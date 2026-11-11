-- Rotations/Hunter.lua – Rotation fuer Jäger (HUNTER), Rueckfall fuer "Beste Rotation".
--
-- STATUS: unverified
--   unverified      = IDs im Wowhead belegt, aber weder im Spiel noch gegen die Rotationshilfe geprueft
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
--   2026-11-11  Neu aufgebaut aus Quellen, getrennt nach retail (Beast Mastery) und classic (unverified, kein Dump vorhanden).
local ADDON, ns = ...

ns.RegisterRotation("HUNTER", {
    status = "unverified",
    updated = "2026-11-11",
    source = "Method (Retail 12.1.5) und Warcraft Tavern (Classic); IDs per Wowhead belegt; kein Dump der Rotationshilfe",
    dots = {
        { 1130, "Hunter's Mark" },
        { 1978, "Serpent Sting" },
    },
    fillers = {
        { 3044, "Arcane Shot" },
    },
    retail = {
        sources = {
            { "https://method.gg/guides/beast-mastery-hunter/playstyle-and-rotation", "Retail 12.1.5, Stand 2026-10-13, Beast Mastery" },
            { "https://www.icy-veins.com/wow/beast-mastery-hunter-pve-dps-spec-builds-talents", "Retail 12.0.5, nur Suchausschnitt (Seite gab 403): Hunter's Mark halten, Kill Command so oft wie moeglich" },
        },
        comparison = "Nur Beast Mastery recherchiert (Marksmanship/Survival offen). Method: Barbed Shot, Bestial Wrath bei <1 Charge, Kill Command, "
            .. "Cobra Shot als Filler. Icy Veins (Ausschnitt): Hunter's Mark auf dem Ziel halten, Kill Command oft. Kill Command ist hier als Filler vor "
            .. "Cobra Shot gesetzt (Annahme, Reihenfolge Cobra/Kill Command nicht ausdruecklich belegt). Bestial Wrath (19574) weggelassen (Cooldown, "
            .. "Talent-Logik). IDs per Wowhead belegt: 257284, 217200, 34026, 193455. Kein Dump der Rotationshilfe.",
        dots = {
            { 257284, "Hunter's Mark" },
            { 217200, "Barbed Shot" },
        },
        fillers = {
            { 34026, "Kill Command" },
            { 193455, "Cobra Shot" },
        },
    },
    classic = {
        sources = {
            { "https://warcrafttavern.com/wow-classic/guides/pve-marksmanship-hunter-rotations-cooldowns", "Classic, undatiert, Marksmanship" },
            { "https://www.icy-veins.com/wow-classic/hunter-dps-pve-rotation-cooldowns-abilities", "Classic, nur Suchausschnitt (403): Auto Shot, Aimed Shot, Multi-Shot; Arcane Shot teilt Abklingzeit mit Aimed Shot" },
        },
        comparison = "Tavern: Hunter's Mark, Multi-Shot, Serpent Sting, Aimed Shot als Hauptzauber zwischen Auto Shots. Icy Veins: nur Aimed Shot und "
            .. "Multi-Shot, Serpent Sting nicht; Aimed Shot und Arcane Shot teilen sich Abklingzeit. Entscheidung: Hunter's Mark + Serpent Sting als Aufbau, "
            .. "Aimed Shot, Multi-Shot, Arcane Shot als Filler. Beide Quellen nicht Forever-spezifisch; ob Forever Raenge/Steady Shot hat, ungeprueft. "
            .. "IDs Wowhead Classic: 1130, 1978, 3044, 19434, 2643 (Basisraenge). Kein Dump der Rotationshilfe.",
        dots = {
            { 1130, "Hunter's Mark" },
            { 1978, "Serpent Sting" },
        },
        fillers = {
            { 19434, "Aimed Shot" },
            { 2643, "Multi-Shot" },
            { 3044, "Arcane Shot" },
        },
    },
})
