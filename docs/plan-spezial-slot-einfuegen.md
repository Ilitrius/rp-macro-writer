# Plan: „Spezial einfügen“ und „Slot einfügen“ aus MacroToolkit übernehmen

Stand 2026-11-12. **Umgesetzt am 2026-11-12** (`Inserts.lua`, `Specials.lua`, Abschnitt „Einfügen“ in `UI.lua`, `[Unreleased]` im Changelog), im Spiel ungetestet. Die offenen Fragen unten hat der Nutzer nicht beantwortet; entschieden wurde: „Destroy grey items“ dabei mit Rückfrage (StaticPopup mit Anzahl) und nie im Kampf, Präfix `/rp…`, Befehle anderer Add-ons werden nicht überschrieben. Die Layout-Zahlen weiter unten gelten für den Stand davor. Auftrag des Nutzers (wörtlich): „Übernimmt die Optionen aus Spezial einfügen und Slot einfügen. Stelle die Option optisch im Panel dar. Dies sind alles zusätzliche Optionen.“

Vorbild: das Add-on MacroToolkit v2.3.53 unter
`D:\Games\Battle.net\World of Warcraft\_forever_\Interface\AddOns\MacroToolkit` (nur lesen, nichts kopieren oder ändern; eigene Umsetzung in rp-macro-writer, Lizenz des Vorbilds nicht übernehmen).

## Was MacroToolkit macht

Im Editor stehen zwei Auswahllisten (AceGUI-Dropdown) mit je einem Knopf „Einfügen“ (`mainframe.lua:812–906`). Beide fügen Text an der Cursorposition in den Makrotext ein und prüfen vorher die 255-Zeichen-Grenze (Fehlermeldung „Not enough space …“).

### „Slot einfügen“ (`Insert slot`, deDE „Slot einfügen“)
Liste `MT.slots` (`initialise.lua:42–62`), fügt die **Zahl** des Ausrüstungsplatzes ein (für `/use 13`, `/equipslot` und Ähnliches):
1 Kopf, 2 Hals, 3 Schulter, 4 Hemd, 5 Brust, 6 Taille, 7 Beine, 8 Füße, 9 Handgelenke, 10 Hände, 11 Finger 1, 12 Finger 2, 13 Schmuckstück 1, 14 Schmuckstück 2, 15 Rücken, 16 Waffenhand, 17 Nebenhand, 18 Fernkampf, 19 Wappenrock. (Namen aus den Spiel-Konstanten `INVTYPE_*`.)

### „Spezial einfügen“ (`Insert special`, deDE „Spezial einfügen“)
Liste `MT.scripts` (`initialise.lua:21–40`), fügt eine **Zeile mit einem eigenen Slash-Befehl** ein. Die Befehle gibt es nur, solange MacroToolkit geladen ist (Registrierung `MacroToolkit.lua:102–105`, Ausführung `DoMTMacroCommand` `MacroToolkit.lua:341–450`). **rp-macro-writer muss sie selbst implementieren**, sonst laufen die Makros ohne MacroToolkit nicht.

| Code | Name | Wirkung (Vorbild) |
|---|---|---|
| mtce | Clear UI errors | `UIErrorsFrame:Clear()` |
| mtex | Disable UI errors | `UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")` |
| mteo | Enable UI errors | `UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")` |
| mtrp | Random non-combat pet | `SummonRandomCritter()` (Retail: `C_PetJournal.SummonRandomPet`) |
| mtso | Enable sound effects | `SetCVar("Sound_EnableSFX", 1)` |
| mtsx | Disable sound effects | `SetCVar("Sound_EnableSFX", 0)` |
| mtrt | Set raid target (Parameter: Ziel, Marker 1–8) | `SetRaidTarget(unit, marker)` |
| mtev | Exit vehicle | `VehicleExit()` |
| mtmc | Print map coordinates | `GetPlayerMapPosition` (in neuen Clients entfernt → `C_Map.GetPlayerMapPosition`) |
| mttc | Toggle cloak | `ShowCloak(not ShowingCloak())` |
| mtth | Toggle helm | `ShowHelm(not ShowingHelm())` |
| mtep | Eject passenger | `EjectPassengerFromSeat` |
| mtsg | Sell grey items | graue Gegenstände an offenen Händler verkaufen, Ertrag im Chat |
| mtdg | Destroy grey items | **löscht** alle grauen Gegenstände ohne Rückfrage |
| mtnb | No food buff (Parameter: Kanal) | meldet Raidmitglieder ohne „Well Fed“ |
| mtnf | No flask (Parameter: Kanal) | meldet Raidmitglieder ohne Fläschchen |
| mtfm | Summon random favourite mount | `C_MountJournal.SummonByID(0)` |
| mtp | Print a message | Chat-Ausgabe, optional `[Bedingung] Kanal Text` mit `%t` `%f` `%c` |

