# rp-macro-writer

World of Warcraft addon: combine spells into macros by drag and drop. Works with every class and race. Targets WoW Forever and WoW Retail. The interface is English, and German on German game clients.

![The rp-macro-writer window with a best-rotation macro for a rogue](media/macro%20writer%20panel2.png)

## Usage
1. `/mw` opens the window.
2. Drag spells from the spellbook (or items from your bags) into the "Steps" list.
3. Choose type, reset, target and extras on the right – the preview at the bottom shows the macro text immediately.
4. Enter a name, click **Create/save macro**, then drag it onto an action bar with **To bar**.

With "Auto-detect", one spell becomes a simple cast and several become a cast sequence.

### Best rotation
The **Best rotation** button fills the list with a rotation for your level and the spells you currently know, and creates the macro. It works for every class and race: the addon asks the game's own rotation helper first and falls back to a simple built-in table that covers all 13 classes. Your race does not matter, because the spells are read from your own spellbook. Classes and spells that do not exist in your game version are skipped. The built-in table is a rough heuristic, not a simulated optimum, and its spell IDs are not yet verified in game.

## Installing for testing
Link the project folder (any name, here `wow-macro-writer`) as `rp-macro-writer` into the AddOns folder of the game flavor you want (PowerShell, once):

```powershell
New-Item -ItemType Junction -Path "D:\Games\Battle.net\World of Warcraft\_retail_\Interface\AddOns\rp-macro-writer" -Target "D:\AI_KI\wow-macro-writer"
```

Then type `/reload` in game.

## Development
- `Locales.lua` – interface texts (German keys, English translations)
- `Generator.lua` – macro text from steps + options (no WoW API, testable)
- `Rotations.lua` – built-in rotation table for most classes (fallback for "Best rotation")
- `Core.lua` – state, drag and drop, creating macros in game
- `UI.lua` – window
- `Minimap.lua` – minimap button
- Tests: `cd tests; npm install; npm test`
- Regenerate the icon: `node tools/make-icon.js`

## Releasing
Version history in [CHANGELOG.md](CHANGELOG.md), release notes per version in [docs/release-notes](docs/release-notes). For the procedure see [CLAUDE.md](CLAUDE.md) (German).

## License
[MIT](LICENSE)
