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
--   2026-11-11  Forever/Classic: Rotation je Talentbaum (trees 1-3), unverified, kein Dump.
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
        comparison = "Rueckfall ohne erkannten Baum: Slice and Dice, Sinister Strike/Backstab. Reihenfolge der Baeume (Assassination, Combat, Subtlety) laut https://wowtbc.gg/warcraftforever/class-guides/assassination-rogue/ (Talentbaum-Reihenfolge der Seite, kein Talentrechner).",
        dots = {
            { 5171, "Slice and Dice" },
        },
        fillers = {
            { 1752, "Sinister Strike" },
            { 53, "Backstab" },
        },
        trees = {
            [1] = {
                name = "Assassination",
                sources = {
                    "Forever (undatiert, 2026): https://www.warcrafttavern.com/forever/guides/assassination-rogue/",
                    "Forever (undatiert, 2026): https://wowtbc.gg/warcraftforever/class-guides/assassination-rogue/",
                },
                comparison = "Beide: Slice and Dice halten, Mutilate (neu in Forever) als Combopunkt-Aufbau; Warcraft Tavern: Sinister Strike nur bei 4 CP, wowtbc: Shank bei unter 70 Energie (nicht aufgenommen: Zauber-ID nur ueber warcraft.wiki.gg, 1329283/1329549, nicht ueber Wowhead belegt; 10 s Abklingzeit). Finisher Eviscerate/Venom/Expose Armor/Rupture weggelassen (Makro kennt keine Combopunkte). Mutilate-ID 1329 per Wowhead /classic/spell= belegt. Keine Stufenbaender: Quellen nennen nur Talent-Staffelung, keine Aenderung der Prioritaet.",
                dots = {
                    { 5171, "Slice and Dice" },
                },
                fillers = {
                    { 1329, "Mutilate" },
                    { 1752, "Sinister Strike" },
                },
            },
            [2] = {
                name = "Combat",
                sources = {
                    "Forever (undatiert, 2026): https://www.warcrafttavern.com/forever/guides/combat-rogue/",
                    "Forever (Suchtreffer, nicht lesbar): https://www.icy-veins.com/wow-forever/combat-rogue-melee-dps-pve-rotation-cooldowns-abilities",
                },
                comparison = "Warcraft Tavern: Slice and Dice hoechste Prioritaet, Blade Flurry auf Abklingzeit, Sinister Strike als Aufbau (Dolch-Build: Backstab). Adrenaline Rush nicht aufgenommen (Zauber-ID nicht belegt, Burst). Eviscerate/Expose Armor wegen Combopunkten weggelassen. Zweite Quelle nicht lesbar, daher faktisch eine Quelle. Keine Stufenbaender (Quelle: keine Stufenrotation).",
                dots = {
                    { 5171, "Slice and Dice" },
                    { 13877, "Blade Flurry" },
                },
                fillers = {
                    { 1752, "Sinister Strike" },
                    { 53, "Backstab" },
                },
            },
            [3] = {
                name = "Subtlety",
                sources = {
                    "Forever (undatiert, 2026): https://www.warcrafttavern.com/forever/guides/subtlety-rogue/",
                    "Forever (undatiert, 2026): https://wowtbc.gg/warcraftforever/class-guides/subtlety-rogue/",
                },
                comparison = "Warcraft Tavern: Ghostly Strike auf Abklingzeit, Hemorrhage als Aufbau (Bleed-Build) oder Backstab (Ambush-Build), Slice and Dice. wowtbc: Slice and Dice, Hemorrhage, Ghostly Strike. Gemeinsam: Hemorrhage als Fueller; Backstab als Rueckfall (braucht Position hinter dem Ziel und Dolch). Rupture/Death Mark/Garrote/Premeditation wegen Combopunkten bzw. Stealth weggelassen. IDs Ghostly Strike 14278, Hemorrhage 16511 per Wowhead belegt. Keine Stufenbaender (Quelle nennt nur Fruehstufen mit Sinister Strike, der Bekannt-Filter deckt das ab).",
                dots = {
                    { 5171, "Slice and Dice" },
                    { 14278, "Ghostly Strike" },
                },
                fillers = {
                    { 16511, "Hemorrhage" },
                    { 53, "Backstab" },
                    { 1752, "Sinister Strike" },
                },
            },
        },
    },
})
