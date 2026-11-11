-- Rotations/Warrior.lua – Rotation fuer Krieger (WARRIOR), Rueckfall fuer "Beste Rotation".
--
-- STATUS: unverified
--   unverified      = recherchiert, aber weder im Spiel noch gegen den Dump der Rotationshilfe geprueft
--   helper-matched  = deckt sich mit dem Dump der Blizzard-Rotationshilfe ("/mw rotation", siehe unten)
--   game-verified   = vom Nutzer im Spiel geprueft
--
-- WIE DIE ROTATION ENTSTEHT
--   1. Erste Quelle im Addon ist die Rotationshilfe des Spiels (C_AssistedCombat.GetRotationSpells), siehe Core.lua.
--   2. Diese Datei ist der Rueckfall, falls die Hilfe nichts liefert. "dots" = Aufbau/Dauerschaden in dieser
--      Reihenfolge, "fillers" = Fuellzauber (der erste bekannte wird ns.FILLER_REPEAT-mal ans Ende gesetzt).
--   3. Welche Zauber der Charakter kennt, entscheidet das Spiel (Level, Talente, Spezialisierung).
--   4. Nachvollziehen/Erneuern: "/mw rotation" auf einem Charakter dieser Klasse ausfuehren; der Dump landet in
--      SavedVariables/rp-macro-writer.lua unter rotationDump.
--
-- QUELLEN UND VERGLEICH
--   Retail (12.1.5, Arms): Method.gg Arms Playstyle and Rotation, Stand 25.10.2026
--     https://www.method.gg/guides/arms-warrior/playstyle-and-rotation
--     Einzelziel: Rend, Avatar, Colossus Smash, Execute (2x Sudden Death), Heroic Strike (Apex), Mortal Strike,
--     Execute (1x), Overpower, Slam. Icy Veins (12.0/12.1.5) war per Abruf nicht lesbar (403); Suchtreffer
--     bestaetigen nur Rend -> Mortal Strike -> Execute -> Overpower -> Slam (Method 12.0.1).
--     Entscheidung: nur Rend als Aufbau, Mortal Strike/Overpower/Slam als Fueller; Cooldowns (Avatar,
--     Colossus Smash) und Execute (nur im Execute-Bereich) bleiben draussen (Makrolaenge, Zustandsabhaengigkeit).
--   Forever (Classic-Basis, Beta bis Stufe 30): Warcraft Tavern Warrior Leveling (WoW Forever), ohne Patchangabe
--     https://www.warcrafttavern.com/forever/guides/warrior-leveling/
--     Arms/Fury: Battle Shout, Charge, Overpower, Rend, Heroic Strike (Slam nur mit Improved Slam).
--     Icy Veins Classic/Forever-Seiten waren nicht lesbar (403); nur eine Quelle gelesen, Mindestmass (2) offen.
--   IDs per Wowhead belegt: Rend 772, Mortal Strike 12294, Overpower 7384, Slam 1464, Heroic Strike 78 (classic).
--   Rotationshilfe-Dump fuer WARRIOR liegt nicht vor -> Abgleich offen.
--
-- AENDERUNGSVERLAUF
--   2026-11-11  Ausgangsstand aus der Sammeltabelle uebernommen (unverified).
--   2026-11-11  Neu recherchiert: Varianten retail und classic, Quellen und Vergleich eingetragen (unverified).
--   2026-11-11  classic: trees (Arms/Fury/Protection) aus je zwei Forever-Quellen; keine Stufenbaender (Quellen nennen keine stufenabhaengige Aenderung). Unverified.
--   IDs Classic (Wowhead): Bloodthirst 23881, Whirlwind 1680, Shield Slam 23922, Revenge 6572, Thunder Clap 6343, Sunder Armor 7386, Execute 5308 (Rang 1 ungeprueft).
local ADDON, ns = ...

