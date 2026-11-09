-- Generator.lua: baut aus Schritten + Optionen den Makrotext.
-- Bewusst ohne WoW-API, damit die Logik ausserhalb des Spiels testbar ist.
local ADDON, ns = ...
ns = ns or {}

ns.MAX_MACRO_LEN = 255
ns.MAX_NAME_LEN = 16
ns.MAX_STEPS = 10

-- Kennung als letzte Zeile jedes erzeugten Makros. WoW ignoriert Zeilen, die mit "#" beginnen
-- (ausser #show/#showtooltip), das Add-on erkennt daran seine eigenen Makros wieder.
ns.MARKER = "#rpmw"

function ns.IsOurMacro(body)
    if type(body) ~= "string" then return false end
    for line in body:gmatch("[^\r\n]+") do
        if line == ns.MARKER then return true end
    end
    return false
end

function ns.NewOpts()
    return {
        mode = "auto",          -- auto | modifier | lines | random
        resetTarget = true,     -- /castsequence reset=target
        resetCombat = true,     -- /castsequence reset=combat
        resetSeconds = 0,       -- /castsequence reset=<n>
        target = "target",      -- target | mouseover | focus
        hostility = "harm",     -- harm (Feind) | help (Freund) | any
        life = "alive",         -- alive (nodead) | dead | any
        showTooltip = true,
        petAttack = false,
        autoTarget = false,
        noChannel = false,
        focusMouseover = false, -- /focus auf die Einheit unter der Maus setzen
        startAttack = false,    -- /startattack am Ende
        perChar = false,        -- false = Makro gilt fuer alle Charaktere (Account)
    }
end

-- Bedingungsblock, z.B. "[mod:shift,@mouseover,harm,nodead][mod:shift] "
local function Conditions(opts, mod)
    -- Bedingungen, die fuer jedes Ziel gelten: Feind/Freund, lebt/tot, nicht kanalisierend
    local base = {}
    if opts.hostility == "harm" then
        base[#base + 1] = "harm"
    elseif opts.hostility == "help" then
        base[#base + 1] = "help"
    end
    if opts.life == "alive" then
        base[#base + 1] = "nodead"
    elseif opts.life == "dead" then
        base[#base + 1] = "dead"
    end
    if opts.noChannel then base[#base + 1] = "nochanneling" end

    -- Erst Mouseover/Fokus pruefen, dann als Rueckfall das aktuelle Ziel
    local units = {}
    if opts.target == "mouseover" then
        units[#units + 1] = "@mouseover"
    elseif opts.target == "focus" then
        units[#units + 1] = "@focus"
    end
    units[#units + 1] = ""

    local out = ""
    local anyContent = false
    for _, unit in ipairs(units) do
        local parts = {}
        if mod and mod ~= "" then parts[#parts + 1] = "mod:" .. mod end
        if unit ~= "" then
            parts[#parts + 1] = unit
            -- [@mouseover] allein ist immer wahr; harm/help pruefen die Existenz bereits mit
            if opts.hostility ~= "harm" and opts.hostility ~= "help" then
                parts[#parts + 1] = "exists"
            end
        end
        for _, p in ipairs(base) do parts[#parts + 1] = p end
        if #parts > 0 then anyContent = true end
        out = out .. "[" .. table.concat(parts, ",") .. "]"
    end
    if not anyContent then return "" end
    return out .. " "
end

-- Wie Conditions, aber mit abweichenden Einstellungen (z.B. anderes Ziel, ohne nochanneling)
local function ConditionsWith(opts, overrides)
    local copy = {}
    for k, v in pairs(opts) do copy[k] = v end
    for k, v in pairs(overrides) do copy[k] = v end
    return Conditions(copy)
end

-- Bedingung nur fuer die Einheit unter der Maus, z.B. "[@mouseover,harm,nodead]"
local function MouseoverOnly(opts)
    local both = ConditionsWith(opts, { target = "mouseover", noChannel = false })
    return both:match("^(%b[])")
end

-- Automatik: ein Zauber = einfacher Cast, mehrere = Cast-Sequenz
function ns.DetectKind(steps)
    if #steps <= 1 then return "cast" end
    return "sequence"
end

local function Names(steps)
    local names = {}
    for i, step in ipairs(steps) do names[i] = step.name end
    return table.concat(names, ", ")
end

-- Liefert: Makrotext, Liste von Warnungen
function ns.BuildMacro(steps, opts)
    local lines, warnings = {}, {}
    if #steps == 0 then return "", warnings end

    if opts.showTooltip then lines[#lines + 1] = "#showtooltip" end
    if opts.focusMouseover then lines[#lines + 1] = "/focus " .. MouseoverOnly(opts) end
    if opts.autoTarget then lines[#lines + 1] = "/targetenemy [noharm][dead]" end
    if opts.petAttack then lines[#lines + 1] = "/petattack" end

    local mode = opts.mode
    if mode == "auto" and ns.DetectKind(steps) == "cast" then
        local step = steps[1]
        local cmd = (step.kind == "item") and "/use " or "/cast "
        lines[#lines + 1] = cmd .. Conditions(opts) .. step.name

    elseif mode == "auto" then
        local reset = {}
        if opts.resetTarget then reset[#reset + 1] = "target" end
        if opts.resetCombat then reset[#reset + 1] = "combat" end
        local secs = tonumber(opts.resetSeconds) or 0
        if secs > 0 then reset[#reset + 1] = tostring(secs) end
        local resetText = ""
        if #reset > 0 then resetText = "reset=" .. table.concat(reset, "/") .. " " end
        lines[#lines + 1] = "/castsequence " .. Conditions(opts) .. resetText .. Names(steps)

    elseif mode == "random" then
        lines[#lines + 1] = "/castrandom " .. Conditions(opts) .. Names(steps)

    elseif mode == "modifier" then
        local parts, seen, fallback = {}, {}, nil
        for _, step in ipairs(steps) do
            local mod = step.mod or ""
            if mod == "" then
                if fallback then
                    warnings[#warnings + 1] = step.name .. ": ohne Taste, wird ignoriert (nur ein Zauber ohne Taste möglich)."
                else
                    fallback = step
                end
            elseif seen[mod] then
                warnings[#warnings + 1] = step.name .. ": Taste doppelt belegt, wird ignoriert."
            else
                seen[mod] = true
                parts[#parts + 1] = Conditions(opts, mod) .. step.name
            end
        end
        if fallback then parts[#parts + 1] = Conditions(opts) .. fallback.name end
        lines[#lines + 1] = "/cast " .. table.concat(parts, "; ")

    else -- lines
        for _, step in ipairs(steps) do
            local cmd = (step.kind == "item") and "/use " or "/cast "
            lines[#lines + 1] = cmd .. Conditions(opts) .. step.name
        end
        if #steps > 1 then
            warnings[#warnings + 1] = "Hinweis: Pro Tastendruck löst WoW nur einen Zauber mit globaler Abklingzeit aus."
        end
    end

    if opts.startAttack then
        -- Angriff auf dasselbe Ziel wie die Zauber; bei "Freund" ohne Bedingung auf das aktuelle Ziel
        local cond = ""
        if opts.hostility ~= "help" then cond = ConditionsWith(opts, { noChannel = false }) end
        lines[#lines + 1] = (("/startattack " .. cond):gsub("%s+$", ""))
    end

    lines[#lines + 1] = ns.MARKER

    local body = table.concat(lines, "\n")
    if #body > ns.MAX_MACRO_LEN then
        warnings[#warnings + 1] = "Makro ist zu lang (" .. #body .. "/" .. ns.MAX_MACRO_LEN .. " Zeichen)."
    end
    return body, warnings
end

return ns
