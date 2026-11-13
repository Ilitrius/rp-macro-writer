# rp-macro-writer – Projektwissen

WoW-Addon: Zauber per Drag & Drop aus dem Zauberbuch in ein Fenster ziehen, Optionen daneben wählen, daraus ein Makro erzeugen. Das Add-on gilt für alle Klassen und Rassen (der Nutzer wollte ausdrücklich keinen Hexenmeister-Schwerpunkt mehr, 2026-11-11). Der Nutzer schreibt Deutsch; UI-Texte und Berichte sind deutsch, Changelog und Release Notes englisch (siehe „Sprache“).

## Aufbau
Das Repo-Wurzelverzeichnis **ist** das Addon (so erwartet es der CurseForge-Packager; `.pkgmeta` benennt den Ordner im Paket in `rp-macro-writer` um).

| Datei | Inhalt |
|---|---|
| `rp-macro-writer.toc` | Metadaten, Interface-Nummern, Ladereihenfolge |
| `Locales.lua` | Sprache: deutsche Texte sind die Schlüssel (`ns.L["…"]`), Tabelle `en` übersetzt; deDE-Clients sehen Deutsch, alle anderen Englisch. Neue Texte immer mit `L["…"]` schreiben und in `en` eintragen |
| `Generator.lua` | Makrotext aus Schritten + Optionen. **Keine WoW-API**, damit testbar |
| `Core.lua` | Zustand, `RPMacroWriterDB`, Drag-&-Drop-Annahme, Makro anlegen, Slash-Befehle |
| `UI.lua` | Fenster, Ablaufliste, Optionen, Vorschau, gespeicherte Kombinationen |
| `Rotations.lua` | Mechanik der Rotationen (`ns.RegisterRotation`, `ns.PickRotation`, Varianten `retail`/`classic`). Keine WoW-API |
| `Rotations/<Klasse>.lua` | Je Klasse eine Datei (13): Zauberlisten je Spielversion, Quellen, Begründung, Status, Änderungsverlauf. Wird vom Agenten `rotation-helper` gepflegt |
| `Minimap.lua` | Minimap-Symbol (Klick öffnet das Fenster, Ziehen verschiebt es) |
| `Options.lua` | Eintrag unter Optionen > AddOns (`Settings.RegisterCanvasLayoutCategory`, Rückfall `InterfaceOptions_AddCategory`); ein Klick öffnet das Fenster (`ns.ShowWindow`) |
| `icon.tga` | Addon-Icon im Spiel, erzeugt von `tools/make-icon.js` (auch `media/icon.png` für CurseForge) |
| `tests/` | Generator-Tests + Syntaxprüfung in einer Lua-VM (`cd tests; npm install; npm test`) |
| `CHANGELOG.md`, `docs/release-notes/` | Versionsverlauf und Release Notes |
| `.claude/agents/` | `makro-generator`, `makro-ui` und `rotation-helper` |

## Sprache
- Mit dem Nutzer und in dieser Datei: Deutsch.
- Offene Aufgaben dem Nutzer immer als nummerierte Liste zeigen (1., 2., 3.), nie als Bullet Points (Wunsch vom 2026-11-11).
- Das Fenster des Addons ist seit 2026-11-11 zweisprachig (Deutsch auf deDE-Clients, sonst Englisch, siehe `Locales.lua`); weitere Sprachen wollte der Nutzer nicht („Englisch reicht“).
- **`CHANGELOG.md` und alle Release Notes immer auf Englisch.** Was der Nutzer dafür auf Deutsch vorgibt, wird ins Englische übersetzt.

## Arbeitsweise
- Aufgaben am Makrotext gehen an den Agenten `makro-generator`, Aufgaben an Fenster/Bedienung an `makro-ui`, Aufgaben an den Rotationen („Beste Rotation“: Recherche, Klassendateien, Pre-Release) an `rotation-helper`. Kleinigkeiten dürfen direkt erledigt werden.
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
5. Paket bauen: BigWigs-Packager liest `.pkgmeta`. Die CurseForge-Projekt-ID 1794790 steht seit 2026-11-11 in der TOC.
6. Interface-Nummern in der TOC bei jedem WoW-Patch gegen `TOC_format` im Wiki abgleichen.