## Vorgaben und Fallen für die Umsetzung

- **Eigene Befehle, anderes Präfix** (z. B. `/rp<Kürzel>`), damit es nicht mit MacroToolkits `/mt…` kollidiert, wenn beide Add-ons laufen. Registrierung über `SlashCmdList`, in einer neuen Datei (z. B. `Specials.lua`, in die TOC aufnehmen und in `tests/generator.test.js` zur Syntaxprüfung ergänzen).
- **Listen/Daten rein halten** (Namen, Kürzel, Parameter), damit sie testbar sind; Handler mit Spiel-API getrennt und mit **Schutz** schreiben (`if Funktion then … else Meldung „in dieser Spielversion nicht verfügbar“`). Spielversionen: Forever (Interface 16001) und Retail 12.1.x sind offiziell; viele alte Funktionen fehlen in Retail (`GetContainerItemInfo`, `UseContainerItem`, `PickupContainerItem` → `C_Container.*`; `GetPlayerMapPosition` → `C_Map`; `SummonRandomCritter` → `C_PetJournal`; `UnitAura` → `C_UnitAuras`). Vor dem Einsatz auf https://warcraft.wiki.gg/wiki/World_of_Warcraft_API nachschlagen (CLAUDE.md, Abschnitt Dokumentation).
- **„Destroy grey items“ löscht Gegenstände:** nur mit klarer Meldung im Chat (Anzahl), besser mit Hinweistext im Tooltip des Eintrags. Im Plan mit dem Nutzer klären, ob der Eintrag überhaupt in die Liste soll oder nur mit Bestätigung.
- **Keine `UIDropDownMenu`- oder Backdrop-Templates** (CLAUDE.md). Auswahllisten deshalb als eigene kleine Popup-Liste bauen: ein Knopf zeigt die Auswahl, ein Klick öffnet einen Rahmen (Strata `FULLSCREEN_DIALOG`) mit Zeilen; passt er unten nicht auf den Bildschirm, nach oben öffnen. Zeilen als `Button` mit Highlight-Textur. Nur `BasicFrameTemplate`, `UIPanelButtonTemplate`, `UICheckButtonTemplate`, `InputBoxTemplate` sind erlaubt.
- **Einfügen in den Makrotext:** Die Vorschau (`ui.preview`) ist ein bearbeitbares Textfeld; Einfügen schaltet in den Handmodus (`ns.state.manualBody`, siehe `ns.WriteMacro`). Einfügeposition = Cursor (`GetCursorPosition()` merkt sich die Stelle auch ohne Fokus), **nie hinter die Kennzeile `#rpmw`** (davor einfügen). Slots: Zahl an den Cursor. Spezial: als eigene Zeile (Zeilenumbruch davor und danach, falls nötig). Bei Überschreitung von 255 Zeichen greift die Klickverlängerung (`ns.ExtendBody`, bis `ns.LONG_MAX`), kein hartes Abweisen nötig; trotzdem Warnung über die Vorschau.
- **Parameter-Befehle:** `Set raid target` braucht Ziel (Standard `target`; Auswahl target/mouseover/focus/player reicht) und Marker 1–8 (Symbol `Interface\TargetingFrame\UI-RaidTargetingIcon_<n>`); `No food buff`/`No flask` einen Kanal (Chat/Party/Raid); `Print a message` einen Text (einfügen mit Platzhaltertext, den der Nutzer im Feld überschreibt). Zusatzfelder nur einblenden, wenn der Eintrag sie braucht.
- **Texte zweisprachig:** deutsche Texte als Schlüssel in `Locales.lua` (`L["…"]`), englische Übersetzung dazu. Namen der Ausrüstungsplätze am besten aus den Spiel-Konstanten (`INVTYPE_*`), dann sind sie automatisch in der Spielsprache.
- Changelog und Release Notes **englisch**; nach der Umsetzung den Nutzer fragen „Ist das so in Ordnung für dich, oder soll ich etwas anpassen?“. Im Spiel prüfen kann nur der Nutzer.

