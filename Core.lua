-- Core.lua: Zustand, gespeicherte Daten, Drag & Drop-Annahme, Makro schreiben.
local ADDON, ns = ...

local PREFIX = "|cff9482c9rp-macro-writer|r: "
local QUESTION_MARK_ICON = 134400 -- Fragezeichen: WoW zeigt dann automatisch das Symbol des Zaubers

function ns.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. msg)
end

local function Trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- ---------------------------------------------------------------------------
-- Kompatibilitaet: Retail (C_Spell/C_Item) und Classic-Varianten (globale API)
-- ---------------------------------------------------------------------------
local function SpellName(id)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
    if GetSpellInfo then return (GetSpellInfo(id)) end
end

local function SpellIcon(id)
    if C_Spell and C_Spell.GetSpellTexture then return (C_Spell.GetSpellTexture(id)) end
    if GetSpellTexture then return (GetSpellTexture(id)) end
end

local function ItemName(id)
    if C_Item and C_Item.GetItemInfo then return (C_Item.GetItemInfo(id)) end
    if GetItemInfo then return (GetItemInfo(id)) end
end

local function ItemIcon(id)
    if C_Item and C_Item.GetItemIconByID then return C_Item.GetItemIconByID(id) end
    if GetItemIcon then return GetItemIcon(id) end
end

-- ---------------------------------------------------------------------------
-- Zustand
-- ---------------------------------------------------------------------------
local function CopySteps(steps)
    local out = {}
    for i, s in ipairs(steps or {}) do
        out[i] = { kind = s.kind, id = s.id, name = s.name, icon = s.icon, mod = s.mod }
    end
    return out
end

local function CopyOpts(opts)
    local out = ns.NewOpts()
    for k in pairs(out) do
        if opts and opts[k] ~= nil then out[k] = opts[k] end
    end
    return out
end

local function InitDB()
    RPMacroWriterDB = RPMacroWriterDB or {}
    local db = RPMacroWriterDB
    db.saved = db.saved or {}
    db.current = db.current or {}
    db.current.name = db.current.name or ""
    db.current.steps = CopySteps(db.current.steps)
    db.current.opts = CopyOpts(db.current.opts)
    ns.db = db
    ns.state = db.current
end

-- ---------------------------------------------------------------------------
-- Drag & Drop: was am Mauszeiger haengt, als Schritt uebernehmen
-- ---------------------------------------------------------------------------
local function StepFromCursor()
    local kind, a, b, c = GetCursorInfo()
    if kind == "spell" then
        local id = c
        if not id and GetSpellBookItemInfo then
            local _, bookId = GetSpellBookItemInfo(a, b)
            id = bookId
        end
        local name = id and SpellName(id)
        if name then return { kind = "spell", id = id, name = name, icon = SpellIcon(id) } end
    elseif kind == "petaction" then
        local name = a and SpellName(a)
        if name then return { kind = "spell", id = a, name = name, icon = SpellIcon(a) } end
    elseif kind == "item" then
        local name = a and ItemName(a)
        if name then return { kind = "item", id = a, name = name, icon = ItemIcon(a) } end
    elseif kind then
        return nil, "Das kann nicht in ein Makro übernommen werden (nur Zauber, Begleiterfähigkeiten und Gegenstände)."
    end
    return nil, kind and "Name konnte nicht ermittelt werden." or nil
end

function ns.TryDrop()
    local step, err = StepFromCursor()
    if not step then
        if err then ns.Print(err) end
        return
    end
    ClearCursor()
    if #ns.state.steps >= ns.MAX_STEPS then
        ns.Print("Maximal " .. ns.MAX_STEPS .. " Zauber pro Makro.")
        return
    end
    table.insert(ns.state.steps, step)
    ns.Refresh()
end

function ns.MoveStep(index, delta)
    local steps = ns.state.steps
    local target = index + delta
    if target < 1 or target > #steps then return end
    steps[index], steps[target] = steps[target], steps[index]
    ns.Refresh()
end

function ns.RemoveStep(index)
    table.remove(ns.state.steps, index)
    ns.Refresh()
end

function ns.ClearSteps()
    ns.state.steps = {}
    ns.Refresh()
end

-- ---------------------------------------------------------------------------
-- Gespeicherte Kombinationen
-- ---------------------------------------------------------------------------
function ns.LoadSaved(name)
    local entry = ns.db.saved[name]
    if not entry then return end
    ns.state.name = name
    ns.state.steps = CopySteps(entry.steps)
    ns.state.opts = CopyOpts(entry.opts)
    ns.Refresh()
end

function ns.DeleteSaved(name)
    ns.db.saved[name] = nil
    ns.Refresh()
end

