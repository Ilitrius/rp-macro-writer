# rp-macro-writer – Projektwissen

WoW-Addon: Zauber per Drag & Drop aus dem Zauberbuch in ein Fenster ziehen, Optionen daneben wählen, daraus ein Makro erzeugen. Schwerpunkt zunächst Hexenmeister (DoTs, Flüche, Begleiter). Der Nutzer schreibt Deutsch; UI-Texte und Berichte sind deutsch, Changelog und Release Notes englisch (siehe „Sprache“).

## Aufbau
Das Repo-Wurzelverzeichnis **ist** das Addon (so erwartet es der CurseForge-Packager; `.pkgmeta` benennt den Ordner im Paket in `rp-macro-writer` um).

| Datei | Inhalt |
|---|---|
| `rp-macro-writer.toc` | Metadaten, Interface-Nummern, Ladereihenfolge |
| `Locales.lua` | Sprache: deutsche Texte sind die Schlüssel (`ns.L["…"]`), Tabelle `en` übersetzt; deDE-Clients sehen Deutsch, alle anderen Englisch. Neue Texte immer mit `L["…"]` schreiben und in `en` eintragen |
| `Generator.lua` | Makrotext aus Schritten + Optionen. **Keine WoW-API**, damit testbar |
| `Core.lua` | Zustand, `RPMacroWriterDB`, Drag-&-Drop-Annahme, Makro anlegen, Slash-Befehle |
| `UI.lua` | Fenster, Ablaufliste, Optionen, Vorschau, gespeicherte Kombinationen |
| `Rotations.lua` | Eingebaute Rotationstabelle (Rückfall für „Beste Rotation“, bisher nur Hexenmeister). Keine WoW-API |
| `Minimap.lua` | Minimap-Symbol (Klick öffnet das Fenster, Ziehen verschiebt es) |
| `icon.tga` | Addon-Icon im Spiel, erzeugt von `tools/make-icon.js` (auch `media/icon.png` für CurseForge) |
| `tests/` | Generator-Tests + Syntaxprüfung in einer Lua-VM (`cd tests; npm install; npm test`) |
| `CHANGELOG.md`, `docs/release-notes/` | Versionsverlauf und Release Notes |
| `.claude/agents/` | `makro-generator` und `makro-ui` |

## Sprache
- Mit dem Nutzer und in dieser Datei: Deutsch.
- Offene Aufgaben dem Nutzer immer als nummerierte Liste zeigen (1., 2., 3.), nie als Bullet Points (Wunsch vom 2026-11-11).
- Das Fenster des Addons ist seit 2026-11-11 zweisprachig (Deutsch auf deDE-Clients, sonst Englisch, siehe `Locales.lua`); weitere Sprachen wollte der Nutzer nicht („Englisch reicht“).
- **`CHANGELOG.md` und alle Release Notes immer auf Englisch.** Was der Nutzer dafür auf Deutsch vorgibt, wird ins Englische übersetzt.

## Arbeitsweise
- Aufgaben am Makrotext gehen an den Agenten `makro-generator`, Aufgaben an Fenster/Bedienung an `makro-ui`. Kleinigkeiten dürfen direkt erledigt werden.
- **Nach jeder Umsetzung den Nutzer fragen, ob es so in Ordnung ist** – das hat er ausdrücklich verlangt.
- Memory und diese Datei laufend aktuell halten, auch mitten in der Arbeit (offene Aufgaben, Entscheidungen, Links).
- Im Spiel kann nur der Nutzer testen (`/reload`, dann `/mw`). Nie behaupten, etwas sei im Spiel geprüft.

