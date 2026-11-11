#!/usr/bin/env bash
set -euo pipefail

# Ingest .nx? archives and an optional channel init file from a staging
# directory, auto-bump versions, copy to the destination and update the
# corresponding updates_*_files table.
#
# Requirements on the remote host:
# - docker with a container named "faf-db" running MySQL
# - DB env file at $SCRIPT_BASE_DIR/config/faf-db/faf-db.env
# - md5sum and find
#
# Usage:
#   ingest_nx_files.sh --script-base /path/to/base \
#                      --staging /path/to/staging \
#                      --channel fafbeta \
#                      [--kind nx4] \
#                      [--init init_fafbeta.lua] \
#                      [--exe ForgedAlliance.exe] \
#                      [--dry-run] \
#                      [--only lua,units,loc]

SCRIPT_BASE_DIR=""
STAGING_DIR=""
CHANNEL=""
KIND="nx4"
DRY_RUN=false
ONLY_NAMES=""
INIT_FILE_NAME=""
EXE_FILE_NAME=""
PALETTE_FILE_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --script-base)
      SCRIPT_BASE_DIR="$2"; shift 2 ;;
    --staging)
      STAGING_DIR="$2"; shift 2 ;;
    --channel)
      CHANNEL="$2"; shift 2 ;;
    --kind)
      KIND="$2"; shift 2 ;;
    --init)
      INIT_FILE_NAME="$2"; shift 2 ;;
    --exe)
      EXE_FILE_NAME="$2"; shift 2 ;;
    --palette)
      PALETTE_FILE_NAME="$2"; shift 2 ;;
    --dry-run)
      DRY_RUN=true; shift ;;
    --only)
      ONLY_NAMES="$2"; shift 2 ;;
    *)
      echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$SCRIPT_BASE_DIR" || -z "$STAGING_DIR" || -z "$CHANNEL" ]]; then
  echo "Missing required arguments. See script header for usage." >&2
  exit 1
fi

if [[ ! "$KIND" =~ ^nx[234]$ ]]; then
  echo "Unsupported archive kind: $KIND (expected: nx2|nx3|nx4)" >&2
  exit 1
fi

if [[ ! -d "$SCRIPT_BASE_DIR" ]]; then
  echo "SCRIPT_BASE_DIR does not exist: $SCRIPT_BASE_DIR" >&2
  exit 1
fi

if [[ ! -d "$STAGING_DIR" ]]; then
  echo "STAGING_DIR does not exist: $STAGING_DIR" >&2
  exit 1
fi

DB_CONFIG_FILE="$SCRIPT_BASE_DIR/config/faf-db/faf-db.env"
echo "Reading DB configuration from: $DB_CONFIG_FILE"
set -a
source "$DB_CONFIG_FILE"
set +a

# Optionally use the running lobby's authenticated DB connection. Credentials
# remain inside that container; only SQL and query results cross the boundary.
query_database() {
  local query="$1"
  if [[ -n "${GAF_DB_RUNTIME_CONTAINER:-}" ]]; then
    [[ "$GAF_DB_RUNTIME_CONTAINER" =~ ^[A-Za-z0-9_.-]+$ ]] || return 2
    printf '%s' "$query" | docker exec -i "$GAF_DB_RUNTIME_CONTAINER" python -c '
import sys,pymysql,prometheus_client
prometheus_client.start_http_server=lambda *a,**k: None
from server.config import config
c=pymysql.connect(host=config.DB_SERVER,port=int(config.DB_PORT),user=config.DB_LOGIN,password=config.DB_PASSWORD,database=config.DB_NAME)
try:
 with c.cursor() as cursor:
  cursor.execute(sys.stdin.read())
  if cursor.description:
   for row in cursor.fetchall(): print("\t".join(str(value) for value in row))
 c.commit()
finally: c.close()
'
  else
    MYSQL_PWD="$MYSQL_ROOT_PASSWORD" docker exec -u root -i -e MYSQL_PWD faf-db mysql -N -D "$MYSQL_DATABASE" -e "$query"
  fi
}