-- ---------------------------------------------------------------------------
-- Eigene Makros im Spiel wiedererkennen (an der Kennung ns.MARKER im Makrotext)
-- ---------------------------------------------------------------------------
-- Liefert eine Tabelle Name -> Makro-Index fuer alle Makros mit Kennung (Account + Charakter)
function ns.ScanMacros()
    local found = {}
    local numAccount, numChar = GetNumMacros()
    local base = MAX_ACCOUNT_MACROS or 120
    local function check(index)
        local name, _, body = GetMacroInfo(index)
        if name and ns.IsOurMacro(body) then found[name] = index end
    end
    for i = 1, (numAccount or 0) do check(i) end
    for i = base + 1, base + (numChar or 0) do check(i) end
    return found
end

-- Liste aufbereiten: gespeicherte Kombinationen plus erkannte Makros ohne Vorlage
function ns.ListEntries()
    local inGame = ns.ScanMacros()
    local entries, seen = {}, {}
    for name in pairs(ns.db.saved) do
        entries[#entries + 1] = { name = name, hasTemplate = true, inGame = inGame[name] ~= nil }
        seen[name] = true
    end
    for name in pairs(inGame) do
        if not seen[name] then
            entries[#entries + 1] = { name = name, hasTemplate = false, inGame = true }
        end
    end
    table.sort(entries, function(a, b) return a.name < b.name end)
    return entries
end

function ns.PickupMacroByName(name)
    if InCombatLockdown() then
        ns.Print("Im Kampf nicht möglich.")
        return
    end
    local index = GetMacroIndexByName(name)
    if index and index > 0 then PickupMacro(index) end
end

-- Liste aktuell halten, wenn Makros im Spiel angelegt, geaendert oder geloescht werden
local macroWatcher = CreateFrame("Frame")
macroWatcher:RegisterEvent("UPDATE_MACROS")
macroWatcher:SetScript("OnEvent", function()
    if ns.state then ns.Refresh() end
end)

-- ---------------------------------------------------------------------------
-- Makro im Spiel anlegen / aktualisieren
-- ---------------------------------------------------------------------------
function ns.WriteMacro()
    local state = ns.state
    local name = Trim(state.name)
    if InCombatLockdown() then
        ns.Print("Im Kampf können keine Makros geändert werden.")
        return
    end
    if name == "" then
        ns.Print("Bitte zuerst einen Makronamen eingeben.")
        return
    end
    if #state.steps == 0 then
        ns.Print("Bitte zuerst Zauber in das Fenster ziehen.")
        return
    end
    local body = ns.BuildMacro(state.steps, state.opts)
    if #body > ns.MAX_MACRO_LEN then
        ns.Print("Makro ist zu lang (" .. #body .. "/" .. ns.MAX_MACRO_LEN .. " Zeichen).")
        return
    end

    local index = GetMacroIndexByName(name)
    local ok, err
    if index and index > 0 then
        -- Nur eigene Makros ueberschreiben: fremde Makros gleichen Namens bleiben unangetastet
        local _, _, oldBody = GetMacroInfo(index)
        if not ns.IsOurMacro(oldBody) then
            ns.Print("Es gibt schon ein Makro namens \"" .. name .. "\", das nicht von rp-macro-writer stammt. Bitte einen anderen Namen wählen.")
            return
        end
        ok, err = pcall(EditMacro, index, name, nil, body)
    else
        local numAccount, numChar = GetNumMacros()
        local perChar = state.opts.perChar and true or false
        local limit = perChar and (MAX_CHARACTER_MACROS or 18) or (MAX_ACCOUNT_MACROS or 120)
        if (perChar and numChar or numAccount) >= limit then
            ns.Print("Kein freier Makroplatz mehr (" .. (perChar and "Charakter" or "Account") .. ").")
            return
        end
        ok, err = pcall(CreateMacro, name, QUESTION_MARK_ICON, body, perChar)
    end
    if not ok then
        ns.Print("Makro konnte nicht gespeichert werden: " .. tostring(err))
        return
    end

    state.name = name
    ns.db.saved[name] = { steps = CopySteps(state.steps), opts = CopyOpts(state.opts) }
    ns.Print("Makro \"" .. name .. "\" gespeichert. Mit \"Auf Leiste\" kannst du es auf eine Aktionsleiste ziehen.")
    ns.Refresh()
end

function ns.PickupMacro()
    if InCombatLockdown() then
        ns.Print("Im Kampf nicht möglich.")
        return
    end
    local index = GetMacroIndexByName(Trim(ns.state.name))
    if index and index > 0 then
        PickupMacro(index)
    else
        ns.Print("Dieses Makro gibt es noch nicht – zuerst \"Makro erstellen/speichern\" klicken.")
    end
end

-- Platzhalter, bis UI.lua geladen ist
ns.Refresh = ns.Refresh or function() end

-- ---------------------------------------------------------------------------
-- Start
-- ---------------------------------------------------------------------------
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, addon)
    if addon ~= ADDON then return end
    self:UnregisterEvent("ADDON_LOADED")
    InitDB()
end)

SLASH_RPMACROWRITER1 = "/mw"
SLASH_RPMACROWRITER2 = "/rpmw"
SLASH_RPMACROWRITER3 = "/macrowriter"
SlashCmdList["RPMACROWRITER"] = function()
    if ns.Toggle then ns.Toggle() end
end
