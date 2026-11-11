-- Rotations.lua: Rueckfalltabelle fuer "Beste Rotation", fuer alle Klassen. Keine WoW-API, damit testbar.
-- Die Rassen spielen keine Rolle: welche Zauber gelten, liest der Aufrufer aus dem Zauberbuch des Charakters.
-- Eine Rotation besteht aus "dots" (Reihenfolge der Dauerschaden-Zauber / Aufbau) und
-- "fillers" (Fuellzauber: der erste bekannte wird am Ende wiederholt). Zauber-IDs sind
-- Grundraenge; welche davon das Spiel kennt, entscheidet der Aufrufer (Level, Talente, Spezialisierung).
local ADDON, ns = ...

-- Wie oft der Fuellzauber am Ende der Sequenz steht (eine Sequenz springt nach dem letzten Eintrag zum ersten zurueck)
ns.FILLER_REPEAT = 3

ns.ROTATIONS = {
    WARLOCK = {
        dots = {
            980,    -- Fluch der Pein / Agonie
            172,    -- Verderbnis
            316099, -- Instabiles Gebrechen (Retail)
            30108,  -- Instabiles Gebrechen (Classic)
            63106,  -- Seelenfeuer-Aussaugen / Lebensentzug (Retail)
            18265,  -- Lebensentzug (Classic)
            348,    -- Feuerbrand
        },
        fillers = {
            686,   -- Schattenblitz
            29722, -- Verbrennen
        },
    },

    MAGE = {
        dots = { 2948 }, -- Verbrennen (Scorch)
        fillers = { 30451, 133, 116, 5143 }, -- Arkanschlag, Feuerball, Frostblitz, Arkane Geschosse
    },
    PRIEST = {
        dots = { 589, 34914, 2944, 8092 }, -- Schattenwort: Schmerz, Vampirberuehrung, Verschlingende Seuche, Gedankenschlag
        fillers = { 15407, 585 }, -- Gedankenschinden, Zuechtigen
    },
    HUNTER = {
        dots = { 1130, 1978 }, -- Mal des Jaegers, Stich der Schlange
        fillers = { 56641, 3044 }, -- Zuverlaessiger Schuss, Arkaner Schuss
    },
    DRUID = {
        dots = { 8921, 5570, 1822, 1079 }, -- Mondfeuer, Insektenschwarm, Krallenhieb, Zerfleischen
        fillers = { 5221, 2912, 5176 }, -- Zerfetzen, Sternenfeuer, Zorn
    },
    ROGUE = {
        dots = { 5171, 1943 }, -- Zerhaecksel, Blutung
        fillers = { 1752, 53 }, -- Fieser Trick, Meucheln
    },
    WARRIOR = {
        dots = { 772 }, -- Ruptur (Rend)
        fillers = { 12294, 23881, 78 }, -- Toedlicher Stoss, Blutdurst, Heldenhafter Stoss
    },
    PALADIN = {
        dots = { 20271 }, -- Richturteil
        fillers = { 35395, 879 }, -- Kreuzfahrerstoss, Exorzismus
    },
    SHAMAN = {
        dots = { 8050 }, -- Flammenschock
        fillers = { 51505, 17364, 403 }, -- Lavaeruption, Sturmschlag, Blitzschlag
    },
    DEATHKNIGHT = {
        dots = { 45477, 45462 }, -- Eisige Beruehrung, Seuchenstoss
        fillers = { 49020, 49143, 47541 }, -- Vernichten, Frostschlag, Todesmantel
    },
    MONK = {
        dots = { 116095 }, -- Behinderung (Disable)
        fillers = { 113656, 107428, 100784, 100780 }, -- Furor der Fauste, Aufsteigender Sonnentritt, Schwarzer Tritt, Tigerklaue
    },
    DEMONHUNTER = {
        dots = { 258920 }, -- Feuerbrandaura (Immolation Aura)
        fillers = { 228477, 162794, 263642, 203782, 162243 }, -- Seelenspalter, Chaosschlag, Bruch, Scherung, Daemonenbiss
    },
    EVOKER = {
        dots = { 357208 }, -- Feueratem
        fillers = { 356995, 361469, 362969 }, -- Zersetzen, Lebendiges Feuer, Azurblauer Schlag
    },
}

-- Liefert eine Liste von Zauber-IDs (in Reihenfolge) oder nil, "keine Rotation fuer diese Klasse".
-- isKnown(id) -> true, wenn der Charakter den Zauber aktuell hat.
function ns.PickRotation(classToken, isKnown)
    local rot = ns.ROTATIONS[classToken]
    if not rot then return nil end
    local ids, seenName = {}, {}
    for _, id in ipairs(rot.dots) do
        if isKnown(id) then ids[#ids + 1] = id end
    end
    local filler
    for _, id in ipairs(rot.fillers) do
        if isKnown(id) then filler = id; break end
    end
    if filler then
        for _ = 1, ns.FILLER_REPEAT do ids[#ids + 1] = filler end
    end
    if #ids == 0 then return {} end
    return ids
end
