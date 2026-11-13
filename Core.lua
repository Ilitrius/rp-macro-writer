-- Core.lua: Zustand, gespeicherte Daten, Drag & Drop-Annahme, Makro schreiben.
local ADDON, ns = ...
local L = ns.L

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
    db.ext = db.ext or {} -- Verlaengerung ueber 255 Zeichen: [Makroname] = { slot, text, parts }
    db.long = nil         -- Rest des ersten Versuchs vom 2026-11-10
    db.current = db.current or {}
    db.current.name = db.current.name or ""
    if type(db.current.manualBody) ~= "string" then db.current.manualBody = nil end
    db.current.foreign = nil -- Makro-Indizes gelten nur fuer die laufende Sitzung
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
        return nil, L["Das kann nicht in ein Makro übernommen werden (nur Zauber, Begleiterfähigkeiten und Gegenstände)."]
    end
    return nil, kind and L["Name konnte nicht ermittelt werden."] or nil
end

local function AddStep(step)
    if #ns.state.steps >= ns.MAX_STEPS then
        ns.Print(L["Maximal "] .. ns.MAX_STEPS .. L[" Zauber pro Makro."])
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
        ns.Print(L["Name des Gegenstands konnte nicht ermittelt werden."])
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

-- Schritt von Position from an Position to setzen (Drag & Drop in der Ablaufliste)
function ns.MoveStepTo(from, to)
    local steps = ns.state.steps
    if from == to or not steps[from] or to < 1 or to > #steps then return end
    table.insert(steps, to, table.remove(steps, from))
    ns.Refresh()
end

function ns.RemoveStep(index)
    table.remove(ns.state.steps, index)
    ns.Refresh()
end

