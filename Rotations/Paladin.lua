-- Rotations/Paladin.lua – Rotation fuer Paladin (PALADIN), Rueckfall fuer "Beste Rotation".
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
--   2026-11-11  Neu aufgebaut aus Quellen, getrennt nach retail und classic (unverified, kein Dump vorhanden).
local ADDON, ns = ...

ns.RegisterRotation("PALADIN", {
    status = "unverified",
    updated = "2026-11-11",
    source = "Method (Retail 12.1.5), Warcraft Tavern + wowtbc.gg (Classic); IDs per Wowhead belegt",
    dots = {
        { 20271, "Judgement" },
    },
    fillers = {
        { 26573, "Consecration" },
    },
    retail = {
        sources = {
            { "https://www.method.gg/guides/retribution-paladin/playstyle-and-rotation", "Retail 12.1.5, Stand 2026-10-13, Retribution (Templar/Herald of the Sun)" },
            { "https://www.wowhead.com/guide/classes/paladin/retribution/rotation-cooldowns-pve-dps", "Retail 12.1.5, 2026-10-13; Inhalt nicht abrufbar, nur Metadaten" },
        },
        comparison = "Nur Method lieferte die Prioritaet: Wake of Ashes, Blade of Justice, Judgment als Heilige-Kraft-Erzeuger, Final Verdict als Verbraucher, "
            .. "Hammer of Wrath nach Abklingzeit/Proc. Cooldowns (Avenging Wrath, Execution Sentence, Divine Toll) weggelassen. Templar Strike/Slash (ID 406647 = Templar Slash) weggelassen. "
            .. "Zweite Quelle (Icy Veins 403, Wowhead ohne Inhalt) fehlt. Kein Dump der Rotationshilfe.",
        dots = {
            { 255937, "Wake of Ashes" },
            { 184575, "Blade of Justice" },
            { 20271, "Judgment" },
        },
        fillers = {
            { 383328, "Final Verdict" },
            { 24275, "Hammer of Wrath" },
        },
    },
    classic = {
        sources = {
            { "https://www.warcrafttavern.com/wow-classic/guides/pve-retribution-paladin-rotations-amp-cooldowns/", "Classic, ohne Datum" },
            { "https://wowtbc.gg/classic/class-guides/retribution-paladin", "Classic, ohne Datum" },
        },
        comparison = "Beide: Seal of Command halten, Judgement, Consecration (bei Vengeance/ueberschuessigem Mana), Hammer of Wrath unter 20 %, Exorcism gegen Untote/Daemonen. "
            .. "Crusader Strike gibt es in der Classic-Basis nicht (entfernt). Seal-Twisting und Seal of the Crusader per Makro nicht sinnvoll. "
            .. "IDs sind Rang 1 (Seal of Command 20920, Consecration 26573); hoehere Raenge haben andere IDs, im Spiel pruefen. Forever-spezifische Quelle fehlt (Mobalytics 403). Kein Dump.",
        dots = {
            { 20920, "Seal of Command" },
            { 20271, "Judgement" },
        },
        fillers = {
            { 26573, "Consecration" },
            { 24275, "Hammer of Wrath" },
        },
    },
})
