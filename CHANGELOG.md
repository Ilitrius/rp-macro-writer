# Changelog

All notable changes to MakroWriter are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and version numbers follow [Semantic Versioning](https://semver.org/).

## [0.1.0] – unreleased

First version. Not yet tested in game.

### Added
- Window opened with `/mw` (also `/makrowriter`, `/macrowriter`); ESC closes it.
- Drag and drop spells, pet abilities and items from the spellbook and bags into the step list; reorder with arrows, remove single entries.
- **Automatic detection:** one spell becomes a simple cast (`/cast`), several become a cast sequence (`/castsequence`).
- Sequence reset on target change, on leaving combat and/or after a configurable number of seconds.
- Target conditions: enemy / friend / any, and alive / dead / any; optionally check mouseover or focus first, then the current target.
- More macro types: modifier key (Shift / Ctrl / Alt per spell), separate lines, random (`/castrandom`).
- Extras: `#showtooltip`, pet attack, auto-target an enemy, do not interrupt channeled spells, character-specific macro.
- Live preview of the macro text with a character counter (255 limit) and warnings.
- Create or update the macro in game and pick it up with one click to place it on an action bar.
- Saved combinations: every created combination can be loaded and edited again later.
- Supported game flavors according to the TOC: Retail 12.1.x, Mists Classic, Wrath (Titan Reforged), TBC Classic, Forever, Classic Era.
