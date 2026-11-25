"""Execute the actual game color policy and host admission paths using Lua 5.1 (lupa)."""
from pathlib import Path
import re
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[2]


class ColorAssignmentTest(unittest.TestCase):
    def runtime(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute((ROOT / 'lua/GameColors.lua').read_text(encoding='utf8'))
        lua.execute("""
            policy = {CanUsePlayerColor = CanUsePlayerColor, FindPublicPlayerColor = FindPublicPlayerColor}
            gameColors = GameColors
            function import(path) assert(path == '/lua/GameColors.lua'); return policy end
            LobbyComm = {maxPlayerSlots = 16}
            gameInfo = {PlayerOptions = {}, Observers = {}, ClosedSlots = {}}
            argv = {}
            Prefs = {GetFromCurrentProfile = function() return savedColor end}
            function WARN(text) warning = text end
            numOpenSlots = 16
            hostID = 1
            singlePlayer = false
            lobbyComm = {
                SendData = function() end,
                BroadcastData = function(self, data) broadcast = data end,
                IsHost = function() return true end,
            }
            HostUtils = {FindEmptySlot = function() return 2 end}
            function SetSlotInfo() end
            function AssignAutoTeams() end
            function PossiblyAnnounceGameFull() end
            function UpdateFactionSelectorForPlayer() end
            function SendSystemMessage() end
            function player(color, role, human)
                return {PlayerColor = color, ArmyColor = color, GroupRole = role, Human = human,
                    StartSpot = 2, AsTable = function(self) return self end}
            end
        """)
        source = (ROOT / 'lua/ui/lobby/lobby.lua').read_text(encoding='utf8')
        for name in ('IsColorFree', 'GetAvailableColor', 'GetPlayerColorForSlot', 'SetPlayerColor', 'GetSanitisedLastColor'):
            match = re.search(r'^function ' + name + r'\(.*?^end\b', source, re.M | re.S)
            self.assertIsNotNone(match)
            lua.execute(match[0].replace('gameInfo.PlayerOptions:pairs()', 'pairs(gameInfo.PlayerOptions)'))
        for name in ('TryAddPlayer', 'ConvertObserverToPlayer'):
            match = re.search(r'^        ' + name + r' = function\((.*?)\)\n(.*?)^        end,', source, re.M | re.S)
            self.assertIsNotNone(match)
            lua.globals().HostUtils[name] = lua.eval('function(' + match[1] + ')\n' + match[2] + '\nend')
        return lua

    def test_saved_restricted_colors_are_replaced_when_joining_or_leaving_observers(self):
        for role in (False, 'bs', 'mod', 'admin'):
            for color in (17, 23):
                for observer in (False, True):
                    with self.subTest(role=role, color=color, observer=observer):
                        lua = self.runtime()
                        lua.globals().incoming = lua.globals().player(color, role, True)
                        allowed = color == 17 and role in ('bs', 'mod', 'admin') or color == 23 and role == 'admin'
                        if observer:
                            lua.execute('gameInfo.Observers[1] = incoming; HostUtils.ConvertObserverToPlayer(1, 2, true)')
                        else:
                            lua.execute('HostUtils.TryAddPlayer(7, 2, incoming)')
                        expected = color if allowed else 1
                        self.assertEqual(expected, lua.eval('gameInfo.PlayerOptions[2].PlayerColor'))
                        self.assertEqual(expected, lua.eval('gameInfo.PlayerOptions[2].ArmyColor'))
                        self.assertEqual(expected, lua.eval('broadcast.Options.PlayerColor'))

    def test_collision_fallback_never_assigns_black_or_premium_even_to_admins(self):
        for role in (False, 'bs', 'admin'):
            for observer in (False, True):
                with self.subTest(role=role, observer=observer):
                    lua = self.runtime()
                    lua.globals().role = role
                    lua.execute('''
                        gameColors.LobbyColorOrder = {23, 17, 1, 2}
                        gameInfo.PlayerOptions[1] = {PlayerColor=1, StartSpot=1}
                        incoming = player(1, role, true)
                    ''')
                    if observer:
                        lua.execute('gameInfo.Observers[1] = incoming; HostUtils.ConvertObserverToPlayer(1, 2, true)')
                    else:
                        lua.execute('HostUtils.TryAddPlayer(7, 2, incoming)')
                    self.assertEqual(2, lua.eval('gameInfo.PlayerOptions[2].PlayerColor'))

    def test_out_of_range_preferences_and_expired_roles_are_sanitized(self):
        for color in (0, 1.5, 17, 23, 999, '23'):
            lua = self.runtime()
            lua.globals().savedColor = color
            self.assertEqual(1, lua.globals().GetSanitisedLastColor())
        lua = self.runtime()
        lua.execute("savedColor=23; argv.groupDev='admin'")
        self.assertEqual(23, lua.globals().GetSanitisedLastColor())

    def test_preference_sanitization_does_not_require_an_initialized_lobby(self):
        lua = self.runtime()
        lua.execute('gameInfo = nil; savedColor = 23')
        self.assertEqual(1, lua.globals().GetSanitisedLastColor())

    def test_automatic_assignment_uses_policy_not_index_or_lobby_size(self):
        lua = self.runtime()
        lua.execute('''
            gameColors.PlayerColorAccess[1] = 'admin'
            for i=2,16 do gameInfo.PlayerOptions[i]={PlayerColor=i, StartSpot=i} end
            gameColors.PlayerColors[24] = 'FF123456'
            gameColors.PlayerColorAccess[24] = 'public'
            LobbyComm.maxPlayerSlots = 2
        ''')
        self.assertEqual(24, lua.globals().GetAvailableColor())

    def test_exhaustion_does_not_assign_restricted_or_nil_color_or_remove_observer(self):
        for observer in (False, True):
            lua = self.runtime()
            lua.execute('''
                for i=1,16 do gameColors.PlayerColorAccess[i] = 'premium' end
                incoming = player(23, false, true)
            ''')
            if observer:
                lua.execute('gameInfo.Observers[1]=incoming; HostUtils.ConvertObserverToPlayer(1, 2, true)')
                self.assertTrue(lua.eval('gameInfo.Observers[1] == incoming'))
            else:
                lua.execute('HostUtils.TryAddPlayer(7, 2, incoming)')
            self.assertIsNone(lua.eval('gameInfo.PlayerOptions[2]'))
            self.assertEqual(23, lua.eval('incoming.PlayerColor'))
            self.assertIsNone(lua.globals().broadcast)

    def test_ai_does_not_inherit_human_role_privileges(self):
        lua = self.runtime()
        lua.execute("HostUtils.TryAddPlayer(7, 2, player(23, 'admin', false))")
        self.assertEqual(1, lua.eval('gameInfo.PlayerOptions[2].PlayerColor'))

    def test_available_color_is_kept_and_replacement_slot_is_excluded(self):
        lua = self.runtime()
        lua.execute('''
            gameInfo.PlayerOptions[2] = {PlayerColor=1, StartSpot=2}
            HostUtils.TryAddPlayer(7, 2, player(1, false, true))
        ''')
        self.assertEqual(1, lua.eval('gameInfo.PlayerOptions[2].PlayerColor'))
        lua.execute('gameInfo.PlayerOptions[2] = nil; HostUtils.TryAddPlayer(7, 2, player(8, false, true))')
        self.assertEqual(8, lua.eval('gameInfo.PlayerOptions[2].PlayerColor'))


if __name__ == '__main__':
    unittest.main()
