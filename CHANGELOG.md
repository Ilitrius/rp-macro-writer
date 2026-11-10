# Changelog

All notable changes to rp-macro-writer are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and version numbers follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- The macro text box is now editable: type directly into the preview to fine-tune the macro by hand. While edited by hand, options no longer change the text; "Neu erzeugen" returns to the generated text. The marker line `#rpmw` is appended on saving if it was removed. Hand-edited text is saved with the combination.
- The window can be resized (wider and taller) by dragging a grip in the bottom-right corner of the window or of the macro text box; the step list and the macro text box grow with it, the options stay at the right edge.
- The list of saved macros now has two tabs: "Global" shows all account-wide macros (the addon's own with or without saved data, and macros made by others, greyed out) and "Dieser Charakter" shows only the macros of the current character. The addon's own macros are always listed first, macros made by others after them. Clicking a macro without saved data loads its text into the editable macro box; macros made by others are changed directly in game when saved (without the marker line and without saved data).
- The window remembers its position and size between sessions.
- Syntax highlighting in the macro text box: commands, `@units`, conditions, `reset=` and comment lines get their own colors.

## [0.1.1] – 2026-11-10

### Added
- Warning in the preview when a spell name contains characters that can break the macro (line breaks and square brackets always; commas in sequences and random macros; commas and semicolons in modifier macros).
- Items that are not yet in the client cache are now requested and added automatically once their data arrives, instead of failing with "name could not be determined".
- MIT license.
- New options "Fokus anvisieren" (`/target focus`) and "Ziel des Ziels (Rückfall)": the spell goes to the current target if it is a valid enemy, otherwise to the target's target (`@targettarget`), otherwise to the target anyway (`[@target]`).

### Changed
- "Maus-Ziel als Fokus setzen" now sets the focus to the unit under the mouse and falls back to the current target when nothing is under the mouse (`/focus [@mouseover,…][]`). It also ticks "Fokus anvisieren", and the spells then go to the current target (the focus) instead of `@focus`. The old behaviour is still available through the target choice "Fokus".
- Window is 22 pixels taller to fit the new options.

## [0.1.0] – 2026-11-09

First release.

### Added
- Window opened with `/mw` (also `/rpmw`, `/macrowriter`); ESC closes it.
- Drag and drop spells, pet abilities and items from the spellbook and bags into the step list; reorder with arrows, remove single entries.
- **Automatic detection:** one spell becomes a simple cast (`/cast`), several become a cast sequence (`/castsequence`).
- Sequence reset on target change, on leaving combat and/or after a configurable number of seconds.
- Target conditions: enemy / friend / any, and alive / dead / any; optionally check mouseover or focus first, then the current target.
- More macro types: modifier key (Shift / Ctrl / Alt per spell), separate lines, random (`/castrandom`).
- Extras: `#showtooltip`, pet attack, auto-target an enemy, do not interrupt channeled spells, character-specific macro.
- Set the unit under the mouse as focus (`/focus [@mouseover,…]`) and cast on the focus, so the target stays locked without changing your current target.
- Start auto-attack at the end of the macro (`/startattack`), aimed at the same target as the spells.
- Live preview of the macro text with a character counter (255 limit) and warnings.
- Create or update the macro in game and pick it up with one click to place it on an action bar.
- Saved combinations: every created combination is stored account-wide, so it can be loaded and edited again later on any character. Macros are created account-wide by default; a checkbox makes them character-specific.
- Every generated macro ends with the marker line `#rpmw`. The addon uses it to recognise its own macros in game, shows them in the list, and never overwrites a macro of the same name that it did not create.

### Known limitations

- WoW allows only one spell on the global cooldown per key press; a cast sequence casts the next spell with each press.
- Macros cannot be created or changed while in combat.
- A macro holds at most 255 characters; the marker line uses 6 of them.
- The addon's interface is currently German only.

### Supported game versions

Developed for WoW Forever and WoW Retail (12.1.x). Also flagged for Mists Classic, Wrath (Titan Reforged), TBC Classic and Classic Era.