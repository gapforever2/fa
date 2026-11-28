"""Ordinary Russian words must not be swallowed by the profanity filter."""
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[2]


class ChatCensorshipFalsePositiveTest(unittest.TestCase):
    def setUp(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute("""
            option = true
            Prefs = {GetOption = function() return option end}
            function import(path)
                if path == '/lua/user/prefs.lua' then return Prefs end
                error('Unexpected import: ' .. path)
            end
        """)
        lua.execute((ROOT / 'lua/ui/chat/autoreplace.lua').read_text(encoding='utf-8-sig'))
        self.mask = lua.globals().MaskProfanity

    def test_ordinary_words_are_not_masked(self):
        for text in [
            'себе', 'себя', 'походу', 'по хо ду', 'po ho dy', 'штож',
            'ш т о ж', 'что ж', 'штраф', 'штука', 'доход', 'находка',
            'хулиган', 'геймер', 'мандарин', 'фагот', 'лохматый',
        ]:
            with self.subTest(text=text):
                self.assertEqual(self.mask(text), text)

    def test_profanity_is_still_masked(self):
        for text, expected in [
            ('сука', '****'),
            ('хуй', '***'),
            ('похуй', '*****'),
            ('нахуй', '*****'),
            ('х у й', '***'),
            ('h у й', '***'),
            ('shit', '****'),
        ]:
            with self.subTest(text=text):
                self.assertEqual(self.mask(text), expected)


if __name__ == '__main__':
    unittest.main()
