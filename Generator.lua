-- Generator.lua: baut aus Schritten + Optionen den Makrotext.
-- Bewusst ohne WoW-API, damit die Logik ausserhalb des Spiels testbar ist.
local ADDON, ns = ...
-- Sprache: ohne Locales.lua (Tests) bleibt es beim deutschen Text
local L = ns.L or setmetatable({}, { __index = function(_, k) return k end })
ns = ns or {}

ns.MAX_MACRO_LEN = 255
ns.MAX_NAME_LEN = 16
ns.MAX_STEPS = 10

-- Kennung als letzte Zeile jedes erzeugten Makros. WoW ignoriert Zeilen, die mit "#" beginnen
-- (ausser #show/#showtooltip), das Add-on erkennt daran seine eigenen Makros wieder.
ns.MARKER = "#rpmw"

-- Kuerzt einen Makrotext ohne Wirkungsaenderung: Leerzeichen nach Komma/Semikolon in den
-- Zauberlisten weglassen (nur Zeilen mit /cast, /castsequence, /castrandom, /use).
function ns.Compact(body)
    local lines = {}
    for line in (body .. "\n"):gmatch("(.-)\n") do
        if line:match("^/cast") or line:match("^/use") then
            local head, rest = line:match("^(/%S+ ?%b[]%s*)(.*)$")
            if not head then head, rest = line:match("^(/%S+%s*)(.*)$") end
            -- Bedingungen "][" und "] " bleiben; nur in der Zauberliste kuerzen
            line = head .. rest:gsub(",%s+", ","):gsub(";%s+", ";")
        end
        lines[#lines + 1] = line
    end
    if lines[#lines] == "" then lines[#lines] = nil end
    return table.concat(lines, "\n")
end

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
        focusMouseover = false, -- /focus auf die Einheit unter der Maus setzen (sonst auf das Ziel)
        targetFocus = false,    -- /target focus: den Fokus anvisieren, Zauber gehen aufs Ziel
        targetTarget = false,   -- Rueckfall auf das Ziel des Ziels, sonst Zauber trotzdem aufs Ziel
        fallbackTarget = false, -- bei Mouseover/Fokus als Rueckfall das aktuelle Ziel pruefen ("[@focus,harm][harm]")
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
    if opts.target == "target" or opts.fallbackTarget then units[#units + 1] = "" end
    if opts.targetTarget then
        units[#units + 1] = "@targettarget"
        units[#units + 1] = "CATCHALL" -- immer wahr: Zauber geht im Zweifel aufs Ziel
    end

    local out = ""
    local anyContent = false
    for _, unit in ipairs(units) do
        local parts = {}
        if mod and mod ~= "" then parts[#parts + 1] = "mod:" .. mod end
        if unit == "CATCHALL" then
            parts[#parts + 1] = "@target"
        else
            if unit ~= "" then
                parts[#parts + 1] = unit
                -- [@mouseover] allein ist immer wahr; harm/help pruefen die Existenz bereits mit
                if opts.hostility ~= "harm" and opts.hostility ~= "help" then
                    parts[#parts + 1] = "exists"
                end
            end
            for _, p in ipairs(base) do parts[#parts + 1] = p end
            -- Kette mit Ziel des Ziels: jede Klammer prueft zusaetzlich "exists" (so laeuft die Vorlage des Nutzers im Spiel)
            if opts.targetTarget and (opts.hostility ~= "any" or opts.life ~= "any") then
                local has = false
                for _, p in ipairs(parts) do if p == "exists" then has = true end end
                if not has then parts[#parts + 1] = "exists" end
            end
        end
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
    local both = ConditionsWith(opts, { target = "mouseover", noChannel = false, targetTarget = false })
    return both:match("^(%b[])")
end

-- ---------------------------------------------------------------------------
-- Syntaxfarben fuer den Makrotext (reine Textfunktion, ohne WoW-API)
-- ---------------------------------------------------------------------------
local COLOR = {
    command = "ffffa040", -- /cast, /focus, ...
    comment = "ff808080", -- #rpmw und andere Kommentarzeilen
    show    = "ffffd100", -- #show, #showtooltip
    unit    = "ff66ccff", -- @mouseover, @focus, ...
    cond    = "ff7fe07f", -- harm, nodead, mod:shift, ...
    reset   = "ffd19bff", -- reset=target/combat
}

local function Paint(color, s)
    if s == "" then return "" end
    return "|c" .. color .. s:gsub("|", "||") .. "|r"
end

local function Plain(s)
    s = s:gsub("|", "||")
    return (s:gsub("reset=%S+", function(r) return "|c" .. COLOR.reset .. r .. "|r" end))
end

local function Bracket(inner)
    local parts = {}
    for token in (inner .. ","):gmatch("([^,]*),") do
        if token:sub(1, 1) == "@" then
            parts[#parts + 1] = Paint(COLOR.unit, token)
        else
            parts[#parts + 1] = Paint(COLOR.cond, token)
        end
    end
    return table.concat(parts, ",")
end

local function HighlightLine(line)
    if line:sub(1, 1) == "#" then
        return Paint(line:match("^#show") and COLOR.show or COLOR.comment, line)
    end
    local cmd, rest = line:match("^(/%S+)(.*)$")
    if not cmd then return Plain(line) end
    local out, pos = { Paint(COLOR.command, cmd) }, 1
    while true do
        local open = rest:find("[", pos, true)
        local close = open and rest:find("]", open, true)
        if not close then break end
        out[#out + 1] = Plain(rest:sub(pos, open - 1))
        out[#out + 1] = "[" .. Bracket(rest:sub(open + 1, close - 1)) .. "]"
        pos = close + 1
    end
    out[#out + 1] = Plain(rest:sub(pos))
    return table.concat(out)
end

-- Faerbt Makrotext mit |c..|r-Codes ein; ohne die Codes ist das Ergebnis der Originaltext
function ns.Highlight(text)
    text = tostring(text or "")
    local out, pos = {}, 1
    while true do
        local nl = text:find("\n", pos, true)
        if not nl then
            out[#out + 1] = HighlightLine(text:sub(pos))
            break
        end
        out[#out + 1] = HighlightLine(text:sub(pos, nl - 1))
        pos = nl + 1
    end
    return table.concat(out, "\n")
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

-- Zeichen, die im Namen den Makrotext durcheinanderbringen wuerden:
--   Zeilenumbruch und [ ] immer, "," in Sequenz/Zufall, ";" und "," im Modus Zusatztaste
function ns.NameProblem(name, mode)
    name = tostring(name or "")
    if name:find("[\r\n%[%]]") then return true end
    if mode == "sequence" or mode == "random" then return name:find(",", 1, true) ~= nil end
    if mode == "modifier" then return name:find("[,;]") ~= nil end
    return false
end

-- Liefert: Makrotext, Liste von Warnungen
function ns.BuildMacro(steps, opts)
    local lines, warnings = {}, {}
    if #steps == 0 then return "", warnings end

    if opts.showTooltip then lines[#lines + 1] = "#showtooltip" end
    -- Fokus: Einheit unter der Maus, sonst (leere Bedingung) das aktuelle Ziel
    if opts.focusMouseover then lines[#lines + 1] = "/focus " .. MouseoverOnly(opts) .. "[]" end
    if opts.targetFocus then lines[#lines + 1] = "/target focus" end
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
                    warnings[#warnings + 1] = step.name .. L[": ohne Taste, wird ignoriert (nur ein Zauber ohne Taste möglich)."]
                else
                    fallback = step
                end
            elseif seen[mod] then
                warnings[#warnings + 1] = step.name .. L[": Taste doppelt belegt, wird ignoriert."]
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
            warnings[#warnings + 1] = L["Hinweis: Pro Tastendruck löst WoW nur einen Zauber mit globaler Abklingzeit aus."]
        end
    end

    -- Namen mit Sonderzeichen melden (die Syntax kann dann brechen)
    local kindForNames = opts.mode
    if kindForNames == "auto" then
        kindForNames = (ns.DetectKind(steps) == "sequence") and "sequence" or "cast"
    end
    for _, step in ipairs(steps) do
        if ns.NameProblem(step.name, kindForNames) then
            warnings[#warnings + 1] = step.name .. L[": enthält Sonderzeichen, das Makro funktioniert evtl. nicht."]
        end
    end

    if opts.startAttack then
        -- Angriff auf dasselbe Ziel wie die Zauber; bei "Freund" ohne Bedingung auf das aktuelle Ziel
        local cond = ""
        if opts.hostility ~= "help" then cond = ConditionsWith(opts, { noChannel = false, targetTarget = false }) end
        lines[#lines + 1] = (("/startattack " .. cond):gsub("%s+$", ""))
    end

    lines[#lines + 1] = ns.MARKER

    local body = table.concat(lines, "\n")
    if #body > ns.MAX_MACRO_LEN then body = ns.Compact(body) end -- erst kuerzen, dann erst warnen
    if #body > ns.MAX_MACRO_LEN then body = body:gsub("\n/target ", "\n/tar ") end -- /tar ist die Kurzform von /target
    if #body > ns.MAX_MACRO_LEN then
        warnings[#warnings + 1] = L["Makro ist zu lang ("] .. #body .. "/" .. ns.MAX_MACRO_LEN .. L[" Zeichen). Bitte Zauber oder Optionen entfernen."]
    end
    return body, warnings
end

return ns