case "$CHANNEL" in
  faf)
    DEST_DIR="$SCRIPT_BASE_DIR/data/content/legacy-featured-mod-files/updates_faf_files"
    TABLE_PREFIX="updates_faf"
    EXPECTED_INIT_FILE="init_faf.lua" ;;
  fafbeta)
    DEST_DIR="$SCRIPT_BASE_DIR/data/content/legacy-featured-mod-files/updates_fafbeta_files"
    TABLE_PREFIX="updates_fafbeta"
    EXPECTED_INIT_FILE="init_fafbeta.lua" ;;
  murderparty)
    DEST_DIR="$SCRIPT_BASE_DIR/data/content/legacy-featured-mod-files/updates_murderparty_files"
    TABLE_PREFIX="updates_murderparty"
    EXPECTED_INIT_FILE="" ;;
  *)
    echo "Unsupported channel: $CHANNEL (expected: faf|fafbeta|murderparty)" >&2
    exit 1 ;;
esac

if [[ -n "$INIT_FILE_NAME" && "$INIT_FILE_NAME" != "$EXPECTED_INIT_FILE" ]]; then
  echo "Invalid init file for channel $CHANNEL: $INIT_FILE_NAME (expected: ${EXPECTED_INIT_FILE:-none})" >&2
  exit 1
fi

if [[ -n "$EXE_FILE_NAME" && "$EXE_FILE_NAME" != "ForgedAlliance.exe" ]]; then
  echo "Invalid executable file name: $EXE_FILE_NAME (expected ForgedAlliance.exe)" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"

echo "Processing staging directory: $STAGING_DIR (kind: $KIND, channel: $CHANNEL)"

publish_file() {
  local FILE_PATH="$1"
  local CLIENT_FILE_NAME="$2"
  local VERSION_SEPARATOR="$3"
  local REQUIRED="$4"
  local FILE_STEM="${CLIENT_FILE_NAME%.*}"
  local FILE_EXTENSION="${CLIENT_FILE_NAME##*.}"

  if [[ ! "$CLIENT_FILE_NAME" =~ ^[A-Za-z0-9_.-]+$ ]]; then
    echo "Unsafe file name: $CLIENT_FILE_NAME" >&2
    exit 1
  fi

  echo "Handling: $(basename "$FILE_PATH") (client name: $CLIENT_FILE_NAME)"

  local FILE_ID
  FILE_ID=$(query_database "SELECT id FROM ${TABLE_PREFIX} WHERE filename = '$CLIENT_FILE_NAME' LIMIT 1;")

  if [[ -z "$FILE_ID" ]]; then
    if [[ "$REQUIRED" == true ]]; then
      echo "Required file is not registered in ${TABLE_PREFIX}: $CLIENT_FILE_NAME" >&2
      exit 1
    fi
    echo "Not found in ${TABLE_PREFIX}: $CLIENT_FILE_NAME - skipping"
    return
  fi

  local DB_LAST
  DB_LAST=$(query_database "SELECT IFNULL(MAX(version),0) FROM ${TABLE_PREFIX}_files WHERE fileId = $FILE_ID;")
  [[ -z "$DB_LAST" ]] && DB_LAST=0

  local FS_LAST
  if [[ "$VERSION_SEPARATOR" == "." ]]; then
    FS_LAST=$(find "$DEST_DIR" -maxdepth 1 -type f -name "${FILE_STEM}.*.${FILE_EXTENSION}" -printf '%f\n' 2>/dev/null | \
      sed -nE 's/^.*\.([0-9]+)\.[^.]+$/\1/p' | sort -n | tail -1)
  else
    FS_LAST=$(find "$DEST_DIR" -maxdepth 1 -type f -name "${FILE_STEM}_*.${FILE_EXTENSION}" -printf '%f\n' 2>/dev/null | \
      sed -nE 's/^.*_([0-9]+)\.[^.]+$/\1/p' | sort -n | tail -1)
  fi
  [[ -z "$FS_LAST" ]] && FS_LAST=0

  local NEXT_VERSION=$((DB_LAST > FS_LAST ? DB_LAST : FS_LAST))
  NEXT_VERSION=$((NEXT_VERSION + 1))

  local NEW_FILENAME="${FILE_STEM}${VERSION_SEPARATOR}${NEXT_VERSION}.${FILE_EXTENSION}"
  local DEST_PATH="$DEST_DIR/$NEW_FILENAME"

  echo "  Current max version: DB=$DB_LAST, FS=$FS_LAST -> next: $NEXT_VERSION"
  echo "  Copying to: $DEST_PATH"

  if [[ "$DRY_RUN" == true ]]; then
    echo "  [DRY-RUN] Would copy $FILE_PATH -> $DEST_PATH"
    echo "  [DRY-RUN] Would update ${TABLE_PREFIX}_files with version=$NEXT_VERSION"
    return
  fi

  cp "$FILE_PATH" "$DEST_PATH"
  chmod 664 "$DEST_PATH"

  local MD5
  MD5=$(md5sum "$DEST_PATH" | cut -d' ' -f1)
  echo "  MD5: $MD5"

  query_database "INSERT INTO ${TABLE_PREFIX}_files (fileId, name, version, md5) VALUES ($FILE_ID, '$NEW_FILENAME', $NEXT_VERSION, '$MD5') ON DUPLICATE KEY UPDATE version=$NEXT_VERSION, md5='$MD5';"

  echo "  Published $NEW_FILENAME (version $NEXT_VERSION)"
}

