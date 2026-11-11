-- Rotations/DeathKnight.lua – Rotation fuer Todesritter (DEATHKNIGHT), Rueckfall fuer "Beste Rotation".
--
-- STATUS: unverified (kein Dump der Rotationshilfe vorhanden, nicht im Spiel geprueft)
--   unverified      = Zauber-IDs aus dem Gedaechtnis eingetragen, weder im Spiel noch im Wiki geprueft
--   helper-matched  = deckt sich mit dem Dump der Blizzard-Rotationshilfe ("/mw rotation", siehe unten)
--   game-verified   = vom Nutzer im Spiel geprueft
--
-- WIE DIE ROTATION ENTSTEHT
--   1. Erste Quelle im Addon ist die Rotationshilfe des Spiels (C_AssistedCombat.GetRotationSpells), siehe Core.lua.
--   2. Diese Datei ist der Rueckfall, falls die Hilfe nichts liefert. "dots" = Aufbau/Dauerschaden in dieser
--      Reihenfolge, "fillers" = Fuellzauber (der erste bekannte wird ns.FILLER_REPEAT-mal ans Ende gesetzt).
--   3. Welche Zauber der Charakter kennt, entscheidet das Spiel (Level, Talente, Spezialisierung).
--   4. Nachvollziehen/Erneuern: "/mw rotation" auf einem Charakter dieser Klasse ausfuehren; der Dump landet in
--      SavedVariables/rp-macro-writer.lua unter rotationDump. Der Agent "rotation-helper" gleicht ihn mit dieser
--      Datei ab und aktualisiert sie.
--
-- AENDERUNGSVERLAUF
--   2026-11-11  Ausgangsstand aus der Sammeltabelle uebernommen (unverified).
--   2026-11-11  Neu aufgebaut: Retail (Frost, 12.1.5) aus Method + Maxroll, IDs per Wowhead belegt (unverified, kein Dump).
--               Classic/Forever: Todesritter existiert in WoW Forever (Client 1.60.x) nicht (nur die 9 Classic-Klassen),
--               daher keine classic-Variante. Die alte Wrath-Rotation (Icy Touch/Plague Strike) war fuer Forever falsch.
local ADDON, ns = ...

ns.RegisterRotation("DEATHKNIGHT", {
    status = "unverified",
    updated = "2026-11-11",
    source = "Method + Maxroll (Retail 12.1.5, Frost); Forever: Klasse nicht vorhanden; IDs per Wowhead belegt",
    dots = {
        { 51271, "Pillar of Frost" },
        { 49184, "Howling Blast" },
    },
    fillers = {
        { 49020, "Obliterate" },
        { 49143, "Frost Strike" },
    },
    retail = {
        sources = {
            { "https://www.method.gg/guides/frost-death-knight/playstyle-and-rotation", "Retail 12.1.5, Stand 2026-10-13, Frost" },
            { "https://maxroll.gg/wow/class-guides/frost-death-knight-raid-guide", "Retail 12.1.5, Stand 2026-10-13/21, Frost" },
        },
        comparison = "Nur Frost betrachtet. Beide: Pillar of Frost auf Abklingzeit, Howling Blast bei Rime, Obliterate (Killing Machine bevorzugt) als Hauptzauber, "
            .. "Frost Strike gegen Runic-Power-Ueberlauf. Abweichung: Method setzt Pillar zuerst, Maxroll Empower Rune Weapon/Reaper's Mark davor; Method nennt Frost Strike "
            .. "vor Obliterate bei <=1 Rune. Cooldowns (Frostwyrm's Fury, Breath of Sindragosa, Empower Rune Weapon, Reaper's Mark) weggelassen. "
            .. "Blood/Unholy nicht recherchiert; Rotation ist fuer Frost, andere Spezialisierungen kennen die Zauber evtl. nicht. Kein Dump der Rotationshilfe.",
        dots = {
            { 51271, "Pillar of Frost" },
            { 49184, "Howling Blast" },
        },
        fillers = {
            { 49020, "Obliterate" },
            { 49143, "Frost Strike" },
        },
    },
    -- classic: bewusst nicht gesetzt, Todesritter existiert in WoW Forever (1.60.x) nicht.
})
