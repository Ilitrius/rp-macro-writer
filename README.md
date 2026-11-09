# rp-macro-writer

World-of-Warcraft-Addon: Zauber per Drag & Drop zu Makros kombinieren. Schwerpunkt zunächst Hexenmeister (DoTs, Flüche, Begleiter), funktioniert aber mit jeder Klasse.

## Benutzung
1. `/mw` öffnet das Fenster.
2. Zauber aus dem Zauberbuch (oder Gegenstände aus den Taschen) in die Liste „Ablauf“ ziehen.
3. Rechts Art, Reset, Ziel und Extras wählen – die Vorschau unten zeigt den Makrotext sofort.
4. Namen eingeben, **Makro erstellen**, dann mit **Auf Leiste** auf eine Aktionsleiste ziehen.

Bei „Automatisch erkennen“ wird aus einem Zauber ein einfacher Cast und aus mehreren eine Cast-Sequenz.

## Installation zum Testen
Den Projektordner als `rp-macro-writer` in den AddOns-Ordner der gewünschten Spielvariante verknüpfen (PowerShell, einmalig):

```powershell
New-Item -ItemType Junction -Path "D:\Games\Battle.net\World of Warcraft\_retail_\Interface\AddOns\rp-macro-writer" -Target "D:\AI_KI\rp-macro-writer"
```

Danach im Spiel `/reload`.

## Entwicklung
- `Generator.lua` – Makrotext aus Schritten + Optionen (ohne WoW-API, testbar)
- `Core.lua` – Zustand, Drag & Drop, Makros im Spiel anlegen
- `UI.lua` – Fenster
- Tests: `cd tests; npm install; npm test`
- Icon neu erzeugen: `node tools/make-icon.js`

## Veröffentlichen
Versionsverlauf in [CHANGELOG.md](CHANGELOG.md), Release Notes je Version in [docs/release-notes](docs/release-notes). Ablauf siehe [CLAUDE.md](CLAUDE.md).