if [[ -n "$PALETTE_FILE_NAME" ]]; then
  if [[ "$PALETTE_FILE_NAME" != "game-colors-$CHANNEL.json" ]]; then
    echo 'Unexpected palette filename' >&2; exit 1
  fi
  if [[ -n "$ONLY_NAMES" && ",$ONLY_NAMES," != *,lua,* ]]; then
    echo 'A palette may only be published with the matching Lua archive' >&2; exit 1
  fi
  # Validate against the archive before any DB/file publication. Never execute Lua.
  python3 "$STAGING_DIR/export_game_colors.py" "$STAGING_DIR/lua.$KIND" | \
    python3 -c 'import json,sys; actual=json.load(sys.stdin); expected=json.load(open(sys.argv[1],encoding="utf-8-sig")); assert actual == expected, "Palette does not match the Lua archive"' "$STAGING_DIR/$PALETTE_FILE_NAME"
fi

shopt -s nullglob
for FILE_PATH in "$STAGING_DIR"/*."$KIND"; do
  FILE_NAME=$(basename "$FILE_PATH")
  BASENAME_NO_EXT="${FILE_NAME%.${KIND}}"

  if [[ -n "$ONLY_NAMES" ]]; then
    IFS=',' read -r -a ONLY_ARR <<< "$ONLY_NAMES"
    SHOULD_PROCESS=false
    for NAME in "${ONLY_ARR[@]}"; do
      if [[ "$NAME" == "$BASENAME_NO_EXT" ]]; then
        SHOULD_PROCESS=true
        break
      fi
    done
    if [[ "$SHOULD_PROCESS" != true ]]; then
      echo "Skipping $FILE_NAME due to --only filter"
      continue
    fi
  fi

  REQUIRED=false
  if [[ "$BASENAME_NO_EXT" == lua && -n "$PALETTE_FILE_NAME" ]]; then
    REQUIRED=true
  fi
  publish_file "$FILE_PATH" "$FILE_NAME" "." "$REQUIRED"
done

if [[ -n "$INIT_FILE_NAME" ]]; then
  INIT_FILE_PATH="$STAGING_DIR/$INIT_FILE_NAME"
  if [[ ! -f "$INIT_FILE_PATH" ]]; then
    echo "Requested init file is missing from staging: $INIT_FILE_PATH" >&2
    exit 1
  fi
  publish_file "$INIT_FILE_PATH" "$INIT_FILE_NAME" "_" true
fi

if [[ -n "$EXE_FILE_NAME" ]]; then
  EXE_FILE_PATH="$STAGING_DIR/$EXE_FILE_NAME"
  if [[ ! -f "$EXE_FILE_PATH" ]]; then
    echo "Requested executable is missing from staging: $EXE_FILE_PATH" >&2
    exit 1
  fi
  publish_file "$EXE_FILE_PATH" "$EXE_FILE_NAME" "." true
fi

if [[ -n "$PALETTE_FILE_NAME" ]]; then
  PALETTE_DIR="$SCRIPT_BASE_DIR/config/faf-python-server/dynamic"
  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] Would atomically publish $PALETTE_DIR/$PALETTE_FILE_NAME"
  else
    mkdir -p "$PALETTE_DIR"
    PALETTE_TEMP=$(mktemp "$PALETTE_DIR/.game-colors-XXXXXX")
    cp "$STAGING_DIR/$PALETTE_FILE_NAME" "$PALETTE_TEMP"
    chmod 644 "$PALETTE_TEMP"
    mv -f "$PALETTE_TEMP" "$PALETTE_DIR/$PALETTE_FILE_NAME"
    echo "Published autohost palette: $PALETTE_FILE_NAME (no lobby restart needed)"
  fi
fi

echo "Done. Published files for channel=$CHANNEL kind=$KIND from $STAGING_DIR"
