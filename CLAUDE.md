# MakroWriter – Projektwissen

WoW-Addon: Zauber per Drag & Drop aus dem Zauberbuch in ein Fenster ziehen, Optionen daneben wählen, daraus ein Makro erzeugen. Schwerpunkt zunächst Hexenmeister (DoTs, Flüche, Begleiter). Der Nutzer schreibt Deutsch; UI-Texte und Berichte sind deutsch, Changelog und Release Notes englisch (siehe „Sprache“).

## Aufbau
Das Repo-Wurzelverzeichnis **ist** das Addon (so erwartet es der CurseForge-Packager; `.pkgmeta` benennt den Ordner im Paket in `MakroWriter` um).

| Datei | Inhalt |
|---|---|
| `MakroWriter.toc` | Metadaten, Interface-Nummern, Ladereihenfolge |
| `Generator.lua` | Makrotext aus Schritten + Optionen. **Keine WoW-API**, damit testbar |
| `Core.lua` | Zustand, `MakroWriterDB`, Drag-&-Drop-Annahme, Makro anlegen, Slash-Befehle |
| `UI.lua` | Fenster, Ablaufliste, Optionen, Vorschau, gespeicherte Kombinationen |
| `icon.tga` | Addon-Icon im Spiel, erzeugt von `tools/make-icon.js` (auch `media/icon.png` für CurseForge) |
| `tests/` | Generator-Tests + Syntaxprüfung in einer Lua-VM (`cd tests; npm install; npm test`) |
| `CHANGELOG.md`, `docs/release-notes/` | Versionsverlauf und Release Notes |
| `.claude/agents/` | `makro-generator` und `makro-ui` |

## Sprache
- Mit dem Nutzer, im Fenster des Addons und in dieser Datei: Deutsch.
- **`CHANGELOG.md` und alle Release Notes immer auf Englisch.** Was der Nutzer dafür auf Deutsch vorgibt, wird ins Englische übersetzt.

## Arbeitsweise
- Aufgaben am Makrotext gehen an den Agenten `makro-generator`, Aufgaben an Fenster/Bedienung an `makro-ui`. Kleinigkeiten dürfen direkt erledigt werden.
- **Nach jeder Umsetzung den Nutzer fragen, ob es so in Ordnung ist** – das hat er ausdrücklich verlangt.
- Memory und diese Datei laufend aktuell halten, auch mitten in der Arbeit (offene Aufgaben, Entscheidungen, Links).
- Im Spiel kann nur der Nutzer testen (`/reload`, dann `/mw`). Nie behaupten, etwas sei im Spiel geprüft.

## Technische Regeln
- **Variantenneutral:** WoW liegt unter `D:\Games\Battle.net\World of Warcraft` mit `_retail_` (12.1.5), `_classic_`, `_classic_era_`, `_anniversary_`, `_forever_` (Interface 16001) und Betas. Welche Variante Vorrang hat, ist offen – bis dahin muss alles überall laufen.
- `C_Spell.GetSpellName` / `C_Spell.GetSpellTexture` / `C_Item.GetItemInfo` / `C_Item.GetItemIconByID` bevorzugen, auf globale Funktionen zurückfallen. `GetSpellInfo` ist in Retail seit 11.0.2 entfernt.
- Keine `UIDropDownMenu`- oder Backdrop-Templates; nur `BasicFrameTemplate`, `UIPanelButtonTemplate`, `UICheckButtonTemplate`, `InputBoxTemplate`.
- `CreateMacro`, `EditMacro`, `PickupMacro` sind im Kampf gesperrt → vorher `InCombatLockdown()` prüfen. Makrotext max. 255 Bytes, Name max. 16 Zeichen, 120 Account-Makros; Charakter-Makros je nach Variante 18 oder 30 (`MAX_CHARACTER_MACROS` nutzen).
- `GetCursorInfo()`: `"spell", index, bookType, spellID` · `"petaction", spellID, index` · `"item", itemID, link`.
- Makro-Syntax: Bedingungen stehen vor `reset=`; `[@mouseover]` allein ist immer wahr, deshalb `harm`/`help` oder `exists` dazu. `nochanneling` steht nicht ausdrücklich im Wiki (abgeleitet aus `channeling` + `no`-Präfix) → im Spiel prüfen.
- Lua 5.1-kompatibel schreiben.

## Dokumentation (vom Nutzer vorgegeben, vor API-Einsatz nachschlagen)
- https://warcraft.wiki.gg/wiki/World_of_Warcraft_API – aktuelle API-Referenz, erste Wahl. Einzelseiten: `API_<Funktionsname>`, außerdem `TOC_format`, `Macro_conditionals`, `Making_a_macro`
- https://wowpedia.fandom.com/wiki/Wowpedia:Interface_customization – Überblick, älterer Stand
- https://community.developer.battle.net/documentation/world-of-warcraft – Battle.net Web-API (nur für externe Tools, nicht aus dem Addon erreichbar)
- https://www.wowhead.com/guide/comprehensive-beginners-guide-for-wow-addon-coding-in-lua-5338 – Einsteiger-Guide

## Release-Ablauf (CurseForge)
1. Version in `MakroWriter.toc` (`## Version`) erhöhen.
2. `CHANGELOG.md`: Abschnitt der Version mit Datum versehen; neue Einträge immer oben.
3. `docs/release-notes/vX.Y.Z.md` schreiben (nutzerfreundliche Fassung für die CurseForge-Seite).
4. Tests grün, im Spiel geprüft, dann committen und `git tag vX.Y.Z`.
5. Paket bauen: BigWigs-Packager liest `.pkgmeta`. Sobald das CurseForge-Projekt existiert, `## X-Curse-Project-ID: <id>` in die TOC eintragen.
6. Interface-Nummern in der TOC bei jedem WoW-Patch gegen `TOC_format` im Wiki abgleichen.

## Offen
- Im Spiel testen (noch nie geladen) und Zielvariante festlegen.
- Screenshots für CurseForge (erst nach dem Test im Spiel möglich).
- Lizenz wählen, GitHub-Remote und CurseForge-Projekt anlegen.
