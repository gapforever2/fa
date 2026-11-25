"""Run the real marker display policy and rename path with Lua UI stubs."""
from pathlib import Path
import re
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[2]


class MarkerCensorshipTest(unittest.TestCase):
    def runtime(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute("""
            option = true
            Prefs = {GetOption = function(key)
                assert(key == 'chat_censorship')
                return option
            end}
            function import(path)
                if path == '/lua/user/prefs.lua' then return Prefs end
                if path == '/lua/ui/chat/autoreplace.lua' then return policy end
                error('Unexpected import: ' .. path)
            end
        """)
        lua.execute((ROOT / 'lua/ui/chat/autoreplace.lua').read_text(encoding='utf-8-sig'))
        lua.execute("""
            calls = 0
            policy = {MaskProfanity = function(text)
                calls = calls + 1
                return MaskProfanity(text)
            end}
        """)
        lua.execute((ROOT / 'lua/ui/game/markertext.lua').read_text(encoding='utf8'))
        lua.execute("""
            MarkerText = {Refresh = Refresh, OnFrame = OnFrame}
            function newMarker(name)
                return {data = {Name = name}, Name = {writes = 0,
                    SetText = function(self, text)
                        self.text = text
                        self.writes = self.writes + 1
                    end}}
            end
        """)
        return lua

    def test_creation_uses_real_filter_without_changing_synced_name(self):
        lua = self.runtime()
        source = (ROOT / 'lua/ui/controls/worldview.lua').read_text(encoding='utf8')
        creation = source[source.index('                PingGroup.Name = UIUtil.CreateText('):
                          source.index('                PingGroup.Name:DisableHitTest()')]
        lua.execute("""
            PingGroup = newMarker('сука')
            UIUtil = {CreateText = function(parent, text)
                local control = newMarker('').Name
                control:SetText(text)
                return control
            end}
        """)
        lua.execute(creation)
        lua.execute("assert(PingGroup.Name.text == '****'); assert(PingGroup.data.Name == 'сука')")

    def test_existing_labels_follow_preference_both_ways(self):
        lua = self.runtime()
        lua.execute("""
            marker = newMarker('сука!')
            Refresh(marker)
            assert(marker.Name.text == '****!')
            option = false
            OnFrame(marker, 0.1)
            assert(marker.Name.text == '****!')
            OnFrame(marker, 0.15)
            assert(marker.Name.text == 'сука!')
            option = true
            OnFrame(marker, 0.25)
            assert(marker.Name.text == '****!')
            assert(marker.data.Name == 'сука!')
        """)

    def test_boolean_string_and_missing_preferences_match_chat(self):
        for option, expected in [(None, '****'), (True, '****'), ('true', '****'),
                                 (False, 'сука'), ('false', 'сука')]:
            with self.subTest(option=option):
                lua = self.runtime()
                lua.globals().option = option
                marker = lua.globals().newMarker('сука')
                lua.globals().Refresh(marker)
                self.assertEqual(expected, marker.Name.text)

    def test_rename_uses_production_update_path_and_retains_original(self):
        lua = self.runtime()
        source = (ROOT / 'lua/ui/controls/worldview.lua').read_text(encoding='utf8')
        update = source[source.index('    UpdatePing = function(self, pingData)'):
                        source.index('    ---@param show boolean')]
        update = update[:update.rfind('    ---@param self WorldView')]
        update = re.sub(r'for (\w+, \w+) in (self\.Markers|pingTable) do',
                        r'for \1 in pairs(\2) do', update)
        lua.execute('viewClass = {' + update + '}')
        lua.execute("""
            marker = newMarker('base')
            Refresh(marker)
            view = {Markers = {[0] = {[1] = marker}}}
            viewClass.UpdatePing(view, {Owner = 0, ID = 1, Action = 'rename', Name = 'сука'})
            assert(marker.Name.text == '****' and marker.data.Name == 'сука')
            option = false
            viewClass.UpdatePing(view, {Owner = 0, ID = 1, Action = 'rename', Name = 'сука!'})
            assert(marker.Name.text == 'сука!' and marker.data.Name == 'сука!')
        """)

    def test_unchanged_frames_do_not_repeat_filtering_or_layout_updates(self):
        lua = self.runtime()
        lua.execute("""
            marker = newMarker('обычный текст')
            Refresh(marker)
            for i = 1, 600 do OnFrame(marker, 1 / 60) end
            assert(calls == 1 and marker.Name.writes == 1)
        """)
        source = (ROOT / 'lua/ui/controls/worldview.lua').read_text(encoding='utf8')
        self.assertIn('MarkerText.OnFrame(pinggrp, deltaTime)', source)


if __name__ == '__main__':
    unittest.main()
