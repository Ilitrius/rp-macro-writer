-- Rotations/DemonHunter.lua – Rotation fuer Dämonenjäger (DEMONHUNTER), Rueckfall fuer "Beste Rotation".
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
--   2026-11-11  Neu aufgebaut (Havoc) aus Method + Maxroll, IDs per Wowhead belegt. Nur retail: Daemonenjaeger gibt es in
--               WoW Forever / Classic nicht (Klasse stammt aus Legion; Forever startet mit den 9 Classic-Klassen). unverified.
local ADDON, ns = ...

ns.RegisterRotation("DEMONHUNTER", {
    status = "unverified",
    updated = "2026-11-11",
    source = "Method + Maxroll (Retail 12.1.5, Havoc), IDs per Wowhead belegt; nur Retail, Klasse fehlt in Forever/Classic",
    dots = {
        { 258920, "Immolation Aura" },
        { 198013, "Eye Beam" },
        { 258860, "Essence Break" },
        { 188499, "Blade Dance" },
    },
    fillers = {
        { 162794, "Chaos Strike" },
        { 232893, "Felblade" },
    },
    retail = {
        sources = {
            { "https://www.method.gg/guides/havoc-demon-hunter/playstyle-and-rotation", "Retail 12.1.5, Stand 2026-10-16, Havoc" },
            { "https://maxroll.gg/wow/class-guides/havoc-demon-hunter-mythic-plus-guide", "Retail 12.1.5, Stand 2026-10-17/19, Havoc" },
        },
        comparison = "Beide: Essence Break mit Eye Beam, Eye Beam nach Abklingzeit, Blade Dance, Chaos Strike als Filler, Felblade fuer Fury. "
            .. "Method: Reaver's Glaive/The Hunt zuerst (Hero-Talent-abhaengig), Fel-Scarred Immolation Aura bei 2 Aufladungen; Maxroll stellt Eye Beam vor Essence Break. "
            .. "Metamorphose-Varianten (Death Sweep 210152, Annihilation 201427, belegt) ersetzen Blade Dance/Chaos Strike und sind per Name nicht stabil, daher weggelassen; "
            .. "Vengeful Retreat/The Hunt (Mobilitaet/Cooldown) weggelassen. Nur Havoc; Vengeance und Devourer nicht recherchiert. Kein Dump der Rotationshilfe.",
        dots = {
            { 258920, "Immolation Aura" },
            { 198013, "Eye Beam" },
            { 258860, "Essence Break" },
            { 188499, "Blade Dance" },
        },
        fillers = {
            { 162794, "Chaos Strike" },
            { 232893, "Felblade" },
        },
    },
    -- classic: bewusst nicht vorhanden (Klasse existiert in Forever/Classic nicht)
})
