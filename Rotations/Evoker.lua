-- Rotations/Evoker.lua – Rotation fuer Rufer (EVOKER), Rueckfall fuer "Beste Rotation".
--
-- STATUS: unverified (kein Dump der Rotationshilfe vorhanden, nicht im Spiel geprueft)
--   unverified      = Zauber-IDs aus Quellen belegt, aber weder im Spiel noch gegen die Rotationshilfe geprueft
--   helper-matched  = deckt sich mit dem Dump der Blizzard-Rotationshilfe ("/mw rotation", siehe unten)
--   game-verified   = vom Nutzer im Spiel geprueft
--
-- SPIELVERSIONEN
--   Der Rufer existiert nur in Retail. WoW Forever (Client 1.60.x) hat nur die neun Classic-Klassen
--   (Quellen: seemeta.com, warcrafttavern.com), deshalb gibt es hier nur die Variante "retail".
--   Die obersten Listen (dots/fillers) sind der Standard und entsprechen der Retail-Variante.
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
--   2026-11-11  Neu aufgebaut aus Method + Maxroll (Devastation, Retail 12.1.5); Forever hat keinen Rufer (unverified, kein Dump).
local ADDON, ns = ...

ns.RegisterRotation("EVOKER", {
    status = "unverified",
    updated = "2026-11-11",
    source = "Method + Maxroll (Retail 12.1.5, Devastation); IDs per Wowhead belegt; Forever: Klasse existiert nicht",
    dots = {
        { 357208, "Fire Breath" },
        { 359073, "Eternity Surge" },
    },
    fillers = {
        { 356995, "Disintegrate" },
        { 361469, "Living Flame" },
        { 362969, "Azure Strike" },
    },
    retail = {
        sources = {
            { "https://www.method.gg/guides/devastation-evoker/playstyle-and-rotation", "Retail 12.1.5, Stand 2026-10-16, Devastation" },
            { "https://maxroll.gg/wow/class-guides/devastation-evoker-mythic-plus-guide", "Retail 12.1.5, Stand 2026-10-12/11-02 (Angaben widerspruechlich), Devastation M+" },
        },
        comparison = "Beide: Fire Breath und Eternity Surge nach Abklingzeit, danach Disintegrate (Essence ausgeben), Filler Living Flame, "
            .. "Azure Strike bei Bewegung. Reihenfolge Fire Breath/Eternity Surge weicht leicht ab (Method: Fire Breath zuerst, Maxroll: Eternity Surge zuerst); "
            .. "gewaehlt Fire Breath zuerst. Nicht aufgenommen: Deep Breath, Dragonrage (Cooldowns), Unbound Flame/Azure Sweep (Talent, ID nicht belegt), "
            .. "Pyre (nur AoE). Empower-Zauber per Makro werden ohne Halten gewirkt (Stufe 1); Verhalten im Spiel pruefen. "
            .. "Icy Veins gab 403. Nur Devastation recherchiert; Preservation/Augmentation nicht. Kein Dump der Rotationshilfe.",
        dots = {
            { 357208, "Fire Breath" },
            { 359073, "Eternity Surge" },
        },
        fillers = {
            { 356995, "Disintegrate" },
            { 361469, "Living Flame" },
            { 362969, "Azure Strike" },
        },
    },
})
