-- Rotations/Druid.lua – Rotation fuer Druide (DRUID), Rueckfall fuer "Beste Rotation".
--
-- STATUS: unverified
--   unverified      = recherchiert, aber nicht gegen den Dump der Rotationshilfe abgeglichen
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
--   2026-11-11  Neu recherchiert: Retail = Katze (Wilder Kampf) Patch 12.1.5, Forever = Katze/Caster-Levelrotation.
--               Kein Dump (rotationDump) fuer DRUID vorhanden. IDs per Wowhead belegt.
local ADDON, ns = ...

ns.RegisterRotation("DRUID", {
    status = "unverified",
    updated = "2026-11-11",
    source = "Method + Maxroll (Retail 12.1.5, Okt 2026); Warcraft Tavern Forever + Icy Veins Classic (Klassik-Basis)",
    -- Standard (Retail-Katze)
    dots = {
        { 1822, "Rake" },
        { 1079, "Rip" },
    },
    fillers = {
        { 5221, "Shred" },
    },
    retail = {
        sources = {
            "https://www.method.gg/guides/feral-druid/playstyle-and-rotation (Retail 12.1.5, 28.10.2026)",
            "https://maxroll.gg/wow/class-guides/feral-druid-raid-guide (Retail 12.1.5, 19.10.2026)",
            "https://www.wowhead.com/spell=1822 / 1079 / 8921 / 5221 (IDs belegt)",
        },
        comparison = "Method und Maxroll stimmen ueberein: Cooldowns (Tiger's Fury, Berserk), dann Rip und Ferocious Bite als " ..
            "Finisher, Rake/Moonfire halten, Shred als Fueller. Cooldowns und Bite (Energie-/Comboabhaengig) bleiben " ..
            "draussen, da das Makro Combopunkte nicht prueft. Kein Dump der Rotationshilfe vorhanden, daher unverified.",
        dots = {
            { 1822, "Rake" },
            { 1079, "Rip" },
        },
        fillers = {
            { 5221, "Shred" },
        },
    },
    classic = {
        sources = {
            "https://www.warcrafttavern.com/forever/guides/druid-leveling/ (Forever, ohne Datum)",
            "https://www.icy-veins.com/wow-classic/feral-druid-leveling-talent-build-from-1-to-60 (Classic, laut Suche Jul 2026; Seite nicht abrufbar, nur Suchauszug)",
            "https://www.wowhead.com/classic/spell=1822 / 1079 / 1082 / 8921 / 5176 (Rang-1-IDs belegt)",
        },
        comparison = "Beide Quellen: Katzenform, Rake halten, Rip bei 5 Combopunkten, Claw (oder Shred von hinten) als " ..
            "Combopunkt-Aufbau. Claw statt Shred, da Shred Positionierung braucht. Ab Stufe 20 (Katze); ohne Katzenform " ..
            "faellt der Spieler auf den Caster-Pull Moonfire/Wrath zurueck (nicht abgebildet). Rang-Namen loest das Spiel " ..
            "ueber den Namen auf. Kein Dump vorhanden.",
        dots = {
            { 1822, "Rake" },
            { 1079, "Rip" },
        },
        fillers = {
            { 1082, "Claw" },
            { 5221, "Shred" },
            { 5176, "Wrath" },
        },
    },
})
