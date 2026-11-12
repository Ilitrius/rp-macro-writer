-- Options.lua: Eintrag unter "Optionen > AddOns". Ein Klick darauf oeffnet das Fenster des Add-ons.
-- Registrierung wie bei MacroToolkit im Forever-Client: Settings.RegisterCanvasLayoutCategory +
-- Settings.RegisterAddOnCategory; aeltere Clients: InterfaceOptions_AddCategory.
local ADDON, ns = ...
local L = ns.L

local opening = false

-- Optionen schliessen und das Fenster des Add-ons zeigen
function ns.OpenFromOptions()
    if opening then return end
    opening = true
    if SettingsPanel and SettingsPanel:IsShown() then
        if HideUIPanel then HideUIPanel(SettingsPanel) else SettingsPanel:Hide() end
    end
    if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then InterfaceOptionsFrame:Hide() end
    if ns.ShowWindow then ns.ShowWindow() end
    opening = false
end

local function CreatePanel()
    local panel = CreateFrame("Frame")
    panel.name = "rp-macro-writer"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
    title:SetText("rp-macro-writer")

    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetWidth(540)
    desc:SetJustifyH("LEFT")
    desc:SetText(L["Ein Klick auf diesen Eintrag öffnet das Fenster zum Erstellen von Makros. Du kannst es jederzeit auch mit /mw öffnen."])

    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetSize(180, 24)
    button:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -14)
    button:SetText(L["Fenster öffnen"])
    button:SetScript("OnClick", function() ns.OpenFromOptions() end)

    -- Wird der Eintrag gewaehlt, geht das Fenster auf; die Optionen schliessen danach (naechster Frame,
    -- damit sie nicht mitten im Anzeigen des Eintrags verschwinden)
    panel:SetScript("OnShow", function()
        if C_Timer and C_Timer.After then C_Timer.After(0, ns.OpenFromOptions) else ns.OpenFromOptions() end
    end)
    return panel
end

local function Register()
    local panel = CreatePanel()
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        ns.optionsCategory = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
        ns.optionsPanel = panel
    end
end

-- Optionen oeffnen und unseren Eintrag waehlen (z. B. fuer ein Menue); sonst einfach das Fenster zeigen
function ns.OpenOptions()
    if Settings and Settings.OpenToCategory and ns.optionsCategory and ns.optionsCategory.GetID then
        Settings.OpenToCategory(ns.optionsCategory:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory and ns.optionsPanel then
        InterfaceOptionsFrame_OpenToCategory(ns.optionsPanel)
    elseif ns.ShowWindow then
        ns.ShowWindow()
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local ok, err = pcall(Register)
    if not ok then ns.Print("Optionen-Eintrag konnte nicht angelegt werden: " .. tostring(err)) end
end)
