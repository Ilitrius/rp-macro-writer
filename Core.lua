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
    if type(db.current.manualBody) ~= "string" then db.current.manualBody = nil end
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
        -- Gegenstand noch nicht im Client-Cache: nachladen lassen, Schritt folgt per Ereignis
        if a then return nil, nil, a end
    elseif kind then
        return nil, "Das kann nicht in ein Makro übernommen werden (nur Zauber, Begleiterfähigkeiten und Gegenstände)."
    end
    return nil, kind and "Name konnte nicht ermittelt werden." or nil
end

local function AddStep(step)
    if #ns.state.steps >= ns.MAX_STEPS then
        ns.Print("Maximal " .. ns.MAX_STEPS .. " Zauber pro Makro.")
        return
    end
    table.insert(ns.state.steps, step)
    ns.Refresh()
end

-- Gegenstaende, deren Daten noch nachgeladen werden: itemID -> Anzahl wartender Ablagen
local pendingItems = {}
local itemWatcher = CreateFrame("Frame")
itemWatcher:SetScript("OnEvent", function(_, _, itemID, success)
    local count = pendingItems[itemID]
    if not count then return end
    pendingItems[itemID] = nil
    if not next(pendingItems) then itemWatcher:UnregisterEvent("GET_ITEM_INFO_RECEIVED") end
    local name = success ~= false and ItemName(itemID)
    if not name then
        ns.Print("Name des Gegenstands konnte nicht ermittelt werden.")
        return
    end
    for _ = 1, count do
        AddStep({ kind = "item", id = itemID, name = name, icon = ItemIcon(itemID) })
    end
end)

local function RequestItem(itemID)
    if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(itemID) end
    pendingItems[itemID] = (pendingItems[itemID] or 0) + 1
    itemWatcher:RegisterEvent("GET_ITEM_INFO_RECEIVED")
end

function ns.TryDrop()
    local step, err, pendingItem = StepFromCursor()
    if not step then
        if pendingItem then
            ClearCursor()
            RequestItem(pendingItem)
        elseif err then
            ns.Print(err)
        end
        return
    end
    ClearCursor()
    AddStep(step)
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
    ns.state.manualBody = nil
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
    ns.state.manualBody = entry.manualBody
    ns.Refresh()
end

function ns.DeleteSaved(name)
    ns.db.saved[name] = nil
    ns.Refresh()
end

-- ---------------------------------------------------------------------------
-- Eigene Makros im Spiel wiedererkennen (an der Kennung ns.MARKER im Makrotext)
-- ---------------------------------------------------------------------------
-- Alle Makros im Spiel eines Bereichs: scope "global" (Account) oder "char" (dieser Charakter).
-- Liefert Liste { name, index, ours } (ours = hat die Kennung ns.MARKER)
local function ScanScope(scope)
    local list = {}
    local numAccount, numChar = GetNumMacros()
    local base = MAX_ACCOUNT_MACROS or 120
    local first, last
    if scope == "global" then
        first, last = 1, numAccount or 0
    else
        first, last = base + 1, base + (numChar or 0)
    end
    for index = first, last do
        local name, _, body = GetMacroInfo(index)
        if name then list[#list + 1] = { name = name, index = index, ours = ns.IsOurMacro(body) } end
    end
    return list
end

-- Liste eines Reiters aufbereiten: gespeicherte Kombinationen dieses Bereichs plus alle Makros
-- im Spiel dieses Bereichs (eigene ohne Vorlage, fremde)
function ns.ListEntries(scope)
    local wantChar = scope == "char"
    local inGame, entries, seen = {}, {}, {}
    for _, m in ipairs(ScanScope(scope)) do inGame[m.name] = m end
    for name, saved in pairs(ns.db.saved) do
        local isChar = saved.opts and saved.opts.perChar and true or false
        if isChar == wantChar then
            local m = inGame[name]
            entries[#entries + 1] = { name = name, hasTemplate = true, inGame = m ~= nil, index = m and m.index }
            seen[name] = true
        end
    end
    for name, m in pairs(inGame) do
        if not seen[name] then
            entries[#entries + 1] = { name = name, hasTemplate = false, inGame = true, index = m.index, foreign = not m.ours }
        end
    end
    table.sort(entries, function(a, b)
        local x, y = a.name:lower(), b.name:lower()
        if x ~= y then return x < y end
        return a.name < b.name
    end)
    return entries
end

function ns.PickupMacroAt(index)
    if InCombatLockdown() then
        ns.Print("Im Kampf nicht möglich.")
        return
    end
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
    local manual = state.manualBody and state.manualBody ~= ""
    if #state.steps == 0 and not manual then
        ns.Print("Bitte zuerst Zauber in das Fenster ziehen.")
        return
    end
    local body
    if manual then
        -- Von Hand bearbeiteter Text; ohne Kennung koennte das Add-on das Makro nicht wiedererkennen
        body = state.manualBody
        if not ns.IsOurMacro(body) then body = body:gsub("%s+$", "") .. "\n" .. ns.MARKER end
    else
        body = ns.BuildMacro(state.steps, state.opts)
    end
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
    ns.db.savedTab = state.opts.perChar and "char" or "global" -- Liste zeigt gleich den passenden Reiter
    ns.db.saved[name] = { steps = CopySteps(state.steps), opts = CopyOpts(state.opts), manualBody = manual and state.manualBody or nil }
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