function ns.ClearSteps()
    ns.state.steps = {}
    ns.state.manualBody = nil
    ns.state.foreign = nil
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
    ns.state.foreign = nil
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
            entries[#entries + 1] = { name = name, hasTemplate = true, inGame = m ~= nil, index = m and m.index,
                long = m and ns.db.ext[name] and #ns.db.ext[name].text or nil }
            seen[name] = true
        end
    end
    for name, m in pairs(inGame) do
        if not seen[name] then
            entries[#entries + 1] = { name = name, hasTemplate = false, inGame = true, index = m.index, foreign = not m.ours,
                long = m.ours and ns.db.ext[name] and #ns.db.ext[name].text or nil }
        end
    end
    -- Eigene Makros (mit Vorlage oder Kennung) zuerst, fremde danach; jeweils alphabetisch
    table.sort(entries, function(a, b)
        if (a.foreign and 1 or 0) ~= (b.foreign and 1 or 0) then return not a.foreign end
        local x, y = a.name:lower(), b.name:lower()
        if x ~= y then return x < y end
        return a.name < b.name
    end)
    return entries
end

-- Makro aus dem Spiel zum Bearbeiten laden (Text von Hand, ohne Zauberliste).
-- foreign = Makro stammt nicht vom Add-on: wird beim Speichern direkt geaendert, ohne Kennung
function ns.LoadMacro(index, foreign)
    local name, _, body = GetMacroInfo(index or 0)
    if not name then return end
    ns.state.name = name
    ns.state.steps = {}
    ns.state.manualBody = body or ""
    local ext = (not foreign) and ns.db.ext[name]
    if ext and ext.text and ext.text ~= "" and (body or ""):find("RPMWL" .. ext.slot .. " ", 1, true) then
        -- verlaengertes Makro: den vollen Text laden (mit der #show-Zeile aus dem Makro), nicht nur die /click-Zeilen
        local tip = (body or ""):match("^(#show[^\n]*)\n")
        ns.state.manualBody = (tip and (tip .. "\n") or "") .. ext.text .. "\n" .. ns.MARKER
    end
    ns.state.foreign = foreign and { name = name, index = index } or nil
    ns.state.opts.perChar = index > (MAX_ACCOUNT_MACROS or 120) -- Charakter-Makros haben die hohen Indizes
    ns.Refresh()
end

-- Liste aktuell halten, wenn Makros im Spiel angelegt, geaendert oder geloescht werden
local macroWatcher = CreateFrame("Frame")
macroWatcher:RegisterEvent("UPDATE_MACROS")
macroWatcher:SetScript("OnEvent", function()
    if ns.state then ns.Refresh() end
end)

-- ---------------------------------------------------------------------------
-- Beste Rotation: Blizzards Rotationshilfe (C_AssistedCombat), sonst eigene Tabelle
-- ---------------------------------------------------------------------------
local function IsKnown(id)
    if IsPlayerSpell and IsPlayerSpell(id) then return true end
    if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then return false end
    local name = SpellName(id)
    if not name then return false end
    if C_Spell and C_Spell.GetSpellInfo then return C_Spell.GetSpellInfo(name) ~= nil end
    return GetSpellInfo and GetSpellInfo(name) ~= nil or false
end

-- Talentbaum (1..3) fuer Forever/Classic: laut Wiki gibt es dort C_SpecializationInfo.GetSpecialization (1.60.1+);
-- sonst der Baum mit den meisten Punkten (GetTalentTabInfo). Retail nutzt keine Baeume (liefert nil).
-- Gibt zweitens zurueck, woher der Wert kam (fuer /mw rotation).
local function DetectTree()
    if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then return nil, "retail" end
    if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
        local ok, index = pcall(C_SpecializationInfo.GetSpecialization)
        if ok and type(index) == "number" and index >= 1 and index <= 3 then return index, "C_SpecializationInfo" end
    end
    if GetNumTalentTabs and GetTalentTabInfo then
        local best, bestPoints = nil, 0
        for i = 1, (GetNumTalentTabs() or 0) do
            local a, b, c, d, e = GetTalentTabInfo(i)
            -- neue Form: id, name, description, icon, pointsSpent; alte Form: name, icon, pointsSpent
            local points = (type(a) == "number") and e or c
            if type(points) == "number" and points > bestPoints then best, bestPoints = i, points end
        end
        if best then return best, "GetTalentTabInfo" end
    end
    return nil, "keine"
end

function ns.BestRotation()
    pcall(ns.RecordRotation) -- Dump fuer den Abgleich der Rotationstabellen sammeln (still)
    if InCombatLockdown() then
        ns.Print(L["Im Kampf können keine Makros geändert werden."])
        return
    end
    local ids, source
    local ac = C_AssistedCombat
    if ac and ac.GetRotationSpells and (not ac.IsAvailable or ac.IsAvailable()) then
        local ok, list = pcall(ac.GetRotationSpells)
        if ok and type(list) == "table" and #list > 0 then
            ids, source = {}, L["Blizzard-Rotationshilfe"]
            for _, id in ipairs(list) do
                if IsKnown(id) then ids[#ids + 1] = id end
            end
        end
    end
    if not ids or #ids == 0 then
        local _, class = UnitClass("player")
        ids = ns.PickRotation(class, IsKnown, WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and "retail" or "classic", (DetectTree()), UnitLevel("player"))
        source = L["eigene Tabelle"]
        if not ids then
            ns.Print(L["Für diese Klasse ist keine Rotation hinterlegt und die Rotationshilfe des Spiels liefert nichts."])
            return
        end
    end
    local steps, seen = {}, {}
    for _, id in ipairs(ids) do
        local name = SpellName(id)
        if name and #steps < ns.MAX_STEPS and (not seen[id] or id == ids[#ids]) then
            seen[id] = true
            steps[#steps + 1] = { kind = "spell", id = id, name = name, icon = SpellIcon(id) }
        end
    end
    if #steps == 0 then
        ns.Print(L["Keine passenden Zauber für Level "] .. UnitLevel("player") .. L[" gefunden."])
        return
    end
    ns.state.steps = steps
    ns.state.manualBody = nil
    ns.state.foreign = nil
    if Trim(ns.state.name) == "" then ns.state.name = "Rotation" end
    local names = {}
    for i, s in ipairs(steps) do names[i] = s.name end
    ns.Print("Rotation (" .. source .. L[", Level "] .. UnitLevel("player") .. "): " .. table.concat(names, ", "))
    ns.Refresh()
    ns.WriteMacro()
end

-- /mw rotation: schreibt auf, was die Blizzard-Rotationshilfe fuer diesen Charakter liefert (Klasse, Spielversion,
-- Level, Zauber mit ID und Name). Der Dump steht im Chat und in RPMacroWriterDB.rotationDump; der Agent
-- "rotation-helper" liest ihn aus der SavedVariables-Datei und gleicht Rotations/<Klasse>.lua damit ab.
-- Zeichnet auf, was die Rotationshilfe fuer diesen Charakter liefert (ohne Chatausgabe) und gibt den Dump zurueck.
function ns.RecordRotation()
    local _, class = UnitClass("player")
    local flavor = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE) and "retail" or "classic"
    local build, _, _, toc = GetBuildInfo()
    local dump = { class = class, flavor = flavor, level = UnitLevel("player"), build = build, toc = toc,
        race = select(2, UnitRace("player")), date = date("%Y-%m-%d %H:%M"), helper = {}, available = false }
    local ac = C_AssistedCombat
    if ac and ac.GetRotationSpells then
        dump.available = (not ac.IsAvailable) or ac.IsAvailable() and true or false
        local ok, list = pcall(ac.GetRotationSpells)
        if ok and type(list) == "table" then
            for _, id in ipairs(list) do
                dump.helper[#dump.helper + 1] = { id = id, name = SpellName(id) or "?", known = IsKnown(id) and true or false }
            end
        end
    end
    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex then dump.spec = select(2, GetSpecializationInfo(specIndex)) end
    local tree, treeSource = DetectTree()
    dump.tree, dump.treeSource = tree, treeSource
    local ids = ns.PickRotation(class, IsKnown, flavor, tree, dump.level)
    dump.table = {}
    for _, id in ipairs(ids or {}) do dump.table[#dump.table + 1] = id end
    ns.db.rotationDump = ns.db.rotationDump or {}
    local variant = dump.spec or (tree and ("tree" .. tree)) -- Retail: Spezialisierung, Forever: Talentbaum
    ns.db.rotationDump[class .. ":" .. flavor .. (variant and (":" .. variant) or "")] = dump
    return dump, class, flavor, build, tree, treeSource, ac
end

-- /mw rotation: zeichnet auf und schreibt das Ergebnis in den Chat
function ns.DumpRotation()
    local dump, class, flavor, build, tree, treeSource, ac = ns.RecordRotation()
    ns.Print("Rotationsdump " .. class .. " (" .. flavor .. ", Level " .. dump.level .. ", Build " .. tostring(build) .. ")")
    if not ac or not ac.GetRotationSpells then
        ns.Print("  C_AssistedCombat gibt es in dieser Spielversion nicht.")
    else
        ns.Print("  Rotationshilfe verfuegbar: " .. tostring(dump.available) .. ", " .. #dump.helper .. " Zauber")
        for i, s in ipairs(dump.helper) do
            ns.Print(string.format("  %d. %s (%d)%s", i, s.name, s.id, s.known and "" or " - nicht bekannt"))
        end
    end
    if flavor == "classic" then ns.Print("  Talentbaum: " .. tostring(tree) .. " (erkannt ueber " .. treeSource .. ")") end
    ns.Print("  Gespeichert in den SavedVariables (nach /reload oder Abmelden) unter rotationDump.")
end

-- ---------------------------------------------------------------------------
-- Verlaengerung ueber 255 Zeichen per /click (Vorbild: MacroToolkit, mainframe.lua CreateSecureActionButton)
-- Der Text liegt in sicheren Schaltflaechen RPMWL<slot>, RPMWL<slot>_2, ... (je Stueck hoechstens 255 Zeichen);
-- das Makro im Spiel enthaelt nur die Zeilen "/click RPMWL<slot> LeftButton 1".
-- ---------------------------------------------------------------------------
local extButtons = {}
local extPending = false

local function ExtButtonName(slot, part)
    return part == 1 and ("RPMWL" .. slot) or ("RPMWL" .. slot .. "_" .. part)
end

local function ExtButton(frameName)
    local btn = extButtons[frameName]
    if not btn then
        btn = CreateFrame("Button", frameName, nil, "SecureActionButtonTemplate")
        btn:SetAttribute("type", "macro")
        btn:SetAttribute("macrotext", "")
        btn:RegisterForClicks("AnyDown")
        -- ab Client 10.0.2: erzwingt die Ausfuehrung beim Druecken, unabhaengig von der Einstellung des Spiels
        btn:SetAttribute("pressAndHoldAction", "1")
        extButtons[frameName] = btn
    end
    return btn
end

-- Legt den Text einer Verlaengerung auf die Schaltflaechen (Attribute sind im Kampf gesperrt)
local function ApplyExt(entry)
    local chunks = ns.SplitChunks(entry.text, ns.MAX_MACRO_LEN) or {}
    for part = 1, math.max(#chunks, entry.parts or 0) do
        ExtButton(ExtButtonName(entry.slot, part)):SetAttribute("macrotext", chunks[part] or "")
    end
    entry.parts = #chunks
end

local function ExtSlot(name)
    local entry = ns.db.ext[name]
    if entry and entry.slot then return entry.slot end
    local used = {}
    for _, e in pairs(ns.db.ext) do used[e.slot] = true end
    local slot = 1
    while used[slot] do slot = slot + 1 end
    return slot
end

local function ClearExt(name)
    local entry = ns.db.ext[name]
    if not entry then return end
    entry.text = ""
    ApplyExt(entry) -- leert die Schaltflaechen
    ns.db.ext[name] = nil
end

-- Beim Anmelden alle gespeicherten Verlaengerungen wieder auf die Schaltflaechen legen
function ns.RestoreExt()
    if InCombatLockdown() then extPending = true; return end
    for _, entry in pairs(ns.db.ext) do ApplyExt(entry) end
end

local extRegen = CreateFrame("Frame")
extRegen:RegisterEvent("PLAYER_REGEN_ENABLED")
extRegen:SetScript("OnEvent", function()
    if extPending then extPending = false; ns.RestoreExt() end
end)

-- /mw long: zeigt, ob die Schaltflaechen da sind und wie viel Text sie halten
function ns.ExtStatus()
    local any
    for name, e in pairs(ns.db.ext) do
        any = true
        local chunks = ns.SplitChunks(e.text, ns.MAX_MACRO_LEN) or {}
        ns.Print(name .. ": " .. #e.text .. L[" Zeichen in "] .. #chunks .. L[" Teil(en)"])
        for i = 1, #chunks do
            local frameName = ExtButtonName(e.slot, i)
            local btn = _G[frameName]
            local have = btn and btn:GetAttribute("macrotext")
            ns.Print("  " .. frameName .. (btn and L[" vorhanden"] or L[" FEHLT"]) .. ", type=" .. tostring(btn and btn:GetAttribute("type"))
                .. ", " .. (have and #have or 0) .. "/" .. #chunks[i])
        end
    end
    if not any then ns.Print(L["Keine verlängerten Makros gespeichert."]) end
end

-- ---------------------------------------------------------------------------
-- Makro im Spiel anlegen / aktualisieren
-- ---------------------------------------------------------------------------
function ns.WriteMacro()
    local state = ns.state
    local name = Trim(state.name)
    if InCombatLockdown() then
        ns.Print(L["Im Kampf können keine Makros geändert werden."])
        return
    end
    if name == "" then
        ns.Print(L["Bitte zuerst einen Makronamen eingeben."])
        return
    end
    -- Fremdes Makro bearbeiten: direkt im Spiel aendern, ohne Kennung und ohne Vorlage
    if state.foreign then
        local body = state.manualBody or ""
        if #body > ns.MAX_MACRO_LEN then
            ns.Print(L["Makro ist zu lang ("] .. #body .. "/" .. ns.MAX_MACRO_LEN .. L[" Zeichen)."])
            return
        end
        local index = state.foreign.index
        local cur = GetMacroInfo(index or 0)
        if cur ~= state.foreign.name then -- Reihenfolge hat sich geaendert: nach altem Namen suchen
            index = GetMacroIndexByName(state.foreign.name)
        end
        if not index or index == 0 then
            ns.Print(L["Das Makro \""] .. state.foreign.name .. L["\" gibt es nicht mehr."])
            return
        end
        local ok, err = pcall(EditMacro, index, name, nil, body)
        if not ok then
            ns.Print(L["Makro konnte nicht gespeichert werden: "] .. tostring(err))
            return
        end
        state.name = name
        state.foreign = { name = name, index = GetMacroIndexByName(name) }
        ns.Print(L["Fremdes Makro \""] .. name .. L["\" geändert."])
        ns.Refresh()
        return
    end

    local manual = state.manualBody and state.manualBody ~= ""
    if #state.steps == 0 and not manual then
        ns.Print(L["Bitte zuerst Zauber in das Fenster ziehen."])
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
    -- Zu lang fuer ein Makro: Text in Zusatzschaltflaechen auslagern, das Makro ruft sie per /click auf
    local ext
    if #body > ns.MAX_MACRO_LEN then
        local slot = ExtSlot(name)
        local macro, chunks, text = ns.ExtendBody(body, function(i) return ExtButtonName(slot, i) end,
            (not manual and state.opts.showTooltip and state.steps[1]) and state.steps[1].name or nil)
        if not macro then
            if chunks == "long" then
                ns.Print(L["Makro ist zu lang ("] .. #body .. "/" .. ns.LONG_MAX .. L[" Zeichen). Bitte Zauber oder Optionen entfernen."])
            elseif chunks == "line" then
                ns.Print(L["Eine einzelne Zeile ist länger als 255 Zeichen und lässt sich nicht aufteilen. Bitte Zauber oder Optionen entfernen."])
            else
                ns.Print(L["Die /click-Zeilen passen nicht in 255 Zeichen. Bitte den Text kürzen."])
            end
            return
        end
        local old = ns.db.ext[name]
        ext = { slot = slot, text = text, parts = old and old.parts or 0, count = #chunks }
        body = macro
    end

    local index = GetMacroIndexByName(name)
    local ok, err
    if index and index > 0 then
        -- Nur eigene Makros ueberschreiben: fremde Makros gleichen Namens bleiben unangetastet
        local _, _, oldBody = GetMacroInfo(index)
        if not ns.IsOurMacro(oldBody) then
            ns.Print(L["Es gibt schon ein Makro namens \""] .. name .. L["\", das nicht von rp-macro-writer stammt. Bitte einen anderen Namen wählen."])
            return
        end
        ok, err = pcall(EditMacro, index, name, nil, body)
    else
        local numAccount, numChar = GetNumMacros()
        local perChar = state.opts.perChar and true or false
        local limit = perChar and (MAX_CHARACTER_MACROS or 18) or (MAX_ACCOUNT_MACROS or 120)
        if (perChar and numChar or numAccount) >= limit then
            ns.Print(L["Kein freier Makroplatz mehr ("] .. (perChar and L["Charakter"] or L["Account"]) .. ").")
            return
        end
        ok, err = pcall(CreateMacro, name, QUESTION_MARK_ICON, body, perChar)
    end
    if not ok then
        ns.Print(L["Makro konnte nicht gespeichert werden: "] .. tostring(err))
        return
    end

    if ext then
        local count = ext.count
        ext.count = nil
        ns.db.ext[name] = ext
        ApplyExt(ext)
        ns.Print(L["Der Makrotext ("] .. #ext.text .. L[" Zeichen) läuft über "] .. count .. L[" Zusatzschaltfläche(n) (/click)."])
    else
        ClearExt(name) -- wieder kurz genug: Text steht direkt im Makro
    end

    state.name = name
    ns.db.savedTab = state.opts.perChar and "char" or "global" -- Liste zeigt gleich den passenden Reiter
    ns.db.saved[name] = { steps = CopySteps(state.steps), opts = CopyOpts(state.opts), manualBody = manual and state.manualBody or nil }
    ns.Print(L["Makro \""] .. name .. L["\" gespeichert. Mit \"Auf Leiste\" kannst du es auf eine Aktionsleiste ziehen."])
    ns.Refresh()
end

function ns.PickupMacro()
    if InCombatLockdown() then
        ns.Print(L["Im Kampf nicht möglich."])
        return
    end
    local index = GetMacroIndexByName(Trim(ns.state.name))
    if index and index > 0 then
        PickupMacro(index)
    else
        ns.Print(L["Dieses Makro gibt es noch nicht – zuerst \"Makro erstellen/speichern\" klicken."])
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
    ns.RestoreExt()
end)

-- Rotationsdump automatisch schreiben: nach dem Anmelden und wenn sich Spezialisierung oder Talente aendern.
-- Verzoegert und zusammengefasst, damit Zauberbuch und Rotationshilfe geladen sind; ohne Chatausgabe.
local autoDump = CreateFrame("Frame")
local autoDumpPending = false
local function AutoDump()
    autoDumpPending = false
    if ns.db then pcall(ns.RecordRotation) end
end
local function ScheduleAutoDump()
    if autoDumpPending then return end
    autoDumpPending = true
    if C_Timer and C_Timer.After then C_Timer.After(5, AutoDump) else AutoDump() end
end
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_SPECIALIZATION_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_TALENT_UPDATE" }) do
    pcall(autoDump.RegisterEvent, autoDump, event) -- nicht jede Spielversion kennt jedes Ereignis
end
autoDump:SetScript("OnEvent", ScheduleAutoDump)

SLASH_RPMACROWRITER1 = "/mw"
SLASH_RPMACROWRITER2 = "/rpmw"
SLASH_RPMACROWRITER3 = "/macrowriter"
SlashCmdList["RPMACROWRITER"] = function(msg)
    if msg and msg:lower():match("^%s*rotation") then return ns.DumpRotation() end
    if msg and msg:lower():match("^%s*long") then return ns.ExtStatus() end
    if ns.Toggle then ns.Toggle() end
end
