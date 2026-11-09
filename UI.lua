-- UI.lua: Fenster mit Ablaufliste (Drop-Ziel), Optionen, Vorschau und gespeicherten Kombinationen.
local ADDON, ns = ...

local ROWS, ROW_H = ns.MAX_STEPS, 31
local BOTTOM = -72-- Versatz des unteren Bereichs (Name, Vorschau, gespeicherte Kombinationen)
local SAVED_ROWS, SAVED_H = 6, 22
local LEFT_X, LEFT_W = 14, 300
local RIGHT_X, RIGHT_W = 328, 298

local MOD_LABEL = { [""] = "-", shift = "Shift", ctrl = "Strg", alt = "Alt" }
local MOD_NEXT = { [""] = "shift", shift = "ctrl", ctrl = "alt", alt = "" }

local ui = { syncs = {}, savedOffset = 0 }

-- ---------------------------------------------------------------------------
-- Bausteine
-- ---------------------------------------------------------------------------
local function AcceptDrop(frame)
    frame:EnableMouse(true)
    frame:SetScript("OnReceiveDrag", function() ns.TryDrop() end)
    frame:HookScript("OnMouseUp", function()
        if GetCursorInfo() then ns.TryDrop() end
    end)
end

local function Label(parent, text, x, y, font)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetText(text)
    return fs
end

local function Box(parent, x, y, w, h)
    local box = CreateFrame("Frame", nil, parent)
    box:SetSize(w, h)
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.45)
    return box
end

local function Check(parent, text, x, y, getter, onClick)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(22, 22)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", cb, "RIGHT", 1, 0)
    fs:SetText(text)
    cb:SetHitRectInsets(0, -(fs:GetStringWidth() + 2), 0, 0)
    cb:SetScript("OnClick", function(self)
        onClick(self:GetChecked() and true or false)
        ns.Refresh()
    end)
    ui.syncs[#ui.syncs + 1] = function() cb:SetChecked(getter() and true or false) end
    return cb
end

-- Ankreuzfeld fuer eine Ja/Nein-Option
local function Toggle(parent, text, x, y, key)
    return Check(parent, text, x, y,
        function() return ns.state.opts[key] end,
        function(checked) ns.state.opts[key] = checked end)
end

-- Auswahlfeld: genau ein Wert einer Option aktiv
local function Radio(parent, text, x, y, key, value)
    return Check(parent, text, x, y,
        function() return ns.state.opts[key] == value end,
        function() ns.state.opts[key] = value end)
end

local function IconButton(parent, texture, size)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(size, size)
    b:SetNormalTexture(texture)
    b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    return b
end

local function TextButton(parent, text, w, h)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, h or 22)
    b:SetText(text)
    return b
end

local function SetEnabled(control, enabled)
    if enabled then control:Enable() else control:Disable() end
    control:SetAlpha(enabled and 1 or 0.4)
end

