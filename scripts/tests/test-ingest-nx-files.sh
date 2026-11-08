#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
INGEST_SCRIPT=$(cd -- "$SCRIPT_DIR/.." && pwd)/server/ingest_nx_files.sh
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

SCRIPT_BASE="$TEST_ROOT/base"
STAGING="$TEST_ROOT/staging"
DEST="$SCRIPT_BASE/data/content/legacy-featured-mod-files/updates_fafbeta_files"
MOCK_LOG="$TEST_ROOT/mysql.log"
export MOCK_LOG

mkdir -p "$SCRIPT_BASE/config/faf-db" "$STAGING" "$DEST"
printf 'MYSQL_ROOT_PASSWORD=test\nMYSQL_DATABASE=test\n' > "$SCRIPT_BASE/config/faf-db/faf-db.env"
printf 'archive-content\n' > "$STAGING/lua.nx4"
printf 'init-content\n' > "$STAGING/init_fafbeta.lua"
printf 'patched-executable\n' > "$STAGING/ForgedAlliance.exe"
printf 'old-archive\n' > "$DEST/lua.7.nx4"
printf 'old-init\n' > "$DEST/init_fafbeta_12.lua"
printf 'old-executable\n' > "$DEST/ForgedAlliance.4.exe"

docker() {
  local command_line="$*"
  case "$command_line" in
    *"SELECT id FROM updates_fafbeta WHERE filename = 'lua.nx4'"*)
      if [[ "${MISSING_LUA:-0}" != 1 ]]; then printf '11\n'; fi ;;
    *"SELECT id FROM updates_fafbeta WHERE filename = 'init_fafbeta.lua'"*)
      printf '21\n' ;;
    *"SELECT id FROM updates_fafbeta WHERE filename = 'ForgedAlliance.exe'"*)
      printf '31\n' ;;
    *"MAX(version),0) FROM updates_fafbeta_files WHERE fileId = 11"*)
      printf '9\n' ;;
    *"MAX(version),0) FROM updates_fafbeta_files WHERE fileId = 21"*)
      printf '12\n' ;;
    *"MAX(version),0) FROM updates_fafbeta_files WHERE fileId = 31"*)
      printf '4\n' ;;
    *"INSERT INTO updates_fafbeta_files"*)
      printf '%s\n' "$command_line" >> "$MOCK_LOG" ;;
    *)
      printf 'Unexpected docker command: %s\n' "$command_line" >&2
      return 1 ;;
  esac
}
export -f docker

bash "$INGEST_SCRIPT" \
  --script-base "$SCRIPT_BASE" \
  --staging "$STAGING" \
  --channel fafbeta \
  --kind nx4 \
  --only lua \
  --init init_fafbeta.lua \
  --exe ForgedAlliance.exe

test -f "$DEST/lua.10.nx4"
test -f "$DEST/init_fafbeta_13.lua"
test -f "$DEST/ForgedAlliance.5.exe"
grep -Fq "VALUES (11, 'lua.10.nx4', 10," "$MOCK_LOG"
grep -Fq "VALUES (21, 'init_fafbeta_13.lua', 13," "$MOCK_LOG"
grep -Fq "VALUES (31, 'ForgedAlliance.5.exe', 5," "$MOCK_LOG"

echo "ingest nx/init/exe test: OK"

# Exercise the palette branch with a real Lua archive and no actual Docker/SSH.
if ! command -v python3 >/dev/null 2>&1; then
  python3() { python "$@"; }
  export -f python3
fi
cp "$SCRIPT_DIR/../export_game_colors.py" "$STAGING/export_game_colors.py"
python3 - "$STAGING/lua.nx4" "$SCRIPT_DIR/../../lua/GameColors.lua" <<'PY'
import pathlib, sys, zipfile
with zipfile.ZipFile(sys.argv[1], 'w') as archive:
    archive.writestr('lua/GameColors.lua', pathlib.Path(sys.argv[2]).read_bytes())
PY
python3 "$STAGING/export_game_colors.py" "$STAGING/lua.nx4" --output "$STAGING/game-colors-fafbeta.json"
PALETTE_DEST="$SCRIPT_BASE/config/faf-python-server/dynamic/game-colors-fafbeta.json"
bash "$INGEST_SCRIPT" --script-base "$SCRIPT_BASE" --staging "$STAGING" \
  --channel fafbeta --only lua --palette game-colors-fafbeta.json --dry-run
test ! -f "$PALETTE_DEST"
bash "$INGEST_SCRIPT" --script-base "$SCRIPT_BASE" --staging "$STAGING" \
  --channel fafbeta --only lua --palette game-colors-fafbeta.json
cmp "$STAGING/game-colors-fafbeta.json" "$PALETTE_DEST"

# A mismatched manifest must fail BEFORE any extra publication.
BEFORE=$(wc -l < "$MOCK_LOG")
python3 - "$STAGING/game-colors-fafbeta.json" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
data['colors'][0]['color'] = '#123456'
path.write_text(json.dumps(data))
PY
if bash "$INGEST_SCRIPT" --script-base "$SCRIPT_BASE" --staging "$STAGING" \
    --channel fafbeta --only lua --palette game-colors-fafbeta.json > "$TEST_ROOT/rejected.log" 2>&1; then
  echo 'Mismatched palette was incorrectly accepted' >&2; exit 1
fi
test "$(wc -l < "$MOCK_LOG")" -eq "$BEFORE"
echo 'palette dry-run/publication/mismatch tests: OK'

cp "$PALETTE_DEST" "$STAGING/game-colors-fafbeta.json"
if MISSING_LUA=1 bash "$INGEST_SCRIPT" --script-base "$SCRIPT_BASE" --staging "$STAGING" \
    --channel fafbeta --only lua --palette game-colors-fafbeta.json > "$TEST_ROOT/missing-lua.log" 2>&1; then
  echo 'Palette published without a registered Lua archive' >&2; exit 1
fi
test "$(wc -l < "$MOCK_LOG")" -eq "$BEFORE"
cmp "$STAGING/game-colors-fafbeta.json" "$PALETTE_DEST"
echo 'missing Lua registration fails without publishing palette: OK'

# Missing access metadata must also fail before touching the DB or live catalog.
python3 - "$STAGING/lua.nx4" <<'PY'
import pathlib, sys, zipfile
path = pathlib.Path(sys.argv[1])
with zipfile.ZipFile(path) as archive:
    source = archive.read('lua/GameColors.lua').decode('utf-8-sig')
source = source.replace("[23] = 'admin',", '')
with zipfile.ZipFile(path, 'w') as archive:
    archive.writestr('lua/GameColors.lua', source)
PY
if bash "$INGEST_SCRIPT" --script-base "$SCRIPT_BASE" --staging "$STAGING" \
    --channel fafbeta --only lua --palette game-colors-fafbeta.json > "$TEST_ROOT/missing-policy.log" 2>&1; then
  echo 'Palette with missing access rules was incorrectly published' >&2; exit 1
fi
grep -Fq 'Missing PlayerColorAccess entries for colors: 23' "$TEST_ROOT/missing-policy.log"
test "$(wc -l < "$MOCK_LOG")" -eq "$BEFORE"
cmp "$STAGING/game-colors-fafbeta.json" "$PALETTE_DEST"
echo 'missing access rule blocks publication without changing DB/catalog: OK'
