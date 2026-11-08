import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('export_game_colors', ROOT / 'scripts/export_game_colors.py')
exporter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(exporter)


class GameColorsTests(unittest.TestCase):
    def setUp(self):
        self.source = (ROOT / 'lua/GameColors.lua').read_text(encoding='utf-8-sig')

    def expanded_source(self, include_access=True):
        extra = ''.join(f'        "{index:06x}",\n' for index in range(24, 39))
        source = re.sub(r'(\b(?:ArmyColors|PlayerColors)\s*=\s*\{)(.*?)(\n\s*\},)',
                        lambda match: match[1] + match[2] + '\n' + extra + match[3],
                        self.source, flags=re.S)
        if include_access:
            rules = ''.join(f"        [{index}] = '{('public', 'premium', 'admin')[(index - 24) % 3]}',\n"
                            for index in range(24, 39))
            source = source.replace("[23] = 'admin',", "[23] = 'admin',\n" + rules)
        return source

    def test_current_palette_has_16_public_6_premium_and_admin_black(self):
        palette = exporter.export_palette(self.source)
        self.assertEqual(len(palette['colors']), 23)
        self.assertEqual([entry['access'] for entry in palette['colors']].count('public'), 16)
        self.assertEqual(palette['colors'][-1], dict(id=23, color='#000000', access='admin'))

    def test_comments_do_not_change_version_but_rgb_and_access_changes_do(self):
        baseline = exporter.export_palette(self.source)
        self.assertEqual(baseline, exporter.export_palette('-- "123456", 30\n' + self.source))
        self.assertNotEqual(baseline['version'], exporter.export_palette(self.source.replace('940000', '950000'))['version'])
        self.assertNotEqual(baseline['version'], exporter.export_palette(self.source.replace("[22] = 'premium'", "[22] = 'admin'"))['version'])

    def test_adding_15_colors_preserves_each_explicit_rule_regardless_of_position(self):
        original = exporter.export_palette(self.source)
        expanded = exporter.export_palette(self.expanded_source())
        self.assertEqual(len(expanded['colors']), 38)
        self.assertEqual(expanded['colors'][:23], original['colors'])
        self.assertNotEqual(expanded['version'], original['version'])
        for index in range(24, 39):
            self.assertEqual(expanded['colors'][index - 1]['access'],
                             ('public', 'premium', 'admin')[(index - 24) % 3])

    def test_public_colors_after_admin_colors_can_be_used_by_auto_assignment(self):
        source = self.expanded_source().replace('LobbyColorOrder = { 1,', 'LobbyColorOrder = { 24, 1,')
        source = source.replace('9, -- blue', '24, -- new public color')
        self.assertEqual(exporter.export_palette(source)['colors'][23]['access'], 'public')

    def test_missing_new_or_existing_policies_block_publication(self):
        with self.assertRaisesRegex(ValueError, 'Missing PlayerColorAccess entries for colors: 24, 25'):
            exporter.export_palette(self.expanded_source(include_access=False))
        with self.assertRaisesRegex(ValueError, 'Missing PlayerColorAccess entries for colors: 23'):
            exporter.export_palette(self.source.replace("[23] = 'admin',", ''))

    def test_unknown_duplicate_extra_and_non_static_rules_are_rejected(self):
        for replacement, error in [
            ("[23] = 'adminn',", 'Unknown PlayerColorAccess policy'),
            ("[23] = 'admin', [23] = 'public',", 'Duplicate PlayerColorAccess'),
            ("[23] = 'admin', [24] = 'public',", 'has no matching color'),
            ("[23] = 'admin', [0] = 'public',", 'has no matching color'),
            ("[23] = someFunction(),", 'Expected PlayerColorAccess entry'),
            ("[23.0] = 'public',", 'Expected PlayerColorAccess entry'),
        ]:
            with self.subTest(replacement=replacement), self.assertRaisesRegex(ValueError, error):
                exporter.export_palette(self.source.replace("[23] = 'admin',", replacement))

    def test_restricted_colors_cannot_be_automatically_assigned(self):
        for field in ['LobbyColorOrder', 'WarmColdMapping']:
            source = re.sub(r'(\b' + field + r'\s*=\s*\{)', r'\g<1> 23,', self.source, count=1)
            with self.subTest(field=field), self.assertRaisesRegex(ValueError, field):
                exporter.export_palette(source)

    def test_cli_reports_missing_policy_without_writing_an_output(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / 'GameColors.lua'
            output = Path(directory) / 'palette.json'
            source.write_text(self.expanded_source(include_access=False), encoding='utf-8')
            result = subprocess.run([sys.executable, str(ROOT / 'scripts/export_game_colors.py'),
                                     str(source), '--output', str(output)], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('Missing PlayerColorAccess entries for colors: 24', result.stderr)
            self.assertNotIn('Traceback', result.stderr)
            self.assertFalse(output.exists())

    def test_mismatched_army_rgb_and_out_of_range_order_are_rejected(self):
        with self.assertRaises(ValueError):
            exporter.export_palette(self.source.replace('"940000"', '"950000"', 1))
        with self.assertRaises(ValueError):
            exporter.export_palette(self.source.replace('LobbyColorOrder = { 1,', 'LobbyColorOrder = { 29,'))

    def test_export_reads_the_actual_case_insensitive_archive_path(self):
        with tempfile.TemporaryDirectory() as directory:
            archive = Path(directory) / 'lua.nx4'
            with zipfile.ZipFile(archive, 'w') as out:
                out.writestr('lua/GameColors.lua', self.source)
            self.assertEqual(exporter.export_palette(self.source), exporter.export_palette(exporter.read_source(archive)))

    def test_bundled_autohost_catalog_matches_lua_when_server_checkout_is_present(self):
        checkout = os.environ.get('GAF_SERVER_CHECKOUT')
        if not checkout:
            self.skipTest('Set GAF_SERVER_CHECKOUT for the cross-repository consistency check')
        server = Path(checkout) / 'server/game_colors.json'
        # Optional workspace consistency check; the portable tests above do not
        # require other repositories or a running lobby/database.
        self.assertEqual(exporter.export_palette(self.source), json.loads(server.read_text()))


if __name__ == '__main__':
    unittest.main()
