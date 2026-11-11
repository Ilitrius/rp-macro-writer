# rp-macro-writer

**Build macros by drag and drop. No typing, no syntax, no guesswork.**

rp-macro-writer turns macro writing into something you do with your mouse. Open the window, drag spells straight out of your spellbook, tick the options you want, and the finished macro appears in front of you – ready to be placed on your action bar.

It works with every class and race.

## What it does

- **Drag and drop:** pull spells, pet abilities and items from your spellbook or bags into the step list. Reorder or remove them with one click.
- **Detects what you need:** one spell becomes a simple `/cast`, several spells become a `/castsequence` – automatically.
- **Sequence reset:** reset on target change, on leaving combat, after a number of seconds, or any combination.
- **Target conditions with one click:** enemy or any target, alive or dead, and optionally mouseover first with your current target as fallback.
- **More macro types:** put different spells on Shift / Ctrl / Alt, cast a random spell from your list, or generate one line per spell.
- **Useful extras:** `#showtooltip`, send your pet in, auto-target the nearest enemy, protect channeled spells from being clipped, account-wide or character-specific macro.
- **Live preview:** the macro text updates as you click, with a character counter for the 255-character limit and plain warnings when something will not work.
- **One-click creation:** rp-macro-writer creates or updates the macro in game and hands it to your cursor to drop on a bar.
- **Saved combinations, shared across characters:** every combination you create is stored account-wide, so you can load it on any character, tweak it and save it again.

## Why you will like it

- **No macro knowledge required.** You never have to remember where `reset=` goes or how conditionals are written.
- **Fewer mistakes.** Spell names are taken from the game itself, so there are no typos and no wrong language.
- **Fast to experiment.** Change an option, see the result immediately, try another combination.
- **You stay in control.** The result is a normal WoW macro. You can read it, edit it by hand, and it keeps working even if you remove the addon.
- **Lightweight.** No libraries, no background processing, nothing running during combat.

## What it cannot do

Honest limits, so you know what to expect:

- **One spell per key press.** WoW only allows a single spell on the global cooldown per press. A cast sequence casts the *next* spell each time you press the key – it does not fire the whole list at once. No addon can change that.
- **No smart rotations.** Macros cannot check whether a DoT is already on the target, how much time is left, or how much mana you have. The sequence simply runs in order.
- **Not in combat.** WoW blocks creating and editing macros while you are in combat.
- **255 characters.** That is the game's hard limit per macro; long spell names fill it quickly (special characters such as umlauts count twice).
- **German interface only, for now.** The window texts are currently German. An English interface is planned.
- **Up to 10 steps** per macro.
- **Early version.** This is the first release – expect rough edges, and please report what you find.

## How to use it

1. Type `/mw`.
2. Open your spellbook and drag spells into the window.
3. Pick your options on the right.
4. Enter a name, create the macro, and place it on an action bar.

## Supported game versions

Developed for **WoW Forever** and **WoW Retail**. The addon is also flagged for Mists Classic, Wrath (Titan Reforged), TBC Classic and Classic Era.

## Feedback

Found a bug or have an idea? Please open an issue on the project page and include the exact error message if there is one.
