"""Export the static GameColors tables, without executing untrusted game Lua.

python scripts/export_game_colors.py lua/GameColors.lua --output palette.json
An archive (lua.nx2/nx3/nx4/zip) can be supplied instead of the Lua file.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import zipfile


def export_palette(source):
    # Comments must not contribute colors, indices or policy values.
    source = re.sub(r'--\[\[.*?\]\]', '', source, flags=re.S)
    source = re.sub(r'--[^\n]*', '', source)

    def table(name):
        matches = list(re.finditer(r'\b' + name + r'\s*=\s*\{([^{}]*)\}', source, re.S))
        if len(matches) != 1:
            raise ValueError('Expected exactly one static table: ' + name)
        return matches[0].group(1)

    def indices(name):
        result = []
        for token in table(name).split(','):
            token = token.strip()
            if not token:
                continue
            if not re.fullmatch(r'\d+', token):
                raise ValueError('Expected integer indices in ' + name)
            result.append(int(token))
        return result

    def colors(name):
        body = table(name)
        tokens = re.findall(r'["\']([0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?)["\']', body)
        remainder = re.sub(r'["\'][0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?["\']', '', body)
        if not tokens or remainder.strip(' \r\n\t,'):
            raise ValueError('Expected a static hex color array: ' + name)
        return ['#' + token[-6:].lower() for token in tokens]

    player = colors('PlayerColors')
    if player != colors('ArmyColors'):
        raise ValueError('PlayerColors and ArmyColors must have identical RGB indices')
    if not 1 <= len(player) <= 256:
        raise ValueError('Palette must contain between 1 and 256 colors')
    access = {}
    for token in table('PlayerColorAccess').split(','):
        token = token.strip()
        if not token:
            continue
        match = re.fullmatch(r'''\[\s*(\d+)\s*\]\s*=\s*(["'])([^"']+)\2''', token)
        if not match:
            raise ValueError('Expected PlayerColorAccess entry: [index] = "public", "premium" or "admin"')
        index, policy = int(match.group(1)), match.group(3)
        if not 1 <= index <= len(player):
            raise ValueError(f'PlayerColorAccess index {index} has no matching color')
        if index in access:
            raise ValueError(f'Duplicate PlayerColorAccess entry for color {index}')
        if policy not in {'public', 'premium', 'admin'}:
            raise ValueError(f'Unknown PlayerColorAccess policy for color {index}: {policy!r}')
        access[index] = policy
    missing = sorted(set(range(1, len(player) + 1)) - access.keys())
    if missing:
        raise ValueError('Missing PlayerColorAccess entries for colors: ' + ', '.join(map(str, missing)))
    if not any(policy == 'public' for policy in access.values()):
        raise ValueError('Palette needs public colors for automatic assignment')
    order = indices('LobbyColorOrder')
    if not order or len(set(order)) != len(order) or any(access.get(value) != 'public' for value in order):
        raise ValueError('LobbyColorOrder must contain distinct public color indices')
    warm_cold = indices('WarmColdMapping')
    if any(access.get(value) != 'public' for value in warm_cold):
        raise ValueError('WarmColdMapping must use public color indices')
    entries = [dict(id=index, color=color, access=access[index]) for index, color in enumerate(player, 1)]
    version = hashlib.sha256(json.dumps(entries, sort_keys=True).encode()).hexdigest()[:16]
    return dict(version=version, colors=entries)


def read_source(path):
    if zipfile.is_zipfile(path):
        with zipfile.ZipFile(path) as archive:
            names = [name for name in archive.namelist() if name.lower() == 'lua/gamecolors.lua']
            if len(names) != 1:
                raise ValueError('Archive must contain exactly one lua/GameColors.lua')
            return archive.read(names[0]).decode('utf-8-sig')
    return Path(path).read_text(encoding='utf-8-sig')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    try:
        content = json.dumps(export_palette(read_source(args.source)), indent=2) + '\n'
    except (ValueError, OSError, UnicodeError, zipfile.BadZipFile) as error:
        parser.error(str(error))
    if args.output:
        args.output.write_text(content, encoding='utf-8')
    else:
        print(content, end='')
