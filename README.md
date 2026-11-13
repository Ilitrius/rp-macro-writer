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

## Commands

Everything is started with `/mw`. These three spellings do exactly the same: `/mw`, `/rpmw` and `/macrowriter`. Upper and lower case do not matter, and only the first word after the command counts.

| Command | What it does |
|---|---|
| `/mw` | Opens the macro window, or closes it when it is already open. Close it with ESC too. |
| `/mw rotation` | Prints, and saves, what the game's own rotation helper returns for your current character: class, game version, level, talent tree (WoW Forever), and the helper's spells with ID and name, marking those you do not know yet. The result is printed to the chat and saved in the saved variables under `rotationDump` (the file is written when you log out or type `/reload`). It is meant for checking the rotation tables in `Rotations/<Class>.lua` against the game. |
| `/mw long` | Shows what the helper buttons hold that carry macros longer than 255 characters: per macro the number of characters and parts, and for every part whether the button exists, its type and how many characters it holds. Prints "no extended macros saved" when you have none. Use it when a long macro does nothing. |

Notes:
- The same information is also saved **automatically and silently** a few seconds after you log in or reload, when your specialization or talents change, and every time you click "Best rotation". It lands in the saved variables under `rotationDump` (one entry per class, game version and specialization or, on WoW Forever, talent tree), so the data builds up while you play. `/mw rotation` is only needed to read it in the chat or to refresh it on the spot.
- Any other word after `/mw` simply opens or closes the window. There are no further sub-commands.
- The output of `/mw rotation` and `/mw long` is printed in German on all clients for now; it is meant for troubleshooting.
- `/mw rotation` and `/mw long` only read information. Creating or changing macros does not work in combat (the game blocks it).

### Other ways to open the window
- **Minimap button:** left click opens or closes the window, drag it to move it around the minimap edge (the position is remembered).
- **Options > AddOns > rp-macro-writer:** choosing the entry opens the window and closes the options; the button "Fenster öffnen" (open window) does the same.

### Commands inside generated macros
- `/click RPMWL<n> LeftButton 1` lines appear in a macro of the addon when its text was longer than 255 characters. They call the helper buttons `RPMWL<n>`, `RPMWL<n>_2` and so on, which hold the real text. Do not delete these lines by hand; use the window to change such a macro. The buttons only exist while rp-macro-writer is loaded.
- `#rpmw` is the last line of every macro the addon creates. The addon uses it to recognize its own macros. Never remove it by hand; the addon adds it again when you save.

## Installing for testing
Link the project folder (any name, here `wow-macro-writer`) as `rp-macro-writer` into the AddOns folder of the game flavor you want (PowerShell, once):

```powershell
New-Item -ItemType Junction -Path "D:\Games\Battle.net\World of Warcraft\_retail_\Interface\AddOns\rp-macro-writer" -Target "D:\AI_KI\wow-macro-writer"
```

Then type `/reload` in game.

## Development
- `Locales.lua` – interface texts (German keys, English translations)
- `Generator.lua` – macro text from steps + options (no WoW API, testable)
- `Rotations.lua` – mechanics of the rotation fallback; `Rotations/<Class>.lua` – one file per class with spell lists per game version, sources and status (fallback for "Best rotation")
- `/mw rotation` – prints and saves what the game's rotation helper returns for your character (for checking the tables)
- `/mw long` – lists the helper buttons of macros longer than 255 characters and what they hold
- `Options.lua` – entry under Options > AddOns that opens the window
- `Core.lua` – state, drag and drop, creating macros in game
- `UI.lua` – window
- `Minimap.lua` – minimap button
- Tests: `cd tests; npm install; npm test`
- Regenerate the icon: `node tools/make-icon.js`

## Releasing
Version history in [CHANGELOG.md](CHANGELOG.md), release notes per version in [docs/release-notes](docs/release-notes). For the procedure see [CLAUDE.md](CLAUDE.md) (German).

## License
[MIT](LICENSE)
