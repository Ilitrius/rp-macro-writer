-- Rotations/Rogue.lua – Rotation fuer Schurke (ROGUE), Rueckfall fuer "Beste Rotation".
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
--   2026-11-11  Neu recherchiert: Retail (Assassination, 12.1.5) und Forever/Classic (Combat). IDs per Wowhead belegt. Kein Dump vorhanden.
local ADDON, ns = ...

ns.RegisterRotation("ROGUE", {
    status = "unverified",
    updated = "2026-11-11",
    source = "Method.gg 12.1.5 (Retail), Warcraft Tavern Forever (undatiert); IDs Wowhead. Kein rotationDump vorhanden.",
    retail = {
        sources = {
            "Retail 12.1.5 (Assassination, Stand 2026-10-18): https://www.method.gg/guides/assassination-rogue/playstyle-and-rotation",
            "Retail 12.1.5 (Stand 2026-10-13, nur Kopf lesbar): https://www.wowhead.com/guide/classes/rogue/assassination/rotation-cooldowns-pve-dps",
        },
        comparison = "Kein Dump vorhanden, nicht mit der Rotationshilfe abgeglicht. Method: Garrote und Rupture halten, Mutilate aufbauen, Envenom ab 5 CP (nicht aufgenommen, Makro kennt CP nicht). Nur Assassination abgedeckt. IDs Wowhead belegt.",
        dots = {
            { 703, "Garrote" },
            { 1943, "Rupture" },
        },
        fillers = {
            { 1329, "Mutilate" },
        },
    },
    classic = {
        sources = {
            "Forever (Combat, undatiert, 2026): https://www.warcrafttavern.com/forever/guides/combat-rogue/",
            "Forever (Suchtreffer, 403 nicht lesbar): https://www.icy-veins.com/wow-forever/combat-rogue-melee-dps-pve-rotation-cooldowns-abilities",
        },
        comparison = "Kein Dump vorhanden. Warcraft Tavern: Sinister Strike (Dolch: Backstab), Slice and Dice hoechste Prioritaet, Eviscerate bei 5 CP (nicht aufgenommen, CP unbekannt). Zweite Quelle nicht lesbar, daher nur eine Quelle.",
        dots = {
            { 5171, "Slice and Dice" },
        },
        fillers = {
            { 1752, "Sinister Strike" },
            { 53, "Backstab" },
        },
    },
})
