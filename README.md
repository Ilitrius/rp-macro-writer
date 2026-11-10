# rp-macro-writer

World of Warcraft addon: combine spells into macros by drag and drop. Initially focused on warlocks (DoTs, curses, pets), but it works with any class. Targets WoW Forever and WoW Retail. The addon's interface is currently German only.

## Usage
1. `/mw` opens the window.
2. Drag spells from the spellbook (or items from your bags) into the "Ablauf" (sequence) list.
3. Choose type, reset, target and extras on the right – the preview at the bottom shows the macro text immediately.
4. Enter a name, click **Makro erstellen/speichern** (create/save macro), then drag it onto an action bar with **Auf Leiste** (to bar).

With "Automatisch erkennen" (detect automatically), one spell becomes a simple cast and several become a cast sequence.

## Installing for testing
Link the project folder (any name, here `wow-macro-writer`) as `rp-macro-writer` into the AddOns folder of the game flavor you want (PowerShell, once):

```powershell
New-Item -ItemType Junction -Path "D:\Games\Battle.net\World of Warcraft\_retail_\Interface\AddOns\rp-macro-writer" -Target "D:\AI_KI\wow-macro-writer"
```

Then type `/reload` in game.

## Development
- `Generator.lua` – macro text from steps + options (no WoW API, testable)
- `Core.lua` – state, drag and drop, creating macros in game
- `UI.lua` – window
- Tests: `cd tests; npm install; npm test`
- Regenerate the icon: `node tools/make-icon.js`

## Releasing
Version history in [CHANGELOG.md](CHANGELOG.md), release notes per version in [docs/release-notes](docs/release-notes). For the procedure see [CLAUDE.md](CLAUDE.md) (German).

## License
[MIT](LICENSE)
