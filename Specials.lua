-- Specials.lua: die Slash-Befehle /rp<Kuerzel> zu "Spezial einfuegen" (Liste: Inserts.lua, ns.SPECIALS).
-- Die eingefuegten Zeilen funktionieren nur, solange rp-macro-writer geladen ist.
-- Jede Funktion wird vor dem Aufruf geprueft: Forever (Classic-Basis) und Retail haben unterschiedliche API.
local ADDON, ns = ...
local L = ns.L

local function Say(msg) ns.Print(msg) end
local function Unavailable() Say(L["In dieser Spielversion nicht verfügbar."]) end

local function Send(msg, channel)
    local fn = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
    if fn then fn(msg, channel) end
end

-- ---------------------------------------------------------------------------
-- Taschen (Retail und neuere Classic-Clients: C_Container; aeltere: globale Funktionen)
-- ---------------------------------------------------------------------------
local POOR = (Enum and Enum.ItemQuality and Enum.ItemQuality.Poor) or 0

local function NumSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then return C_Container.GetContainerNumSlots(bag) or 0 end
    if GetContainerNumSlots then return GetContainerNumSlots(bag) or 0 end
    return 0
end

-- liefert Qualitaet, Anzahl, Link
local function ItemAt(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info then return info.quality, info.stackCount, info.hyperlink end
    elseif GetContainerItemInfo then
        local _, count, _, quality, _, _, link = GetContainerItemInfo(bag, slot)
        return quality, count, link
    end
end

local function UseItem(bag, slot)
    if C_Container and C_Container.UseContainerItem then C_Container.UseContainerItem(bag, slot)
    elseif UseContainerItem then UseContainerItem(bag, slot) end
end

local function PickupItem(bag, slot)
    if C_Container and C_Container.PickupContainerItem then C_Container.PickupContainerItem(bag, slot)
    elseif PickupContainerItem then PickupContainerItem(bag, slot) end
end

local function SellPrice(link)
    local info = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if not info then return 0 end
    return select(11, info(link)) or 0
end

-- Alle grauen Gegenstaende: Liste { bag, slot, count, link }
local function GreyItems()
    local list = {}
    local lastBag = (NUM_BAG_SLOTS or 4) + (NUM_REAGENTBAG_SLOTS or 0)
    for bag = 0, lastBag do
        for slot = 1, NumSlots(bag) do
            local quality, count, link = ItemAt(bag, slot)
            if quality == POOR and link then list[#list + 1] = { bag = bag, slot = slot, count = count or 1, link = link } end
        end
    end
    return list
end

-- ---------------------------------------------------------------------------
-- Die Befehle
-- ---------------------------------------------------------------------------
local H = {}

H.ce = function() if UIErrorsFrame then UIErrorsFrame:Clear() else Unavailable() end end
H.ex = function() if UIErrorsFrame then UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE") else Unavailable() end end
H.eo = function() if UIErrorsFrame then UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE") else Unavailable() end end

H.pet = function()
    if C_PetJournal and C_PetJournal.SummonRandomPet then C_PetJournal.SummonRandomPet(false)
    elseif SummonRandomCritter then SummonRandomCritter()
    else Unavailable() end
end

H.so = function() if SetCVar then SetCVar("Sound_EnableSFX", 1) else Unavailable() end end
H.sx = function() if SetCVar then SetCVar("Sound_EnableSFX", 0) else Unavailable() end end

H.rt = function(msg)
    local unit, marker = (msg or ""):match("^(%S+)%s+(%d+)")
    marker = tonumber(marker)
    if not unit or not marker or marker < 0 or marker > 8 then
        Say(L["Aufruf: /rprt Einheit Marker (0 bis 8)"])
    elseif SetRaidTarget then
        SetRaidTarget(unit, marker)
    else
        Unavailable()
    end
end

H.ev = function() if VehicleExit then VehicleExit() else Unavailable() end end

H.mc = function()
    local x, y
    if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
        local map = C_Map.GetBestMapForUnit("player")
        local pos = map and C_Map.GetPlayerMapPosition(map, "player")
        if pos then x, y = pos:GetXY() end
    elseif GetPlayerMapPosition then
        if SetMapToCurrentZone then SetMapToCurrentZone() end
        x, y = GetPlayerMapPosition("player")
    else
        return Unavailable()
    end
    if x and y and (x ~= 0 or y ~= 0) then
        Say(string.format("%.1f %.1f", x * 100, y * 100))
    else
        Say(L["Keine Position verfügbar."])
    end
end

H.tc = function()
    if ShowCloak and ShowingCloak then ShowCloak(not ShowingCloak()) else Unavailable() end
end
H.th = function()
    if ShowHelm and ShowingHelm then ShowHelm(not ShowingHelm()) else Unavailable() end
end

H.ep = function()
    if CanEjectPassengerFromSeat and EjectPassengerFromSeat then
        for seat = 1, 2 do
            if CanEjectPassengerFromSeat(seat) then EjectPassengerFromSeat(seat) end
        end
    else
        Unavailable()
    end
end

H.sg = function()
    if not (MerchantFrame and MerchantFrame:IsShown()) then return Say(L["Zuerst einen Händler öffnen."]) end
    local cash, sold = 0, 0
    for _, it in ipairs(GreyItems()) do
        local price = SellPrice(it.link)
        if price > 0 then
            cash = cash + price * it.count
            sold = sold + 1
            UseItem(it.bag, it.slot)
        end
    end
    local money = GetCoinTextureString and GetCoinTextureString(cash) or tostring(cash)
    Say(L["Graue Gegenstände verkauft: "] .. sold .. " (" .. money .. ")")
end

-- Loeschen nur nach Rueckfrage und nie im Kampf
local function DestroyGrey()
    if InCombatLockdown() then return Say(L["Im Kampf nicht möglich."]) end
    local deleted = 0
    for _, it in ipairs(GreyItems()) do
        PickupItem(it.bag, it.slot)
        if DeleteCursorItem then DeleteCursorItem() end
        if ClearCursor then ClearCursor() end
        deleted = deleted + 1
    end
    Say(L["Graue Gegenstände gelöscht: "] .. deleted)
end

StaticPopupDialogs["RPMW_DESTROY_GREY"] = {
    text = L["Alle grauen Gegenstände (%d) unwiderruflich löschen?"],
    button1 = YES or "Yes",
    button2 = NO or "No",
    OnAccept = DestroyGrey,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

H.dg = function()
    if InCombatLockdown() then return Say(L["Im Kampf nicht möglich."]) end
    local count = #GreyItems()
    if count == 0 then return Say(L["Keine grauen Gegenstände gefunden."]) end
    StaticPopup_Show("RPMW_DESTROY_GREY", count)
end

-- Essensbonus / Fläschchen melden. Die Namen der Auren sind sprachabhaengig; hinterlegt sind
-- Englisch und Deutsch (Quelle der Namen: das Add-on MacroToolkit), andere Sprachen nutzen die englischen.
local AURA_NAMES = {
    enUS = { fed = { "Well Fed", "Food" }, flask = { "Flask", "Distilled" } },
    deDE = { fed = { "Satt", "Essen" }, flask = { "Fläschchen", "destilliert" } },
}

local function AuraNames()
    return AURA_NAMES[GetLocale and GetLocale() or "enUS"] or AURA_NAMES.enUS
end

local function HasAura(unit, patterns)
    local function matches(name)
        for _, p in ipairs(patterns) do
            if name and name:find(p, 1, true) then return true end
        end
    end
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 40 do
            local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
            if not aura then return false end
            if matches(aura.name) then return true end
        end
    elseif UnitAura then
        for i = 1, 40 do
            local name = UnitAura(unit, i, "HELPFUL")
            if not name then return false end
            if matches(name) then return true end
        end
    end
    return false
end

local function GroupUnits()
    local units = {}
    local n = GetNumGroupMembers and GetNumGroupMembers() or 0
    if IsInRaid and IsInRaid() then
        for i = 1, n do units[#units + 1] = "raid" .. i end
    elseif n > 0 then
        units[1] = "player"
        for i = 1, n - 1 do units[#units + 1] = "party" .. i end
    end
    return units
end

local function ReportMissing(kind, title, channel)
    if InCombatLockdown() then return Say(L["Im Kampf nicht möglich."]) end
    if not (GetNumGroupMembers and UnitName) then return Unavailable() end
    local patterns = AuraNames()[kind]
    local missing = {}
    for _, unit in ipairs(GroupUnits()) do
        if UnitExists(unit) and not HasAura(unit, patterns) then missing[#missing + 1] = UnitName(unit) end
    end
    local list = #missing > 0 and table.concat(missing, " ") or (NONE or "-")
    local msg = string.sub(title .. ": " .. list, 1, 250)
    channel = (channel or ""):lower()
    if channel == "party" and IsInGroup and IsInGroup() then
        Send(msg, "PARTY")
    elseif channel ~= "chat" and channel ~= "party" and IsInRaid and IsInRaid() then
        Send(msg, "RAID")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff99cce6" .. msg .. "|r")
    end
end

H.nb = function(msg) ReportMissing("fed", L["Ohne Essensbonus"], (msg or ""):match("^%s*(%S+)")) end
H.nf = function(msg) ReportMissing("flask", L["Ohne Fläschchen"], (msg or ""):match("^%s*(%S+)")) end

H.fm = function()
    if C_MountJournal and C_MountJournal.SummonByID then C_MountJournal.SummonByID(0) else Unavailable() end
end

-- /rpp [Bedingung] [raid|party|guild|say|chat] Text   (%t Ziel, %f Fokus, %c Ziel der Bedingung)
H.p = function(msg)
    msg = msg or ""
    local ctarget
    local cond = msg:match("^(%b[])")
    if cond then
        if SecureCmdOptionParse then
            local result, unit = SecureCmdOptionParse(cond .. " go")
            if not result then return end
            ctarget = unit
        end
        msg = msg:sub(#cond + 1):gsub("^%s+", "")
    end
    local channel = msg:match("^(%a+)%s")
    local known = { raid = "RAID", party = "PARTY", guild = "GUILD", say = "SAY", chat = "CHAT" }
    channel = channel and known[channel:lower()]
    if channel then msg = msg:gsub("^%a+%s+", "") end
    msg = msg:gsub("%%(%a)", function(c)
        if c == "t" then return UnitName("target") or "" end
        if c == "f" then return UnitName("focus") or "" end
        if c == "c" then return ctarget and UnitName(ctarget) or "" end
    end)
    if channel and channel ~= "CHAT" then Send(msg, channel)
    else DEFAULT_CHAT_FRAME:AddMessage("|cff99cce6" .. msg .. "|r") end
end

-- ---------------------------------------------------------------------------
-- Registrierung. Befehle, die schon ein anderes Add-on belegt hat, werden uebersprungen und gemeldet.
-- ---------------------------------------------------------------------------
local function Taken(cmd)
    cmd = cmd:lower()
    for key in pairs(SlashCmdList) do
        for i = 1, 8 do
            local s = _G["SLASH_" .. key .. i]
            if not s then break end
            if s:lower() == cmd then return true end
        end
    end
end

local skipped = {}
for _, s in ipairs(ns.SPECIALS) do
    local cmd, key, handler = "/rp" .. s.code, "RPMWS_" .. s.code:upper(), H[s.code]
    if handler then
        if Taken(cmd) then
            skipped[#skipped + 1] = cmd
        else
            _G["SLASH_" .. key .. "1"] = cmd
            SlashCmdList[key] = function(msg) handler(msg or "") end
        end
    end
end

if #skipped > 0 then
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_LOGIN")
        Say(L["Befehle von einem anderen Add-on belegt, nicht angelegt: "] .. table.concat(skipped, " "))
    end)
end
