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
--   2026-11-11  classic.trees fuer Arcane/Fire/Frost (Forever, Warcraft Tavern), keine Stufenbaender (Bekannt-Filter deckt Stufen ab).
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
        -- Reihenfolge der Registerkarten Arcane, Fire, Frost: Annahme (klassische Reihenfolge, Warcraft-Tavern-Guides
        -- nennen sie in dieser Folge); Wowhead-Talentrechner nicht lesbar. Im Spiel pruefen (/mw rotation: tree).
        trees = {
            [1] = {
                name = "Arcane",
                dots = {},
                fillers = {
                    { 30451, "Arcane Blast" },
                    { 5143, "Arcane Missiles" },
                    { 116, "Frostbolt" },
                    { 133, "Fireball" },
                },
                sources = {
                    "forever: https://www.warcrafttavern.com/forever/guides/arcane-mage/ (ohne Datum, Nov. 2026; Arcane Blast Aufbau, Missiles bei Missile Barrage, Arcane Wrath, Fire Blast/Scorch/Pyroblast in Stapeln)",
                    "forever: https://www.warcrafttavern.com/forever/guides/mage-leveling/ (Nov. 2026; Level 1-3 Fireball, ab 4 Frostbolt, ab 8 Arcane Missiles, ab 20 Arcane Blast Hauptzauber)",
                },
                comparison = "Beide Quellen stimmen: Arcane Blast ist der Hauptzauber (ab Stufe 20), Arcane Missiles auf Missile Barrage. "
                    .. "Proc-/Cooldown-Zauber (Arcane Wrath, Fire Blast, Pyroblast, Arcane Power) sind per Makro nicht sinnvoll und fehlen. "
                    .. "Unter Stufe 20 faellt der Bekannt-Filter auf Arcane Missiles/Frostbolt/Fireball zurueck. IDs: 5143 per Wowhead Classic belegt, "
                    .. "30451 (Arcane Blast) in Wowhead Classic nicht gelistet (Retail-ID, ungeprueft fuer Forever).",
            },
            [2] = {
                name = "Fire",
                dots = {
                    { 2948, "Scorch" },
                    { 2136, "Fire Blast" },
                },
                fillers = {
                    { 133, "Fireball" },
                    { 116, "Frostbolt" },
                },
                sources = {
                    "forever: https://www.warcrafttavern.com/forever/guides/fire-mage/ (ohne Datum, Nov. 2026; Scorch bis 5 Improved Scorch, Fire Blast auf Cooldown, Fireball Fueller, Pyroblast bei 3 Heating Up)",
                    "forever: https://wowtbc.gg/warcraftforever/class-guides/fire-mage/ (ohne Datum, 2026; Improved Scorch halten, Pyroblast bei Heating Up, Fire Blast, Frostfire Bolt)",
                    "forever: https://www.warcrafttavern.com/forever/guides/mage-leveling/ (Fire: Fireball, ab 6 Fire Blast, ab 20 Pyroblast, ab 22 Scorch)",
                },
                comparison = "Quellen stimmen bei Scorch-Aufbau (Improved Scorch), Fire Blast und Fireball als Fueller ueberein. Pyroblast (Heating Up) ist "
                    .. "proc-/Vorab-Zauber und fehlt im Makro. Frostfire Bolt (wowtbc.gg, Tavern-Variante) ist nur Nebenbuild, nicht aufgenommen "
                    .. "(ID in Wowhead Classic nicht belegt). IDs 133, 2948, 2136 per Wowhead Classic belegt.",
            },
            [3] = {
                name = "Frost",
                dots = {},
                fillers = {
                    { 116, "Frostbolt" },
                    { 133, "Fireball" },
                    { 5143, "Arcane Missiles" },
                },
                sources = {
                    "forever: https://www.warcrafttavern.com/forever/guides/frost-mage/ (ohne Datum, Nov. 2026; Frostbolt Hauptzauber, Ice Lance bei Fingers of Frost, Missiles bei Missile Barrage)",
                    "forever: https://www.warcrafttavern.com/forever/guides/mage-leveling/ (Frost: Fireball bis 3, ab 4 Frostbolt, ab 20 Ice Lance)",
                },
                comparison = "Beide Quellen: Frostbolt Hauptzauber. Ice Lance und Arcane Missiles sind Procs (Fingers of Frost, Missile Barrage) und nicht "
                    .. "als Dauerzauber ins Makro genommen. ID 116 per Wowhead Classic belegt; Ice Lance (30455) dort nicht gelistet.",
            },
        },
    },
})
