# Player color access

`lua/GameColors.lua` is the source for both RGB colors and their access rules.
Every index must appear in `PlayerColors`, `ArmyColors` and `PlayerColorAccess`.
The order of colors does not determine access.

Allowed policies:

- `public`: everyone;
- `premium`: Boosty subscribers and staff;
- `admin`: global administrators only, not moderators or ordinary lobby hosts.

For example, when adding three colors to the existing 23-color palette, append
their RGB values to **both** color arrays and append these access entries,
keeping all existing entries:

```lua
[24] = 'public',
[25] = 'premium',
[26] = 'admin',
```

The new public color at 24 does not unlock premium/admin colors at earlier
indices. Keep existing indices stable; append colors rather than inserting or
reordering them. The currently supported catalog limit is 256 colors.

To offer a new public color during automatic assignment in the ordinary game
lobby, add its index to `LobbyColorOrder`. The warm/cold fallback mapping also
must contain only public indices. Keep enough public colors for all player slots.

Check changes locally before publishing:

```sh
python scripts/export_game_colors.py lua/GameColors.lua
python scripts/tests/test_game_colors.py
```

The balance publisher exports from the actual Lua archive and revalidates it on
the server. A missing rule, duplicate index, unknown policy, or an access entry
without a matching RGB color stops publication. In-game missing/unknown rules
deny selection, including for administrators; there is no implicit premium rule.
The resulting catalog is consumed by the client and autohost server without a
new client release for each palette change (after the initial system rollout).