-- ---------------------------------------------------------------------------
-- Ablaufliste
-- ---------------------------------------------------------------------------
local function CreateStepRow(parent, i)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(LEFT_W - 8, ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -4 - (i - 1) * ROW_H)
    AcceptDrop(row)

    row.index = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.index:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.index:SetWidth(18)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(20, 20)
    row.icon:SetPoint("LEFT", row, "LEFT", 20, 0)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.name:SetPoint("LEFT", row, "LEFT", 46, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)

    row.remove = IconButton(row, "Interface\\Buttons\\UI-StopButton", 16)
    row.remove:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    row.remove:SetScript("OnClick", function() ns.RemoveStep(i) end)

    row.down = IconButton(row, "Interface\\Buttons\\Arrow-Down-Up", 16)
    row.down:SetPoint("RIGHT", row.remove, "LEFT", -4, -3)
    row.down:SetScript("OnClick", function() ns.MoveStep(i, 1) end)

    row.up = IconButton(row, "Interface\\Buttons\\Arrow-Up-Up", 16)
    row.up:SetPoint("RIGHT", row.down, "LEFT", -2, 6)
    row.up:SetScript("OnClick", function() ns.MoveStep(i, -1) end)

    row.mod = TextButton(row, "-", 46, 20)
    row.mod:SetPoint("RIGHT", row, "RIGHT", -62, 0)
    row.mod:SetScript("OnClick", function()
        local step = ns.state.steps[i]
        if step then
            local nextMod = MOD_NEXT[step.mod or ""]
            step.mod = (nextMod ~= "") and nextMod or nil
            ns.Refresh()
        end
    end)

    row:SetScript("OnEnter", function(self)
        local step = ns.state.steps[i]
        if step and step.kind == "spell" and GameTooltip.SetSpellByID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(step.id)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return row
end

-- ---------------------------------------------------------------------------
-- Gespeicherte Kombinationen
-- ---------------------------------------------------------------------------

local function CreateSavedRow(parent, i)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(RIGHT_W - 8, SAVED_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -3 - (i - 1) * SAVED_H)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.text:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.text:SetPoint("RIGHT", row, "RIGHT", -24, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)

    row:SetScript("OnClick", function(self)
        if not self.savedName then return end
        if self.hasTemplate then
            ns.LoadSaved(self.savedName)
        else
            -- Makro mit Kennung, aber ohne Vorlage: direkt auf den Mauszeiger nehmen
            ns.PickupMacroByName(self.savedName)
        end
    end)

    row.delete = IconButton(row, "Interface\\Buttons\\UI-StopButton", 14)
    row.delete:SetPoint("RIGHT", row, "RIGHT", -3, 0)
    row.delete:SetScript("OnClick", function()
        if row.savedName then ns.DeleteSaved(row.savedName) end
    end)
    return row
end

-- ---------------------------------------------------------------------------
-- Fenster
-- ---------------------------------------------------------------------------
local function CreateUI()
    local f = CreateFrame("Frame", "RPMacroWriterFrame", UIParent, "BasicFrameTemplate")
    ui.frame = f
    f:SetSize(640, 598)
    f:SetPoint("CENTER", UIParent, "CENTER", 250, 0)
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    AcceptDrop(f)
    tinsert(UISpecialFrames, "RPMacroWriterFrame") -- ESC schliesst das Fenster

    if f.TitleText then
        f.TitleText:SetText("rp-macro-writer")
    else
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", f, "TOP", 0, -6)
        title:SetText("rp-macro-writer")
    end

    -- Links: Ablauf ----------------------------------------------------------
    Label(f, "Ablauf", LEFT_X, -32)
    ui.detected = f:CreateFontString(nil, "OVERLAY", "GameFontGreenSmall")
    ui.detected:SetPoint("TOPRIGHT", f, "TOPLEFT", LEFT_X + LEFT_W, -33)
    local drop = Box(f, LEFT_X, -50, LEFT_W, ROWS * ROW_H + 8)
    AcceptDrop(drop)
    ui.dropHint = drop:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    ui.dropHint:SetPoint("CENTER")
    ui.dropHint:SetWidth(LEFT_W - 40)
    ui.dropHint:SetText("Zauber aus dem Zauberbuch\nhierher ziehen")

    ui.rows = {}
    for i = 1, ROWS do ui.rows[i] = CreateStepRow(drop, i) end

    -- Rechts: Optionen -------------------------------------------------------
    local c1, c2, c3 = RIGHT_X, RIGHT_X + 110, RIGHT_X + 210

    Label(f, "Makro-Art", RIGHT_X, -32)
    Radio(f, "Automatisch erkennen", c1, -48, "mode", "auto")
    Radio(f, "Zusatztaste", c1 + 160, -48, "mode", "modifier")
    Radio(f, "Einzelne Zeilen", c1, -70, "mode", "lines")
    Radio(f, "Zufall", c1 + 160, -70, "mode", "random")

    Label(f, "Sequenz zurücksetzen (Reset) bei", RIGHT_X, -100)
    ui.resetTarget = Toggle(f, "Zielwechsel", c1, -116, "resetTarget")
    ui.resetCombat = Toggle(f, "Kampfende", c2, -116, "resetCombat")
    ui.secsLabel = Label(f, "Sek.:", c3, -121, "GameFontHighlightSmall")
    local secs = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    ui.secs = secs
    secs:SetSize(36, 20)
    secs:SetPoint("TOPLEFT", f, "TOPLEFT", c3 + 40, -117)
    secs:SetAutoFocus(false)
    secs:SetNumeric(true)
    secs:SetMaxLetters(3)
    secs:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            ns.state.opts.resetSeconds = tonumber(self:GetText()) or 0
            ns.Refresh()
        end
    end)
    secs:SetScript("OnEnterPressed", secs.ClearFocus)
    secs:SetScript("OnEscapePressed", secs.ClearFocus)

    Label(f, "Ziel", RIGHT_X, -148)
    Radio(f, "Aktuelles Ziel", c1, -164, "target", "target")
    Radio(f, "Mouseover", c2, -164, "target", "mouseover")
    Radio(f, "Fokus", c3, -164, "target", "focus")

    Label(f, "Ziel muss sein", RIGHT_X, -196)
    Radio(f, "Feind", c1, -212, "hostility", "harm")
    Radio(f, "Freund", c2, -212, "hostility", "help")
    Radio(f, "Egal", c3, -212, "hostility", "any")
    Radio(f, "Am Leben", c1, -234, "life", "alive")
    Radio(f, "Tot", c2, -234, "life", "dead")
    Radio(f, "Egal", c3, -234, "life", "any")

    Label(f, "Extras", RIGHT_X, -266)
    Toggle(f, "Symbol/Tooltip anzeigen", c1, -282, "showTooltip")
    Toggle(f, "Begleiter greift an", c1 + 160, -282, "petAttack")
    Toggle(f, "Automatisch Gegner wählen", c1, -304, "autoTarget")
    Toggle(f, "Nur dieser Charakter", c1 + 160, -304, "perChar")
    Toggle(f, "Kanalisierte Zauber nicht abbrechen", c1, -326, "noChannel")
    -- Setzt den Fokus auf die Einheit unter der Maus und stellt das Ziel gleich auf "Fokus" um
    Check(f, "Maus-Ziel als Fokus setzen", c1, -348,
        function() return ns.state.opts.focusMouseover end,
        function(checked)
            ns.state.opts.focusMouseover = checked
            if checked then ns.state.opts.target = "focus" end
        end)
    Toggle(f, "Am Ende angreifen", c1 + 160, -348, "startAttack")

    -- Unten links: Name, Vorschau, Knoepfe ------------------------------------
    Label(f, "Makroname", LEFT_X, -312 + BOTTOM)
    local name = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    ui.name = name
    name:SetSize(130, 20)
    name:SetPoint("TOPLEFT", f, "TOPLEFT", LEFT_X + 90, -308 + BOTTOM)
    name:SetAutoFocus(false)
    name:SetMaxLetters(ns.MAX_NAME_LEN)
    name:SetScript("OnTextChanged", function(self, userInput)
        if userInput then ns.state.name = self:GetText() end
    end)
    name:SetScript("OnEnterPressed", name.ClearFocus)
    name:SetScript("OnEscapePressed", name.ClearFocus)

    ui.counter = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.counter:SetPoint("TOPRIGHT", f, "TOPLEFT", LEFT_X + LEFT_W, -313 + BOTTOM)

    local previewBox = Box(f, LEFT_X, -334 + BOTTOM, LEFT_W, 112)
    AcceptDrop(previewBox)
    ui.preview = previewBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.preview:SetPoint("TOPLEFT", previewBox, "TOPLEFT", 6, -6)
    ui.preview:SetPoint("BOTTOMRIGHT", previewBox, "BOTTOMRIGHT", -6, 6)
    ui.preview:SetJustifyH("LEFT")
    ui.preview:SetJustifyV("TOP")
    ui.preview:SetWordWrap(true)

    ui.warning = f:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
    ui.warning:SetPoint("TOPLEFT", f, "TOPLEFT", LEFT_X, -450 + BOTTOM)
    ui.warning:SetWidth(LEFT_W)
    ui.warning:SetJustifyH("LEFT")
    ui.warning:SetJustifyV("TOP")

    local create = TextButton(f, "Makro erstellen/speichern", 172)
    create:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", LEFT_X, 12)
    create:SetScript("OnClick", function() ns.WriteMacro() end)

    local pickup = TextButton(f, "Auf Leiste", 74)
    pickup:SetPoint("LEFT", create, "RIGHT", 4, 0)
    pickup:SetScript("OnClick", function() ns.PickupMacro() end)

    local clear = TextButton(f, "Leeren", 50)
    clear:SetPoint("LEFT", pickup, "RIGHT", 4, 0)
    clear:SetScript("OnClick", function() ns.ClearSteps() end)

    -- Unten rechts: gespeicherte Kombinationen --------------------------------
    Label(f, "Gespeicherte Kombinationen", RIGHT_X, -312 + BOTTOM)
    local saved = Box(f, RIGHT_X, -334 + BOTTOM, RIGHT_W, SAVED_ROWS * SAVED_H + 6)
    ui.savedEmpty = saved:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    ui.savedEmpty:SetPoint("CENTER")
    ui.savedEmpty:SetText("Noch nichts gespeichert")
    ui.savedRows = {}
    for i = 1, SAVED_ROWS do ui.savedRows[i] = CreateSavedRow(saved, i) end
    saved:EnableMouseWheel(true)
    saved:SetScript("OnMouseWheel", function(_, delta)
        ui.savedOffset = ui.savedOffset - delta
        ns.Refresh()
    end)
    local hint = Label(f, "Klick lädt die Kombination, das rote Symbol löscht die Vorlage. Grau = Makro ohne Vorlage, Klick nimmt es auf.", RIGHT_X, -478 + BOTTOM, "GameFontDisableSmall")
    hint:SetWidth(RIGHT_W)
    hint:SetJustifyH("LEFT")

    f:Hide()
