-- UI.lua: Fenster mit Ablaufliste (Drop-Ziel), Optionen, Vorschau und gespeicherten Kombinationen.
local ADDON, ns = ...
local L = ns.L

local ROWS, ROW_H = ns.MAX_STEPS, 31
local BOTTOM = -94 --Versatz des unteren Bereichs (Name, Vorschau, gespeicherte Kombinationen)
local SAVED_ROWS, SAVED_H = 6, 22
local LEFT_X, LEFT_W = 14, 300
local RIGHT_X, RIGHT_W = 328, 298

local MOD_LABEL = { [""] = "-", shift = "Shift", ctrl = L["Strg"], alt = "Alt" }
local MOD_NEXT = { [""] = "shift", shift = "ctrl", ctrl = "alt", alt = "" }

local MIN_W, MAX_W = 640, 1100 -- Fensterbreite
local MIN_H, MAX_H = 620, 900  -- Fensterhoehe

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
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -4 - (i - 1) * ROW_H)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -4 - (i - 1) * ROW_H)
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

    -- Umsortieren per Ziehen: Zeile anklicken, mit gedrueckter Maustaste auf eine andere Zeile ziehen
    row.target = row:CreateTexture(nil, "OVERLAY")
    row.target:SetAllPoints()
    row.target:SetColorTexture(1, 0.82, 0, 0.25)
    row.target:Hide()
    row:HookScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and ns.state.steps[i] and not GetCursorInfo() then
            ui.dragFrom = i
            self:SetScript("OnUpdate", function()
                for r = 1, ROWS do
                    local other = ui.rows[r]
                    other.target:SetShown(other:IsShown() and other:IsMouseOver() and r ~= i)
                end
            end)
        end
    end)
    row:HookScript("OnMouseUp", function(self, button)
        if ui.dragFrom ~= i then return end
        ui.dragFrom = nil
        self:SetScript("OnUpdate", nil)
        local to
        for r = 1, ROWS do
            ui.rows[r].target:Hide()
            if ui.rows[r]:IsShown() and ui.rows[r]:IsMouseOver() then to = r end
        end
        if to and to ~= i then ns.MoveStepTo(i, to) end
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
            -- Makro ohne Vorlage (eigenes ohne Daten oder fremdes): Text zum Bearbeiten laden
            ns.LoadMacro(self.macroIndex, self.foreign)
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
    f:SetSize(640, 620)
    f:SetPoint("CENTER", UIParent, "CENTER", 250, 0)
    -- Position und Groesse aus der letzten Sitzung wiederherstellen
    local w = ns.db and ns.db.window
    if type(w) == "table" and w.point and tonumber(w.x) and tonumber(w.y) then
        f:SetSize(math.min(math.max(tonumber(w.w) or 640, MIN_W), MAX_W),
                  math.min(math.max(tonumber(w.h) or 620, MIN_H), MAX_H))
        f:ClearAllPoints()
        f:SetPoint(w.point, UIParent, w.relPoint or w.point, w.x, w.y)
    end
    ui.saveWindow = function()
        local point, _, relPoint, x, y = f:GetPoint(1)
        if point and ns.db then
            ns.db.window = { point = point, relPoint = relPoint, x = x, y = y,
                             w = f:GetWidth(), h = f:GetHeight() }
        end
    end
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        ui.saveWindow()
    end)
    AcceptDrop(f)
    tinsert(UISpecialFrames, "RPMacroWriterFrame") -- ESC schliesst das Fenster

    -- Titel mit Version aus der TOC (## Version)
    local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local version = getMeta and getMeta(ADDON, "Version")
    local titleText = "rp-macro-writer" .. (version and (" |cff888888v" .. version .. "|r") or "")
    if f.TitleText then
        f.TitleText:SetText(titleText)
    else
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", f, "TOP", 0, -6)
        title:SetText(titleText)
    end

    -- Makro-Symbol oben rechts (Symbol des ersten Schritts, wie bei #showtooltip)
    -- Links: Ablauf ----------------------------------------------------------
    Label(f, L["Ablauf"], LEFT_X, -32)
    local best = TextButton(f, L["Beste Rotation"], 104, 18)
    best:SetPoint("TOPLEFT", f, "TOPLEFT", LEFT_X + 56, -29)
    best:SetScript("OnClick", function() ns.BestRotation() end)
    best:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Beste Rotation für dein Level und deine verfügbaren Zauber\nersetzt den Ablauf und legt das Makro an"], nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    best:SetScript("OnLeave", function() GameTooltip:Hide() end)
    ui.detected = f:CreateFontString(nil, "OVERLAY", "GameFontGreenSmall")
    ui.detected:SetPoint("TOPRIGHT", f, "TOPRIGHT", -(RIGHT_W + 28), -33)
    local drop = Box(f, LEFT_X, -50, LEFT_W, ROWS * ROW_H + 8)
    drop:SetPoint("TOPRIGHT", f, "TOPRIGHT", -(RIGHT_W + 28), -50)
    AcceptDrop(drop)
    ui.dropHint = drop:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    ui.dropHint:SetPoint("CENTER")
    ui.dropHint:SetWidth(LEFT_W - 40)
    ui.dropHint:SetText(L["Zauber aus dem Zauberbuch\nhierher ziehen"])

    ui.rows = {}
    for i = 1, ROWS do ui.rows[i] = CreateStepRow(drop, i) end

    -- Rechts: Optionen (Container haengt am rechten Fensterrand, wandert beim Verbreitern mit) --
    local right = CreateFrame("Frame", nil, f)
    right:SetSize(RIGHT_W, 560)
    right:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, 0)
    local c1, c2, c3 = 0, 110, 210

    -- Makro-Symbol (Symbol des ersten Schritts, wie bei #showtooltip), rechts neben der Makro-Art
    ui.macroIcon = right:CreateTexture(nil, "ARTWORK")
    ui.macroIcon:SetSize(40, 40)
    ui.macroIcon:SetPoint("TOPRIGHT", right, "TOPRIGHT", 0, -34)

    Label(right, L["Makro-Art"], 0, -32)
    Radio(right, L["Automatisch erkennen"], c1, -48, "mode", "auto")
    Radio(right, L["Zusatztaste"], c1 + 160, -48, "mode", "modifier")
    Radio(right, L["Einzelne Zeilen"], c1, -70, "mode", "lines")
    Radio(right, L["Zufall"], c1 + 160, -70, "mode", "random")

    Label(right, L["Sequenz zurücksetzen (Reset) bei"], 0, -100)
    ui.resetTarget = Toggle(right, L["Zielwechsel"], c1, -116, "resetTarget")
    ui.resetCombat = Toggle(right, L["Kampfende"], c2, -116, "resetCombat")
    ui.secsLabel = Label(right, L["Sek.:"], c3, -121, "GameFontHighlightSmall")
    local secs = CreateFrame("EditBox", nil, right, "InputBoxTemplate")
    ui.secs = secs
    secs:SetSize(36, 20)
    secs:SetPoint("TOPLEFT", right, "TOPLEFT", c3 + 40, -117)
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

    Label(right, L["Ziel"], 0, -148)
    Radio(right, L["Aktuelles Ziel"], c1, -164, "target", "target")
    Radio(right, "Mouseover", c2, -164, "target", "mouseover")
    Radio(right, L["Fokus"], c3, -164, "target", "focus")
    Toggle(right, L["Rückfall auf aktuelles Ziel"], c2 - 4, -141, "fallbackTarget")

    Label(right, L["Ziel muss sein"], 0, -196)
    Radio(right, L["Feind"], c1, -212, "hostility", "harm")
    Radio(right, L["Freund"], c2, -212, "hostility", "help")
    Radio(right, L["Egal"], c3, -212, "hostility", "any")
    Radio(right, L["Am Leben"], c1, -234, "life", "alive")
    Radio(right, L["Tot"], c2, -234, "life", "dead")
    Radio(right, L["Egal"], c3, -234, "life", "any")

    Label(right, "Extras", 0, -266)
    Toggle(right, L["Symbol/Tooltip anzeigen"], c1, -282, "showTooltip")
    Toggle(right, L["Begleiter greift an"], c1 + 160, -282, "petAttack")
    Toggle(right, L["Automatisch Gegner wählen"], c1, -304, "autoTarget")
    Toggle(right, L["Nur dieser Charakter"], c1 + 160, -304, "perChar")
    Toggle(right, L["Kanalisierte Zauber nicht abbrechen"], c1, -326, "noChannel")
    -- Fokus auf die Einheit unter der Maus (sonst aufs Ziel) setzen; gleich anvisieren, abwaehlbar
    Check(right, L["Maus-Ziel als Fokus setzen"], c1, -348,
        function() return ns.state.opts.focusMouseover end,
        function(checked)
            ns.state.opts.focusMouseover = checked
            ns.state.opts.targetFocus = checked
        end)
    Toggle(right, L["Am Ende angreifen"], c1 + 160, -348, "startAttack")
    Toggle(right, L["Fokus anvisieren"], c1, -370, "targetFocus")
    Toggle(right, L["Ziel des Ziels (Rückfall)"], c1 + 160, -370, "targetTarget")

    -- Unten links: Name, Vorschau, Knoepfe ------------------------------------
    Label(f, L["Makroname"], LEFT_X, -312 + BOTTOM)
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
    ui.counter:SetPoint("TOPRIGHT", f, "TOPRIGHT", -(RIGHT_W + 28), -313 + BOTTOM)

    -- Makrotext: bearbeitbar; waechst mit der Fensterhoehe
    local previewBox = Box(f, LEFT_X, -334 + BOTTOM, LEFT_W, 112)
    previewBox:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -(RIGHT_W + 28), 76)
    local scroll = CreateFrame("ScrollFrame", "RPMacroWriterPreviewScroll", previewBox, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", previewBox, "TOPLEFT", 4, -4)
    -- unten Platz fuer den Griff lassen, damit der Scroll-Pfeil ihn nicht verdeckt
    scroll:SetPoint("BOTTOMRIGHT", previewBox, "BOTTOMRIGHT", -26, 24)
    local edit = CreateFrame("EditBox", nil, scroll)
    ui.preview = edit
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("GameFontHighlightSmall")
    edit:SetWidth(LEFT_W - 34)
    edit:SetMaxLetters(0)
    scroll:SetScrollChild(edit)
    -- Syntaxfarben: der eigene Text des Felds ist unsichtbar (Cursor bleibt), darueber liegt
    -- eine gleich umbrochene, eingefaerbte Kopie
    edit:SetTextColor(0, 0, 0, 0)
    local colored = edit:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colored:SetPoint("TOPLEFT", edit, "TOPLEFT", 0, 0)
    colored:SetWidth(LEFT_W - 34)
    colored:SetJustifyH("LEFT")
    colored:SetJustifyV("TOP")
    colored:SetWordWrap(true)
    ui.colored = colored
    edit:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            ns.state.manualBody = self:GetText()
            ns.Refresh()
        end
        colored:SetText(ns.Highlight(self:GetText()))
        self:SetHeight(math.max(scroll:GetHeight(), colored:GetStringHeight() + 8))
        scroll:UpdateScrollChildRect()
    end)
    scroll:SetScript("OnSizeChanged", function(self)
        local w = math.max(self:GetWidth(), 50)
        edit:SetWidth(w)
        colored:SetWidth(w)
        edit:SetHeight(math.max(self:GetHeight(), colored:GetStringHeight() + 8))
    end)
    edit:SetScript("OnEscapePressed", edit.ClearFocus)
    -- Der echte Cursor hat die (unsichtbare) Textfarbe, deshalb einen eigenen blinkenden zeichnen
    local caret = edit:CreateTexture(nil, "OVERLAY")
    caret:SetColorTexture(1, 1, 1, 1)
    caret:SetSize(1.5, 12)
    caret:Hide()
    local blink = 0
    edit:SetScript("OnUpdate", function(self, elapsed)
        if not self:HasFocus() then
            caret:Hide()
            return
        end
        blink = blink + elapsed
        if blink >= 1 then blink = 0 end
        caret:SetShown(blink < 0.55)
    end)
    edit:SetScript("OnEditFocusGained", function() blink = 0 end)
    edit:SetScript("OnEditFocusLost", function() caret:Hide() end)
    edit:SetScript("OnCursorChanged", function(self, x, y, _, h)
        caret:ClearAllPoints()
        caret:SetPoint("TOPLEFT", self, "TOPLEFT", x, y)
        caret:SetHeight(math.max(h or 12, 8))
        blink = 0 -- nach jeder Eingabe wieder sichtbar
        -- Cursor im sichtbaren Bereich halten
        local top, view = scroll:GetVerticalScroll(), scroll:GetHeight()
        y = -y
        if y < top then
            scroll:SetVerticalScroll(y)
        elseif y + h > top + view then
            scroll:SetVerticalScroll(y + h - view)
        end
    end)
    -- Klick irgendwo in den Kasten setzt den Cursor in den Text
    previewBox:EnableMouse(true)
    previewBox:SetScript("OnMouseDown", function() edit:SetFocus() end)

    ui.regen = TextButton(previewBox, L["Neu erzeugen"], 90, 18)
    ui.regen:SetPoint("BOTTOMRIGHT", previewBox, "BOTTOMRIGHT", -26, 3)
    ui.regen:SetScript("OnClick", function()
        ns.state.manualBody = nil
        edit:ClearFocus()
        ns.Refresh()
    end)

    ui.warning = f:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
    ui.warning:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", LEFT_X, 38)
    ui.warning:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -(RIGHT_W + 28), 38)
    ui.warning:SetJustifyH("LEFT")
    ui.warning:SetJustifyV("BOTTOM")

    -- Fenstergroesse (Breite und Hoehe) ueber die Griffe aendern
    -- Zwei Griffe: einer an der Ecke des Textkastens, einer unten rechts im Fenster
    local function MakeGrip(parent, anchorTo, x, y)
        local grip = CreateFrame("Button", nil, parent)
        grip:SetSize(18, 18)
        grip:SetFrameLevel(parent:GetFrameLevel() + 10)
        grip:SetPoint("BOTTOMRIGHT", anchorTo, "BOTTOMRIGHT", x, y)
        local bg = grip:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(1, 0.82, 0, 0.35) -- sichtbar, auch wenn das Symbol fehlt
        grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        -- Eigene Groessenaenderung per Mausposition (StartSizing war unzuverlaessig)
        grip:SetScript("OnMouseDown", function()
            local left, top = f:GetLeft(), f:GetTop()
            if left and top then -- Oberkante festhalten, nur die Unterkante wandert
                f:ClearAllPoints()
                f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
            end
            local startX, startY = GetCursorPosition()
            local startW, startH, scale = f:GetWidth(), f:GetHeight(), f:GetEffectiveScale()
            f:SetScript("OnUpdate", function()
                local x, y = GetCursorPosition()
                local w = startW + (x - startX) / scale
                local h = startH + (startY - y) / scale
                f:SetSize(math.min(math.max(w, MIN_W), MAX_W), math.min(math.max(h, MIN_H), MAX_H))
            end)
        end)
        grip:SetScript("OnMouseUp", function()
            f:SetScript("OnUpdate", nil)
            ui.saveWindow()
            ns.Refresh()
        end)
        grip:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(L["Ziehen: Fenster und Makrotext größer/kleiner machen"])
            GameTooltip:Show()
        end)
        grip:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return grip
    end
    MakeGrip(f, f, -4, 4)
    MakeGrip(previewBox, previewBox, -1, 1)

    local create = TextButton(f, L["Makro erstellen/speichern"], 172)
    create:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", LEFT_X, 12)
    create:SetScript("OnClick", function() ns.WriteMacro() end)

    local pickup = TextButton(f, L["Auf Leiste"], 74)
    pickup:SetPoint("LEFT", create, "RIGHT", 4, 0)
    pickup:SetScript("OnClick", function() ns.PickupMacro() end)

    local clear = TextButton(f, L["Leeren"], 50)
    clear:SetPoint("LEFT", pickup, "RIGHT", 4, 0)
    clear:SetScript("OnClick", function() ns.ClearSteps() end)

    -- Unten rechts: gespeicherte Kombinationen --------------------------------
    Label(right, L["Gespeichert"], 0, -312 + BOTTOM)
    -- Reiter: alle globalen Makros / nur Makros dieses Charakters
    ui.tabs = {}
    local function MakeTab(scope, w, x)
        local b = TextButton(right, scope, w, 20)
        b:SetPoint("TOPLEFT", right, "TOPLEFT", x, -308 + BOTTOM)
        b:SetScript("OnClick", function()
            ui.savedOffset = 0
            ns.db.savedTab = scope
            ns.Refresh()
        end)
        ui.tabs[scope] = b
    end
    MakeTab("global", 100, 90)
    MakeTab("char", 104, 194)
    local saved = Box(right, 0, -334 + BOTTOM, RIGHT_W, SAVED_ROWS * SAVED_H + 6)
    ui.savedEmpty = saved:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    ui.savedEmpty:SetPoint("CENTER")
    ui.savedEmpty:SetText(L["Keine Makros"])
    ui.savedRows = {}
    for i = 1, SAVED_ROWS do ui.savedRows[i] = CreateSavedRow(saved, i) end
    saved:EnableMouseWheel(true)
    saved:SetScript("OnMouseWheel", function(_, delta)
        ui.savedOffset = ui.savedOffset - delta
        ns.Refresh()
    end)
    local hint = Label(right, L["Klick lädt die Kombination, das rote Symbol löscht die Vorlage. Grau = Makro ohne Vorlage, Klick lädt den Text zum Bearbeiten. Dunkelgrau = fremdes Makro, wird beim Speichern direkt geändert."], 0, -478 + BOTTOM, "GameFontDisableSmall")
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
    ui.macroIcon:SetTexture(steps[1] and steps[1].icon or 134400) -- 134400 = Fragezeichen

    for _, sync in ipairs(ui.syncs) do sync() end
    local autoMode = opts.mode == "auto"
    local sequenceMode = autoMode and ns.DetectKind(steps) == "sequence"
    if not autoMode or #steps == 0 then
        ui.detected:SetText("")
    elseif sequenceMode then
        ui.detected:SetText(L["Erkannt: Cast-Sequenz"])
    else
        ui.detected:SetText(L["Erkannt: einfacher Cast"])
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
    local manual = state.manualBody
    if manual then
        body = manual
        warnings = { L["Von Hand bearbeitet: Optionen ändern den Text nicht mehr. \"Neu erzeugen\" setzt ihn zurück."] }
        if state.foreign then
            warnings = { L["Fremdes Makro: Speichern ändert es direkt im Spiel (ohne Kennung)."] }
        elseif not ns.IsOurMacro(body) then
            warnings[2] = L["Kennung "] .. ns.MARKER .. L[" fehlt, wird beim Speichern angehängt."]
        end
    end
    ui.regen:SetShown(manual ~= nil and not state.foreign)
    if ui.preview:GetText() ~= body then ui.preview:SetText(body) end
    local len = #body
    -- Fremde Makros bleiben bei 255; eigene duerfen ueber die Verlaengerung (/click) bis ns.LONG_MAX
    local limit = state.foreign and ns.MAX_MACRO_LEN or ns.LONG_MAX
    ui.counter:SetText(len .. "/" .. ((len > ns.MAX_MACRO_LEN and not state.foreign) and ns.LONG_MAX or ns.MAX_MACRO_LEN))
    if len > limit then
        ui.counter:SetTextColor(1, 0.2, 0.2)
    elseif len > ns.MAX_MACRO_LEN then
        ui.counter:SetTextColor(0.4, 0.8, 1) -- verlaengert
    else
        ui.counter:SetTextColor(1, 1, 1)
    end
    ui.warning:SetText(table.concat(warnings, "\n"))

    local tab = (ns.db.savedTab == "char") and "char" or "global"
    local lists = { global = ns.ListEntries("global"), char = ns.ListEntries("char") }
    local entries = lists[tab]
    for scope, button in pairs(ui.tabs) do
        local label = (scope == "global" and "Global" or L["Dieser Charakter"]) .. " (" .. #lists[scope] .. ")"
        if scope == tab then
            button:SetText("|cffffd100" .. label .. "|r")
            button:Disable()
        else
            button:SetText(label)
            button:Enable()
        end
    end
    local maxOffset = math.max(0, #entries - SAVED_ROWS)
    ui.savedOffset = math.min(math.max(ui.savedOffset, 0), maxOffset)
    for i = 1, SAVED_ROWS do
        local row, entry = ui.savedRows[i], entries[i + ui.savedOffset]
        row.savedName = entry and entry.name
        row.hasTemplate = entry and entry.hasTemplate
        row.macroIndex = entry and entry.index
        row.foreign = entry and entry.foreign
        if entry then
            if entry.foreign then
                row.text:SetText("|cff888888" .. entry.name .. L[" (fremd)|r"])
            elseif not entry.hasTemplate then
                row.text:SetText("|cffaaaaaa" .. entry.name .. L[" (nur Makro)|r"])
            elseif entry.inGame then
                row.text:SetText(entry.name .. L[" |cff40ff40(im Spiel)|r"])
            else
                row.text:SetText(entry.name)
            end
            if entry.long then -- Makro-Verlaengerung (Text laeuft ueber Zusatzschaltflaechen)
                row.text:SetText(row.text:GetText() .. " |cff66ccff[+" .. entry.long .. "]|r")
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

-- Fenster nur anzeigen (nie schliessen), z. B. aus dem Optionen-Eintrag
function ns.ShowWindow()
    if not ns.state then return end
    if not ui.frame then CreateUI() end
    if not ui.frame:IsShown() then
        ns.Refresh()
        ui.frame:Show()
    end
end