## Technische Regeln
- **Variantenneutral:** WoW liegt unter `D:\Games\Battle.net\World of Warcraft` mit `_retail_` (12.1.5), `_classic_`, `_classic_era_`, `_anniversary_`, `_forever_` (Interface 16001) und Betas. **Es gibt zwei offizielle Zielvarianten (Nutzer, 2026-11-10): WoW Forever** (`_forever_`, Interface 16001, Client 1.60.x) **und WoW Retail** (`_retail_`, Interface 120105/120107). Beide werden getestet und bekommen die gleiche Funktion; ein Paket, zwei Interface-Nummern in der TOC. Der Projektordner ist per Verknüpfung in `_forever_\Interface\AddOns\rp-macro-writer` und `_classic_era_\Interface\AddOns\rp-macro-writer` eingebunden (Änderungen wirken nach `/reload`). Ebenso in `_retail_\Interface\AddOns\rp-macro-writer` (am 2026-11-10 mit Zustimmung des Nutzers statt einer alten Kopie angelegt). Andere Varianten (Classic, Anniversary, Classic Era) sind Beifang: Kompatibilität behalten, solange sie nichts kostet. Retail-Fallen: `GetSpellBookItemInfo` und `GetSpellInfo` fehlen dort (Code nutzt `C_Spell`, Fallback guarded); Charaktermakros 30 statt 18. Forever hat `C_Spell`/`C_Item`; das globale `GetSpellInfo` ist dort laut Wiki nicht gelistet.
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
1. Version in `rp-macro-writer.toc` (`## Version`) erhöhen.
2. `CHANGELOG.md`: Abschnitt der Version mit Datum versehen; neue Einträge immer oben.
3. `docs/release-notes/vX.Y.Z.md` schreiben (nutzerfreundliche Fassung für die CurseForge-Seite).
4. Tests grün, im Spiel geprüft, dann committen und ZIP bauen (`pwsh tools/build-release.ps1`). GitHub-Release samt ZIP: `gh release create vX.Y.Z .release/rp-macro-writer-X.Y.Z.zip --target main --title ... --notes-file ...` (Notizen = Changelog-Abschnitt der Version; bis zum Spieltest mit `--prerelease`).
5. Paket bauen: BigWigs-Packager liest `.pkgmeta`. Sobald das CurseForge-Projekt existiert, `## X-Curse-Project-ID: <id>` in die TOC eintragen.
6. Interface-Nummern in der TOC bei jedem WoW-Patch gegen `TOC_format` im Wiki abgleichen.

## Offen
- Erster Test im Spiel (WoW Forever **und** Retail) durch den Nutzer steht aus.
- Screenshots für CurseForge (erst nach dem Test im Spiel möglich).
- CurseForge-Projekt anlegen (Lizenz MIT seit 2026-11-10, GitHub-Remote steht).

## Kennung und geplante Auswahl
- Jedes erzeugte Makro endet mit der Zeile `#rpmw` (`ns.MARKER`, kostet 6 der 255 Zeichen). Daran erkennt das Add-on eigene Makros im Spiel (`ns.ListEntries`), zeigt sie in der Liste (Reiter „Global“ mit allen Account-Makros, „Dieser Charakter“ nur Charakter-Makros; fremde Makros grau) und überschreibt keine fremden Makros gleichen Namens. Die Kennung nie ändern, sonst werden alte Makros nicht mehr erkannt.
- Erledigt 2026-11-10: Auswahl in der Liste nach „Global“ und „Dieser Charakter“ (zwei Reiter).

## Makrolänge
- Makros müssen in 255 Zeichen passen. Zu lange erzeugte Makros kürzt `ns.Compact` (Leerzeichen in Zauberlisten), danach `/target` → `/tar`.
- Eine Verlängerung per `/click` auf sichere Zusatzschaltflächen (`macrotext`) lief beim Nutzer auf Forever nicht und wurde am 2026-11-10 auf seinen Wunsch wieder ausgebaut. Nicht erneut einbauen.
- „Beste Rotation“ (`ns.BestRotation`): zuerst `C_AssistedCombat.GetRotationSpells`, sonst `Rotations.lua`. Nicht jede Klasse hat eine Rotation; das steht so in README und Release Notes.
