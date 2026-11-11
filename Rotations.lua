-- Rotations.lua: Mechanik der Rueckfall-Rotationen fuer "Beste Rotation" (alle Klassen). Keine WoW-API, damit testbar.
-- Die Daten stehen je Klasse in Rotations/<Klasse>.lua. Die Rassen spielen keine Rolle: welche Zauber gelten,
-- liest der Aufrufer aus dem Zauberbuch des Charakters.
-- Eine Rotation besteht aus "dots" (Reihenfolge der Dauerschaden-Zauber / Aufbau) und
-- "fillers" (Fuellzauber: der erste bekannte wird am Ende wiederholt). Zauber-IDs sind
-- Grundraenge; welche davon das Spiel kennt, entscheidet der Aufrufer (Level, Talente, Spezialisierung).
local ADDON, ns = ...

-- Wie oft der Fuellzauber am Ende der Sequenz steht (eine Sequenz springt nach dem letzten Eintrag zum ersten zurueck)
ns.FILLER_REPEAT = 3

ns.ROTATIONS = {}

-- Wird von den Dateien Rotations/<Klasse>.lua aufgerufen. data hat status/updated/source und Varianten je Spielversion:
--   dots / fillers      = Standard fuer alle Versionen (Listen { zauberID, "Name" })
--   retail = { dots, fillers, sources, comparison }   nur Retail (Midnight/12.x)
--   classic = { dots, fillers, sources, comparison }  Forever und die Classic-Versionen
-- sources = Liste der ausgewerteten Quellen (URL + Stand), comparison = Begruendung der Wahl (nachvollziehbar).
local function Variant(v)
    local out = { dots = {}, fillers = {}, dotEntries = v.dots or {}, fillerEntries = v.fillers or {},
        sources = v.sources, comparison = v.comparison, name = v.name, minLevel = v.minLevel }
    for _, e in ipairs(out.dotEntries) do out.dots[#out.dots + 1] = e[1] end
    for _, e in ipairs(out.fillerEntries) do out.fillers[#out.fillers + 1] = e[1] end
    -- Forever/Classic: je Talentbaum (1, 2, 3 in der Reihenfolge des Spiels) eine eigene Rotation, darin optional
    -- Stufenbaender (bands = { { minLevel = 20, dots, fillers }, ... }): es gilt das Band mit dem hoechsten minLevel <= Level.
    if v.trees then
        out.trees = {}
        for index, tv in pairs(v.trees) do out.trees[index] = Variant(tv) end
    end
    if v.bands then
        out.bands = {}
        for _, bv in ipairs(v.bands) do out.bands[#out.bands + 1] = Variant(bv) end
        table.sort(out.bands, function(a, b) return (a.minLevel or 0) < (b.minLevel or 0) end)
    end
    return out
end

function ns.RegisterRotation(classToken, data)
    local rot = { status = data.status, updated = data.updated, source = data.source, variants = {} }
    if data.dots or data.fillers then rot.variants.default = Variant(data) end
    if data.retail then rot.variants.retail = Variant(data.retail) end
    if data.classic then rot.variants.classic = Variant(data.classic) end
    ns.ROTATIONS[classToken] = rot
end

-- Liefert eine Liste von Zauber-IDs (in Reihenfolge) oder nil = "keine Rotation fuer diese Klasse".
-- isKnown(id) -> true, wenn der Charakter den Zauber aktuell hat.
-- flavor = "retail" oder "classic" (Forever, Classic-Versionen); ohne passende Variante gilt der Standard.
-- tree (nur classic) = Talentbaum 1..3, level = Charakterstufe: waehlt die Rotation des Baums und dessen Stufenband.
local function Usable(v) return v and (#v.dots + #v.fillers) > 0 end

function ns.PickRotation(classToken, isKnown, flavor, tree, level)
    local rot = ns.ROTATIONS[classToken]
    if not rot then return nil end
    local v = rot.variants[flavor or "default"] or rot.variants.default
    if not v then return nil end
    if tree and v.trees and Usable(v.trees[tree]) then
        local tv = v.trees[tree]
        if level and tv.bands then
            for i = #tv.bands, 1, -1 do
                if (tv.bands[i].minLevel or 0) <= level and Usable(tv.bands[i]) then tv = tv.bands[i]; break end
            end
        end
        v = tv
    elseif level and v.bands then
        for i = #v.bands, 1, -1 do
            if (v.bands[i].minLevel or 0) <= level and Usable(v.bands[i]) then v = v.bands[i]; break end
        end
    end
    local ids = {}
    for _, id in ipairs(v.dots) do
        if isKnown(id) then ids[#ids + 1] = id end
    end
    local filler
    for _, id in ipairs(v.fillers) do
        if isKnown(id) then filler = id; break end
    end
    if filler then
        for _ = 1, ns.FILLER_REPEAT do ids[#ids + 1] = filler end
    end
    return ids
end
