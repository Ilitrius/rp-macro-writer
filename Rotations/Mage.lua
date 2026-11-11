-- Rotations/Mage.lua – Rotation fuer Magier (MAGE), Rueckfall fuer "Beste Rotation".
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
--   2026-11-11  Neu aufgebaut mit Varianten retail/classic, Quellen und Vergleich. Kein Dump fuer MAGE vorhanden.
local ADDON, ns = ...

-- Hinweis: Magier haben je Spezialisierung andere Hauptzauber (Arkan: Arcane Blast, Feuer: Fireball, Frost: Frostbolt).
-- Dauerschaden-Aufbau per Makro gibt es nicht; "dots" bleibt leer. Welcher Fuellzauber greift, entscheidet "bekannt".
-- Zauber-IDs 30451, 116, 133, 2948, 11366 per Wowhead (/spell=ID) belegt; Arcane Missiles (5143) nicht erneut geprueft.
ns.RegisterRotation("MAGE", {
    status = "unverified",
    updated = "2026-11-11",
    source = "Retail: Noxxic (SimC mage_fire, 12.1.5); Forever: Warcraft Tavern; ohne Rotationshilfe-Dump",
    sources = {
        "retail 12.1.5: https://www.noxxic.com/wow/guide/fire-mage/dps-rotation-and-cooldowns (SimC-Prioritaet Feuer: Pyroblast bei Hot Streak, Scorch in Execute, Fireball, Fire Blast)",
        "retail 12.0/12.1: https://www.icy-veins.com/fire-mage-wow-pve-dps-rotation-cooldowns-abilities (nur Suchtreffer, Seite 403; Stand Midnight Pre-Patch 12.0, daher nur Hinweis)",
        "retail 12.1.5: https://www.wowhead.com/tw/guide/classes/mage/fire/overview-pve-dps (Stand 2026-10-13, Rotationstabelle nicht lesbar)",
        "forever: https://www.warcrafttavern.com/forever/guides/mage-leveling/ (ohne Datum, Nov. 2026; Arkan Arcane Blast, Feuer Fireball/Fire Blast/Scorch/Pyroblast, Frost Frostbolt/Ice Lance)",
        "classic: https://warcrafttavern.com/guides/mage-leveling-guide (Classic-Leveling: Fireball bis Stufe 4, dann Frostbolt, Arcane Missiles, Zauberstab)",
    },
    comparison = "Quellen sind spezifikationsabhaengig. Retail (Feuer) und Forever stimmen im Fuellzauber je Spezialisierung ueberein "
        .. "(Arcane Blast / Fireball / Frostbolt). Ein spezifikationsloser Makro-Rueckfall bleibt deshalb bei der Reihenfolge Arcane Blast, "
        .. "Fireball, Frostbolt; die Reihenfolge ist Annahme, nicht quellenbelegt. Offen: Abgleich mit /mw rotation, nur eine echte Quelle je Version lesbar (Icy Veins/Mobalytics 403).",
    dots = {},
    fillers = {
        { 30451, "Arcane Blast" },
        { 133, "Fireball" },
        { 116, "Frostbolt" },
    },
    retail = {
        dots = {},
        fillers = {
            { 30451, "Arcane Blast" },
            { 133, "Fireball" },
            { 116, "Frostbolt" },
            { 5143, "Arcane Missiles" },
        },
    },
    classic = {
        dots = {},
        fillers = {
            { 116, "Frostbolt" },
            { 133, "Fireball" },
            { 30451, "Arcane Blast" },
        },
    },
})
