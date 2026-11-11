-- Rotations/Shaman.lua – Rotation fuer Schamane (SHAMAN), Rueckfall fuer "Beste Rotation".
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
--   2026-11-11  classic: trees fuer Elemental, Enhancement, Restoration (leer) ergaenzt (unverified).
local ADDON, ns = ...

ns.RegisterRotation("SHAMAN", {
    status = "unverified",
    updated = "2026-11-11",
    source = "Method (Retail 12.1.5), Warcraft Tavern + wow.gg (Forever Beta); IDs/Namen per Wowhead belegt",
    dots = {
        { 8050, "Flame Shock" },
        { 17364, "Stormstrike" },
    },
    fillers = {
        { 8042, "Earth Shock" },
        { 403, "Lightning Bolt" },
    },
    retail = {
        sources = {
            { "https://www.method.gg/guides/enhancement-shaman/playstyle-and-rotation", "Retail 12.1.5, Stand 2026-10-13, Enhancement" },
            { "https://www.method.gg/guides/elemental-shaman/playstyle-and-rotation", "Retail 12.1.5, Stand 2026-10-14, Elemental" },
            { "https://icy-veins.com/wow/enhancement-shaman-pve-dps-rotation-cooldowns-abilities", "Retail 12.1.5, nur Suchausschnitt gelesen (Voltaic Blaze, Crash Lightning, Stormstrike, Lava Lash)" },
        },
        comparison = "Gewaehlt: Enhancement (Nahkampf-Prioritaet Method/Icy Veins): Voltaic Blaze, Crash Lightning, Stormstrike, Lava Lash, Filler Lightning Bolt "
            .. "(Method: ab 5 Maelstrom Weapon, bei 10 bevorzugt; Tempest/Primordial Storm ersetzen Lightning Bolt bei Hero-Talent, IDs nicht belegt, weggelassen). "
            .. "Elemental (Flame Shock/Voltaic Blaze, Lava Burst 51505, Elemental Blast 394116 nicht belegt, Lightning Bolt) wird nicht abgedeckt; ein Makro kann nur eine Spezialisierung bedienen. "
            .. "Voltaic Blaze ID 470057 nur ueber Wiki-Links (Wowhead-Seite nicht abgerufen). Cooldowns (Ascendance, Doom Winds) fehlen. Kein Dump der Rotationshilfe.",
        dots = {
            { 470057, "Voltaic Blaze" },
            { 187874, "Crash Lightning" },
            { 17364, "Stormstrike" },
            { 60103, "Lava Lash" },
        },
        fillers = {
            { 188196, "Lightning Bolt" },
        },
    },
    classic = {
        trees = {
            [1] = {
                name = "Elemental",
                dots = {
                    { 8050, "Flame Shock" },
                },
                fillers = {
                    { 403, "Lightning Bolt" },
                },
                sources = {
                    { "https://www.icy-veins.com/wow-forever/elemental-shaman-leveling", "WoW Forever, nur Suchausschnitt (Seite 403): Lightning Bolt Einzelziel, Flame Shock halten, Lava Burst ab Stufe 30, Chain Lightning/Fire Nova ab 3 Zielen" },
                    { "https://mobalytics.gg/wow-forever/classes/elemental-shaman-leveling-guide", "WoW Forever, nur Suchausschnitt (Seite 403): Flame Shock halten, Lava Burst auf Abklingzeit, Lightning Bolt als Filler" },
                    { "https://guildorder.com/games/wow_forever/tools/talents/shaman", "Forever-Talentrechner: Reihenfolge Elemental, Enhancement, Restoration (Listenreihenfolge, nicht ausdruecklich als Registerkarte bezeichnet)" },
                },
                comparison = "Beide Quellen: Flame Shock + Lightning Bolt. Lava Burst (ab 30 laut Icy Veins) weggelassen: Zauber-ID fuer Forever nicht belegt (Wowhead Classic spell=51505 liefert 404). "
                    .. "Chain Lightning (421, belegt) und Fire Nova sind Mehrzielzauber und fehlen. Keine Stufenbaender (Lava Burst-Aenderung ab 30 ohne belegte ID). Rotationshilfe-Dump fehlt.",
            },
            [2] = {
                name = "Enhancement",
                dots = {
                    { 8050, "Flame Shock" },
                    { 17364, "Stormstrike" },
                },
                fillers = {
                    { 8042, "Earth Shock" },
                    { 403, "Lightning Bolt" },
                },
                sources = {
                    { "https://www.warcrafttavern.com/forever/guides/enhancement-shaman/", "WoW Forever, Beta-Stufe 30, ohne Datum; Einzelziel: Flame Shock, Stormstrike, Lightning Bolt bei Maelstrom Weapon, Earth Shock Filler" },
                    { "https://wow.gg/guides/shaman-enhancement-forever-overview", "WoW Forever, Stand 2026-09-19, keine ausdrueckliche Prioritaet" },
                    { "https://guildorder.com/games/wow_forever/tools/talents/shaman", "Baumreihenfolge, siehe Elemental" },
                },
                comparison = "Unveraendert gegenueber der bisherigen classic-Rotation. Lightning Bolt bei Maelstrom Weapon nur sinnvoll mit Procs; als zweiter Filler nur Rueckfall, falls Earth Shock fehlt. Totems/Schilde/Waffen sind keine Makro-Ziele. Keine Stufenbaender belegt (Guide: Stufe-60-Stand ausstehend).",
            },
            [3] = {
                name = "Restoration",
                dots = {},
                fillers = {},
                sources = {
                    { "https://www.icy-veins.com/wow-forever/restoration-shaman-healer-pve-rotation-cooldowns-abilities", "WoW Forever, nur Titel aus Suche, Seite 403" },
                    { "https://guildorder.com/games/wow_forever/tools/talents/shaman", "Baumreihenfolge, siehe Elemental" },
                },
                comparison = "Heilerbaum: keine Schaden-Rotation eingetragen. Suchergebnisse nennen Earth Shock nur als Unterbrechung, empfehlen zum Leveln Enhancement/Elemental; keine Quelle belegt eine Resto-Schadensrotation. Rueckfall (Flame Shock, Stormstrike, Earth Shock) gilt.",
            },
        },
        sources = {
            { "https://www.warcrafttavern.com/forever/guides/enhancement-shaman/", "WoW Forever, Beta-Stufe 30, ohne Datum" },
            { "https://wow.gg/guides/shaman-enhancement-forever-overview", "WoW Forever, Stand 2026-09-19, keine explizite Prioritaet (abgeleitet)" },
            { "https://www.icy-veins.com/tbc-classic/enhancement-shaman-dps-pve-rotation-cooldowns-abilities", "TBC Classic (nur Vergleich, nicht Forever)" },
        },
        comparison = "Enhancement: Flame Shock halten, Stormstrike nach Abklingzeit, Earth Shock als Filler, Lightning Bolt bei Maelstrom Weapon (Forever) bzw. Pull. "
            .. "Warcraft Tavern: Earth Shock Filler; wow.gg: Earth Shock auf Stormstrike-Ziel. Quellen fuer Level 60 fehlen (Beta-Stand). "
            .. "Totems, Schilde, Waffenverzauberungen sind keine Makro-Ziele und fehlen. Elemental-Kern waere Lightning Bolt/Chain Lightning/Flame Shock. "
            .. "Ranghoechstes Zauber per Name; IDs 8050, 17364, 8042, 403 per Wowhead Classic belegt. Kein Dump der Rotationshilfe.",
        dots = {
            { 8050, "Flame Shock" },
            { 17364, "Stormstrike" },
        },
        fillers = {
            { 8042, "Earth Shock" },
            { 403, "Lightning Bolt" },
        },
    },
})
