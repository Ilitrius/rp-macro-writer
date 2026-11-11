-- Rotations/Priest.lua – Rotation fuer Priester (PRIEST), Rueckfall fuer "Beste Rotation".
--
-- STATUS: unverified
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
--   2026-11-11  Neu aufgebaut mit Varianten retail (Shadow, Midnight 12.1.5; Method + Noxxic) und classic
--               (Classic/Forever, Shadow-Levelrotation; Icy Veins/Noob to Boss). Kein Dump vorhanden. unverified.
local ADDON, ns = ...

ns.RegisterRotation("PRIEST", {
    status = "unverified",
    updated = "2026-11-11",
    source = "Method + Noxxic (Retail 12.1.5), Icy Veins + Noob to Boss (Classic); kein Dump der Rotationshilfe",
    retail = {
        sources = {
            "https://www.method.gg/guides/shadow-priest/playstyle-and-rotation (Retail 12.1.5, Shadow, 2026-11-11)",
            "https://www.noxxic.com/wow/guide/shadow-priest/dps-rotation-and-cooldowns (Retail 12.1.5, SimC-Liste, 2026-11-11)",
        },
        comparison = "Method und Noxxic stimmen ueberein: Vampiric Touch halten, Shadow Word: Madness, Mind Blast, Mind Flay als Fueller. Shadow Word: Pain nur mit Invoked Nightmare, daher nicht aufgenommen. Kein Dump der Rotationshilfe vorhanden.",
        dots = {
            { 34914, "Vampiric Touch" },
            { 335467, "Shadow Word: Madness" },
            { 8092, "Mind Blast" },
        },
        fillers = {
            { 15407, "Mind Flay" },
        },
    },
    classic = {
        sources = {
            "https://www.icy-veins.com/wow-classic/shadow-priest-leveling-talent-build-from-1-to-60 (Classic, nur Suchauszug)",
            "https://noobtoboss.com/?p=5409 (Classic Shadow Leveling, nur Suchauszug)",
        },
        comparison = "Beide: Mind Blast, Shadow Word: Pain, Mind Flay, dann Wand/Smite. IDs 585/589 auf Wowhead classic geprueft. Quellen nur aus Suchauszuegen, schwach belegt; kein Dump.",
        dots = {
            { 589, "Shadow Word: Pain" },
            { 8092, "Mind Blast" },
        },
        fillers = {
            { 15407, "Mind Flay" },
            { 585, "Smite" },
        },
    },
    dots = {
        { 589, "Shadow Word: Pain" },
        { 8092, "Mind Blast" },
    },
    fillers = {
        { 15407, "Mind Flay" },
        { 585, "Smite" },
    },
})
