-- Rotations/Monk.lua – Rotation fuer Mönch (MONK), Rueckfall fuer "Beste Rotation".
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
--   2026-11-11  Neu aufgebaut aus Quellen (Windwalker, Retail 12.1.5). Forever hat keinen Moench: nur retail-Variante (unverified, kein Dump vorhanden).
local ADDON, ns = ...

-- WoW Forever (Client 1.60.x) kennt keinen Moench (nur die 9 Classic-Klassen), daher keine classic-Variante.
ns.RegisterRotation("MONK", {
    status = "unverified",
    updated = "2026-11-11",
    source = "Method (Retail 12.1.5, Windwalker); IDs per Wowhead belegt; kein Moench in WoW Forever",
    dots = {
        { 392983, "Strike of the Windlord" },
        { 113656, "Fists of Fury" },
        { 107428, "Rising Sun Kick" },
    },
    fillers = {
        { 100780, "Tiger Palm" },
        { 100784, "Blackout Kick" },
    },
    retail = {
        sources = {
            { "https://www.method.gg/guides/windwalker-monk/playstyle-and-rotation", "Retail 12.1.5, Stand 2026-10-14, Windwalker (Conduit/Shado-Pan)" },
            { "https://www.icy-veins.com/wow/windwalker-monk-pve-dps-rotation-cooldowns-abilities", "Retail 12.1.5, nur Suchausschnitt (Seite gab 403), nicht ausgewertet" },
        },
        comparison = "Nur Method vollstaendig gelesen (zweite Quelle nicht abrufbar, Mindestzahl nicht erreicht). Method: Fists of Fury, Rushing Wind Kick, Rising Sun Kick, "
            .. "Blackout Kick mit Combo Breaker, Tiger Palm als Chi-Aufbau/Filler. Weggelassen: Whirling Dragon Punch, Zenith Stomp, Celestial Conduit, Rushing Wind Kick (IDs nicht belegt, Talente/Cooldowns). "
            .. "Belegt: 113656, 107428, 100784, 100780, 392983. Nur Windwalker. Kein Dump der Rotationshilfe.",
        dots = {
            { 392983, "Strike of the Windlord" },
            { 113656, "Fists of Fury" },
            { 107428, "Rising Sun Kick" },
        },
        fillers = {
            { 100780, "Tiger Palm" },
            { 100784, "Blackout Kick" },
        },
    },
})