## Offen
Aktueller Stand (0.1.8 ist ein Pre-release, siehe Memory) und Details stehen im Memory (`makrowriter-offene-aufgaben.md`); hier die Kurzfassung (Stand 2026-11-12):
1. **„Spezial einfügen“ und „Slot einfügen“ (aus MacroToolkit)** hat der Nutzer am 2026-11-12 wieder entfernen lassen. Die Umsetzung steht in der Git-Historie (Commit 5d28828, per Revert zurückgenommen) und lässt sich bei Bedarf wiederherstellen; Analyse und Plan bleiben in `docs/plan-spezial-slot-einfuegen.md`. Im Code und in den Aufbau-Tabellen ist davon nichts mehr vorhanden.
2. Im Spiel prüfen (nur der Nutzer): Klickverlängerung (`/mw long`), Rotationen und Talentbaum-Erkennung in Forever (`/mw rotation`), `[@target]` in Cast-Sequenzen, Optionen-Eintrag.
3. Rotationen mit dem Dump der Rotationshilfe abgleichen (`rotation-helper`), danach Status `helper-matched`; `game-verified` nur nach Ansage des Nutzers.
4. Neue Version veröffentlichen, wenn 1.–3. laufen (zunächst `--prerelease`); CurseForge-Upload von 0.1.5/0.1.6 klären (Nutzer).
5. Screenshots auf der CurseForge-Seite hochladen (Nutzer). Alle GitHub-Releases 0.1.0–0.1.6 sind normale Releases.

## Kennung und geplante Auswahl
- Jedes erzeugte Makro endet mit der Zeile `#rpmw` (`ns.MARKER`, kostet 6 der 255 Zeichen). Daran erkennt das Add-on eigene Makros im Spiel (`ns.ListEntries`), zeigt sie in der Liste (Reiter „Global“ mit allen Account-Makros, „Dieser Charakter“ nur Charakter-Makros; fremde Makros grau) und überschreibt keine fremden Makros gleichen Namens. Die Kennung nie ändern, sonst werden alte Makros nicht mehr erkannt.
- Erledigt 2026-11-10: Auswahl in der Liste nach „Global“ und „Dieser Charakter“ (zwei Reiter).

## Makrolänge
- Ein Makro im Spiel hat höchstens 255 Zeichen. Zu lange erzeugte Makros kürzt zuerst `ns.Compact` (Leerzeichen in Zauberlisten), danach `/target` → `/tar`; reicht das nicht, läuft der Text über die Klickverlängerung (`ns.ExtendBody`, `Core.lua` Abschnitt „Verlängerung“, bis `ns.LONG_MAX` = 1024). Fremde Makros bleiben bei 255.
- Verlängerung über 255 Zeichen per `/click` auf sichere Zusatzschaltflächen: **ausdrücklich erlaubt und gewünscht** (Nutzer, 2026-11-12: „Ich habe kein Verbot erteilt“). Der erste Versuch am 2026-11-10 lief auf Forever nicht und wurde ausgebaut; das war kein Verbot. Neuer Anlauf nach dem Muster von MacroToolkit (`MacroToolkit.lua`, `mainframe.lua:1102–1115`): Schaltfläche `type = "macro"`, `RegisterForClicks("AnyDown")`, `pressAndHoldAction = "1"`, Aufruf `/click NAME LeftButton 1`, Text in Stücken ≤ 255 Zeichen (der Client begrenzt `macrotext` dort vermutlich auf 255), Gesamtgrenze 1024.
- Ziel Fokus/Mouseover: nur eine Klammer `[@focus,…]`; zweite Klammer (Rückfall aufs aktuelle Ziel) nur mit Option `fallbackTarget`.
- Cast-Sequenz: letzte Klammer ist immer `[@target]` (Nutzer, 2026-11-11).
- „Beste Rotation“ (`ns.BestRotation`): zuerst `C_AssistedCombat.GetRotationSpells`, sonst `Rotations.lua`. Alle Klassen sind abgedeckt (Quelle 1 gilt für alle, Tabelle als Rückfall); Rassen spielen keine Rolle. Die Zauber-IDs der Tabelle sind ungeprüft.
- Heilerbäume behalten ihre Schaden-Rotation (Nutzer, 2026-11-11); Schamane-Restoration ist leer und fällt auf den Klassen-Rückfall zurück.
- Rotationen (Nutzer, 2026-11-11): je Klasse eine Datei `Rotations/<Klasse>.lua`; der Agent `rotation-helper` recherchiert per Websuche die besten Rotationen **für die richtige Spielversion** (Retail oder Forever/Classic), vergleicht sie mit der Blizzard-Rotationshilfe und dem Dump aus `/mw rotation` (liegt nach `/reload` in den SavedVariables unter `rotationDump`) und bereitet ein Pre-Release vor. Status je Klasse: `unverified` → `helper-matched` → `game-verified` (nur nach Ansage des Nutzers).
