-- Rotations/Warlock.lua – Rotation fuer Hexenmeister (WARLOCK), Rueckfall fuer "Beste Rotation".
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
--   2026-11-11  Neu aufgebaut aus Quellen, getrennt nach retail und classic (unverified, kein Dump vorhanden).
local ADDON, ns = ...

ns.RegisterRotation("WARLOCK", {
    status = "unverified",
    updated = "2026-11-11",
    source = "Method + Maxroll (Retail 12.1.5), Warcraft Tavern (Classic); IDs/Namen per Wowhead belegt",
    dots = {
        { 980, "Curse of Agony" },
        { 172, "Corruption" },
        { 348, "Immolate" },
        { 18265, "Siphon Life" },
    },
    fillers = {
        { 686, "Shadow Bolt" },
    },
    retail = {
        sources = {
            { "https://www.method.gg/guides/affliction-warlock/playstyle-and-rotation", "Retail 12.1.5, Stand 2026-10-13, Affliction" },
            { "https://maxroll.gg/wow/class-guides/affliction-warlock-mythic-plus-guide", "Retail 12.1.5, Stand 2026-10-15, Affliction" },
        },
        comparison = "Beide: Agony + Corruption halten (Hellcaller: Wither), Haunt nach Abklingzeit, Unstable Affliction als Splitter-Verbraucher, "
            .. "Filler Drain Soul (Soul Harvester) bzw. Shadow Bolt (Hellcaller). Method nennt Malefic Grasp (ID nicht belegt, weggelassen). "
            .. "Cooldowns (Darkglare, Dark Harvest, Malevolence) fehlen. UA: ID 30108 belegt, 316099 nicht auffindbar. Kein Dump der Rotationshilfe.",
        dots = {
            { 980, "Agony" },
            { 172, "Corruption" },
            { 48181, "Haunt" },
            { 30108, "Unstable Affliction" },
        },
        fillers = {
            { 198590, "Drain Soul" },
            { 686, "Shadow Bolt" },
        },
    },
    classic = {
        sources = {
            { "https://www.warcrafttavern.com/wow-classic/guides/pve-warlock-rotation", "Classic (SoM/Anniversary-Text), ohne Datum" },
            { "https://www.warcrafttavern.com/wow-classic/guides/warlock-leveling-guide/", "Classic Leveling, ohne Datum" },
        },
        comparison = "DoTs Immolate, Corruption, Curse of Agony, Siphon Life, Filler Shadow Bolt; Leveling-Quelle nennt Wand/Drain Life (per Makro nicht sinnvoll). "
            .. "Beide Quellen undatiert, Forever-spezifische Quelle fehlt (Icy Veins gab 403). Kein Dump der Rotationshilfe.",
        dots = {
            { 348, "Immolate" },
            { 172, "Corruption" },
            { 980, "Curse of Agony" },
            { 18265, "Siphon Life" },
        },
        fillers = {
            { 686, "Shadow Bolt" },
        },
    },
})