ns.RegisterRotation("WARRIOR", {
    status = "unverified",
    updated = "2026-11-11",
    source = "Method.gg Arms 12.1.5 (25.10.2026, retail); Warcraft Tavern Forever Leveling (classic)",
    comparison = "Retail: Method-Prioritaet gekuerzt auf Rend + Fueller, Cooldowns/Execute weggelassen. Classic: nur eine Quelle, Rotationshilfe-Dump fehlt.",
    dots = {
        { 772, "Rend" },
    },
    fillers = {
        { 12294, "Mortal Strike" },
        { 7384, "Overpower" },
        { 1464, "Slam" },
    },
    retail = {
        dots = {
            { 772, "Rend" },
        },
        fillers = {
            { 12294, "Mortal Strike" },
            { 7384, "Overpower" },
            { 1464, "Slam" },
        },
    },
    classic = {
        dots = {
            { 772, "Rend" },
        },
        fillers = {
            { 7384, "Overpower" },
            { 78, "Heroic Strike" },
        },
        -- Reihenfolge der Baeume: Arms, Fury, Protection (Warcraft Tavern nennt die Talentrechner-Bilder als
        -- 26/0/0, 0/26/0, 0/0/26; Standardreihenfolge der Krieger-Registerkarten, im Spiel ungeprueft).
        trees = {
            [1] = {
                name = "Arms",
                dots = { { 772, "Rend" } },
                fillers = { { 7384, "Overpower" }, { 12294, "Mortal Strike" }, { 1464, "Slam" } },
                sources = "Warcraft Tavern Forever Arms https://www.warcrafttavern.com/forever/guides/arms-warrior/ (ohne Patchangabe, Beta/Stufe 30); wowtbc.gg Forever Arms https://wowtbc.gg/warcraftforever/class-guides/arms-warrior/ (ohne Patchangabe)",
                comparison = "Beide: Overpower, Rend, Mortal Strike, Slam (Spearing Strike nur gegen Riesen/Drachkin, ausgelassen; Execute nur unter 20%, Zustandsabhaengig, ausgelassen). Heroic Strike/Sunder/Battle Shout ausgelassen (Rage-Dump bzw. Makrolaenge). Overpower braucht Kampfhaltung, Mortal Strike/Slam sind Filler; unbekannte Zauber filtert das Addon.",
            },
            [2] = {
                name = "Fury",
                dots = {},
                fillers = { { 23881, "Bloodthirst" }, { 1680, "Whirlwind" }, { 78, "Heroic Strike" } },
                sources = "Warcraft Tavern Forever Fury https://www.warcrafttavern.com/forever/guides/fury-warrior/ (ohne Patchangabe); wowtbc.gg Forever Fury https://wowtbc.gg/warcraftforever/class-guides/fury-warrior/ (ohne Patchangabe)",
                comparison = "Beide: Bloodthirst vor Whirlwind. Execute (unter 20%) ausgelassen. Rend nur kleiner Zugewinn und braucht Kampfhaltung -> kein Aufbau. Leveling-Guide Tavern nennt fuer Fury dagegen Overpower/Rend/Heroic Strike (niedrige Stufen, Bloodthirst erst spaeter); Bekannt-Filter deckt das ab, Bloodthirst-ID (Classic) per Wowhead belegt, Stufe nicht.",
            },
            [3] = {
                name = "Protection",
                dots = { { 6343, "Thunder Clap" }, { 7386, "Sunder Armor" } },
                fillers = { { 23922, "Shield Slam" }, { 6572, "Revenge" }, { 78, "Heroic Strike" } },
                sources = "Warcraft Tavern Forever Protection https://www.warcrafttavern.com/forever/guides/protection-warrior/ (ohne Patchangabe); wowtbc.gg Forever Protection https://wowtbc.gg/warcraftforever/class-guides/protection-warrior/ (ohne Patchangabe)",
                comparison = "Beide: Thunder Clap und Sunder Armor halten, dann Shield Slam, Revenge, Heroic Strike mit Rest-Rage. Rend/Demoralizing Shout/Battle Shout ausgelassen (Haltung, Makrolaenge). Leveling-Guide stellt Revenge vor Rend; Revenge/Shield Slam sind reaktiv bzw. talentabhaengig.",
            },
        },
    },
})