end

-- ---------------------------------------------------------------------------
-- Anzeige aktualisieren
-- ---------------------------------------------------------------------------
function ns.Refresh()
    if not ui.frame then return end
    local state = ns.state
    local opts = state.opts
    local steps = state.steps
    local modifierMode = opts.mode == "modifier"

    for i = 1, ROWS do
        local row, step = ui.rows[i], steps[i]
        if step then
            row.index:SetText(i .. ".")
            row.icon:SetTexture(step.icon or 134400)
            row.name:SetText(step.name)
            row.name:SetPoint("RIGHT", row, "RIGHT", modifierMode and -112 or -62, 0)
            row.mod:SetShown(modifierMode)
            row.mod:SetText(MOD_LABEL[step.mod or ""])
            SetEnabled(row.up, i > 1)
            SetEnabled(row.down, i < #steps)
            row:Show()
        else
            row:Hide()
        end
    end
    ui.dropHint:SetShown(#steps == 0)

    for _, sync in ipairs(ui.syncs) do sync() end
    local autoMode = opts.mode == "auto"
    local sequenceMode = autoMode and ns.DetectKind(steps) == "sequence"
    if not autoMode or #steps == 0 then
        ui.detected:SetText("")
    elseif sequenceMode then
        ui.detected:SetText("Erkannt: Cast-Sequenz")
    else
        ui.detected:SetText("Erkannt: einfacher Cast")
    end
    SetEnabled(ui.resetTarget, sequenceMode)
    SetEnabled(ui.resetCombat, sequenceMode)
    SetEnabled(ui.secs, sequenceMode)
    ui.secsLabel:SetAlpha(sequenceMode and 1 or 0.4)
    if not ui.secs:HasFocus() then
        ui.secs:SetText(opts.resetSeconds > 0 and tostring(opts.resetSeconds) or "")
    end
    if ui.name:GetText() ~= state.name then ui.name:SetText(state.name) end

    local body, warnings = ns.BuildMacro(steps, opts)
    ui.preview:SetText(body)
    local len = #body
    ui.counter:SetText(len .. "/" .. ns.MAX_MACRO_LEN)
    if len > ns.MAX_MACRO_LEN then
        ui.counter:SetTextColor(1, 0.2, 0.2)
    else
        ui.counter:SetTextColor(1, 1, 1)
    end
    ui.warning:SetText(table.concat(warnings, "\n"))

    local entries = ns.ListEntries()
    local maxOffset = math.max(0, #entries - SAVED_ROWS)
    ui.savedOffset = math.min(math.max(ui.savedOffset, 0), maxOffset)
    for i = 1, SAVED_ROWS do
        local row, entry = ui.savedRows[i], entries[i + ui.savedOffset]
        row.savedName = entry and entry.name
        row.hasTemplate = entry and entry.hasTemplate
        if entry then
            if not entry.hasTemplate then
                row.text:SetText("|cffaaaaaa" .. entry.name .. " (nur Makro)|r")
            elseif entry.inGame then
                row.text:SetText(entry.name .. " |cff40ff40(im Spiel)|r")
            else
                row.text:SetText(entry.name)
            end
            row.delete:SetShown(entry.hasTemplate)
            row:Show()
        else
            row:Hide()
        end
    end
    ui.savedEmpty:SetShown(#entries == 0)
end

function ns.Toggle()
    if not ns.state then return end
    if not ui.frame then CreateUI() end
    if ui.frame:IsShown() then
        ui.frame:Hide()
    else
        ns.Refresh()
        ui.frame:Show()
    end
end
