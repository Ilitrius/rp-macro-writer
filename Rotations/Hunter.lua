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
--   2026-11-11  Classic: drei Talentbaeume (trees) fuer Forever recherchiert, unverified, kein Dump, keine Stufenbaender.
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
        -- Reihenfolge der Registerkarten: Beast Mastery, Marksmanship, Survival (Blizzard-Klassenvorschau Forever, ueber Wowhead gespiegelt).
        trees = {
            [1] = {
                name = "Beast Mastery",
                sources = {
                    { "https://www.warcrafttavern.com/forever/guides/beast-mastery-hunter/", "Forever (Beta), undatiert (Seite zeigt Hotfix-Eintrag 2026-11-10), Beast Mastery" },
                    { "https://www.warcrafttavern.com/forever/guides/hunter-leveling/", "Forever (Beta), undatiert, Beast Mastery: Serpent Sting, Arcane Shot, Aimed Shot (ab 20), Rapid Fire, Bestial Wrath" },
                    { "https://www.wowhead.com/forever/blue-tracker/news/us/world-of-warcraft-forever-class-deep-dives-hunter-and-druid-world-of-warcraft-24301515", "Forever Beta, Blizzard-Klassenvorschau: Reihenfolge der Baeume, Aimed Shot teilt Abklingzeit mit Multi-Shot, Summon Hawk mit Arcane Shot" },
                },
                comparison = "Tavern-Forever: Serpent Sting halten, Summon Hawk (Talent, 16 Punkte, teilt Abklingzeit mit Arcane Shot) und Aimed Shot, Arcane Shot erst bei zwei Falken; "
                    .. "Rapid Fire und Bestial Wrath nach Abklingzeit. Tavern-Leveling: Serpent Sting, Arcane Shot, Aimed Shot. Entscheidung: Hunter's Mark + Serpent Sting + Summon Hawk als Aufbau, "
                    .. "Aimed Shot dann Arcane Shot als Filler (Multi-Shot weggelassen, teilt Abklingzeit mit Aimed Shot). Cooldowns (Rapid Fire 3045, Bestial Wrath 19574) bewusst nicht aufgenommen. "
                    .. "IDs: Wowhead Classic/Forever 1130, 1978, 3044, 19434 (Rang 1); Summon Hawk 1293241 laut Wowhead-Forever-Suche (zweite Seite 1293526, welche Rang 1 ist, ungeprueft). Keine Stufenbaender: Quellen nennen keine Rotationsaenderung ab einer Stufe, der Bekannt-Filter erledigt es.",
                dots = {
                    { 1130, "Hunter's Mark" },
                    { 1978, "Serpent Sting" },
                    { 1293241, "Summon Hawk" },
                },
                fillers = {
                    { 19434, "Aimed Shot" },
                    { 3044, "Arcane Shot" },
                },
            },
            [2] = {
                name = "Marksmanship",
                sources = {
                    { "https://wowtbc.gg/warcraftforever/class-guides/marksmanship-hunter/", "Forever (Beta), undatiert, Marksmanship" },
                    { "https://warcrafttavern.com/wow-classic/guides/pve-marksmanship-hunter-rotations-cooldowns", "Classic (nicht Forever-spezifisch), undatiert: Multi-Shot, Serpent Sting, Aimed Shot" },
                    { "https://www.warcrafttavern.com/forever/guides/hunter-leveling/", "Forever (Beta), undatiert: Serpent Sting, Sniper Shot, Arcane Shot, Aimed Shot, Rapid Fire" },
                },
                comparison = "wowtbc-Forever: Hunter's Mark, Serpent Sting, Sniper Shot (neues Talent, 31 Punkte, 4 s Wirkzeit, 15 s Abklingzeit), Arcane Shot, Multi-Shot. "
                    .. "Tavern-Leveling: Serpent Sting, Sniper Shot, Arcane Shot, Aimed Shot. Classic-Tavern (anderer Stand): Aimed Shot vor Serpent Sting. Entscheidung: Hunter's Mark + Serpent Sting als Aufbau, "
                    .. "Sniper Shot, Aimed Shot, Arcane Shot als Filler (Sniper Shot nur mit Talent bekannt, sonst faellt der Bekannt-Filter auf Aimed Shot). Multi-Shot weggelassen (teilt Abklingzeit mit Aimed Shot). "
                    .. "Sniper Shot ID 1310687 (Wowhead Forever, Seite 'Is Ability'; 1310785 ist ein weiterer Eintrag, welcher Rang 1 ist, ungeprueft). Keine Stufenbaender belegt.",
                dots = {
                    { 1130, "Hunter's Mark" },
                    { 1978, "Serpent Sting" },
                },
                fillers = {
                    { 1310687, "Sniper Shot" },
                    { 19434, "Aimed Shot" },
                    { 3044, "Arcane Shot" },
                },
            },
            [3] = {
                name = "Survival",
                sources = {
                    { "https://www.warcrafttavern.com/forever/guides/survival-hunter/", "Forever (Beta), undatiert: Serpent Sting, Arcane Shot, Aimed Shot, Nahkampf-Einlagen" },
                    { "https://wowtbc.gg/warcraftforever/class-guides/survival-hunter/", "Forever (Beta), undatiert: Hunter's Mark, Serpent Sting, Arcane Shot, Multi-Shot" },
                    { "https://www.warcrafttavern.com/forever/guides/hunter-leveling/", "Forever (Beta), undatiert: Survival mit Nahkampf-Einlagen oder reiner Nahkampf" },
                },
                comparison = "Beide Forever-Quellen: Serpent Sting halten, Arcane Shot; Tavern setzt Aimed Shot davor, wowtbc Hunter's Mark und Multi-Shot. Nahkampf (Raptor Strike, Mongoose Bite, Strider Kick, "
                    .. "Immolation Trap) erfordert Positionswechsel und ist per Makro nicht sinnvoll, daher nicht aufgenommen (Strider Kick ID 1317257 laut Wowhead-URL, nicht verwendet). "
                    .. "Entscheidung: Hunter's Mark + Serpent Sting, Filler Aimed Shot dann Arcane Shot. Keine Stufenbaender belegt. Unsicher: Tavern-Seite nennt kein Hunter's Mark, wowtbc schon.",
                dots = {
                    { 1130, "Hunter's Mark" },
                    { 1978, "Serpent Sting" },
                },
                fillers = {
                    { 19434, "Aimed Shot" },
                    { 3044, "Arcane Shot" },
                },
            },
        },
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
