# Versionsverlauf

Alle nennenswerten Änderungen an MakroWriter stehen in dieser Datei.
Das Format folgt [Keep a Changelog](https://keepachangelog.com/de/1.1.0/), die Versionsnummern folgen [Semantic Versioning](https://semver.org/lang/de/).

## [0.1.0] – noch nicht veröffentlicht

Erste Fassung. Im Spiel noch nicht getestet.

### Neu
- Fenster mit `/mw` (auch `/makrowriter`, `/macrowriter`); ESC schließt es.
- Zauber, Begleiterfähigkeiten und Gegenstände per Drag & Drop aus Zauberbuch und Taschen in die Ablaufliste ziehen; Reihenfolge per Pfeil ändern, einzelne Einträge entfernen.
- **Automatische Erkennung:** ein Zauber ergibt einen einfachen Cast (`/cast`), mehrere ergeben eine Cast-Sequenz (`/castsequence`).
- Reset der Sequenz bei Zielwechsel, bei Kampfende und/oder nach einstellbaren Sekunden.
- Ziel-Bedingungen: Feind / Freund / egal sowie am Leben / tot / egal; wahlweise zuerst Mouseover oder Fokus, danach das aktuelle Ziel.
- Weitere Makro-Arten: Zusatztaste (Shift / Strg / Alt je Zauber), einzelne Zeilen, Zufall (`/castrandom`).
- Extras: `#showtooltip`, Begleiter angreifen lassen, automatisch Gegner wählen, kanalisierte Zauber nicht abbrechen, Makro nur für diesen Charakter.
- Live-Vorschau des Makrotexts mit Zeichenzähler (Grenze 255) und Warnhinweisen.
- Makro direkt im Spiel anlegen oder aktualisieren und per „Auf Leiste“ auf eine Aktionsleiste ziehen.
- Gespeicherte Kombinationen: jede erstellte Kombination lässt sich später wieder laden und ändern.
- Unterstützte Spielvarianten laut TOC: Retail 12.1.x, Mists Classic, Wrath (Titan Reforged), TBC Classic, Forever, Classic Era.