## Layout im Fenster (Stand 2026-11-12)

Die rechte Spalte ist ein Container `right` (298 breit, 560 hoch, oben rechts am Fenster). Alle Y-Werte sind Abstände von oben:
- „Makro-Art“ -32, „Sequenz zurücksetzen“ -100, „Ziel“ -148, „Ziel muss sein“ -196, **„Extras“ -266 mit Zeilen -282, -304, -326, -348, -370** (letzte Zeile endet bei etwa -392).
- Der untere Bereich (Makroname, Vorschau, Zähler, **„Gespeichert“ mit Reitern und Liste**) hängt an `BOTTOM = -94`: „Gespeichert“ steht bei `-312 + BOTTOM = -406`, die Reiter bei -402, die Liste (`SAVED_ROWS = 6`, je 22) bei -428, der Hinweis bei -572.
- Fenster: Mindestgröße `MIN_W/MIN_H = 640/620`, höchstens 1100/900 (`UI.lua` oben).

**Vorschlag:** neuer Abschnitt „Einfügen“ (zusätzliche Optionen, direkt unter „Extras“) mit zwei Zeilen: `Slot einfügen:` + Auswahlknopf + `Einfügen`, `Spezial einfügen:` + Auswahlknopf + `Einfügen`, darunter bei Bedarf die Zusatzfelder (Ziel/Marker bzw. Kanal). Dafür ~80 px Platz schaffen: `BOTTOM` um den gleichen Betrag nach unten verschieben und `MIN_H` entsprechend erhöhen (etwa 700); die linke Spalte (Ablaufliste, Makroname, Vorschau) hängt ebenfalls an `BOTTOM` und rutscht mit.

## Ebenfalls am 2026-11-12 erledigt (Nebenauftrag, ungetestet im Spiel)

Eintrag unter Optionen > AddOns (`Options.lua`): Klick öffnet das Fenster, siehe Changelog. Dasselbe Muster (`Settings.RegisterCanvasLayoutCategory`) nutzt MacroToolkit auf Forever (`modules/options.lua:904–908`).

## Schritte

1. Daten und Handler: `Specials.lua` (Liste, Kürzel, Slash-Registrierung, Handler mit Schutz), Datenanteil rein halten und testen.
2. Popup-Auswahlliste als Baustein in `UI.lua`, dann der Abschnitt „Einfügen“ mit Zusatzfeldern; Einfügefunktion `ns.InsertText(text, asLine)` in `Core.lua` (Cursor, Kennzeile, Handmodus, Refresh).
3. `Locales.lua`, TOC, Tests (`tests/generator.test.js`: Datenliste, Einfügeposition als reine Funktion), `CHANGELOG.md` (englisch, `[Unreleased]`), README/CurseForge-Beschreibung, `CLAUDE.md` (Tabelle Aufbau), Memory.
4. Commit und Push, Nutzer fragen. Release nur auf Wunsch (zunächst `--prerelease`, solange der Nutzer nichts anderes sagt).

## Offene Fragen an den Nutzer

1. Soll „Destroy grey items“ (löscht Gegenstände) dabei sein, und wenn ja mit welcher Absicherung?
2. Reicht ein eigenes Präfix für die Befehle (Vorschlag `/rp…`), oder soll es ein anderes sein?
