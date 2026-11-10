-- Rotations.lua: Vorschlaege fuer Rotationen je Klasse. Keine WoW-API, damit testbar.
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
