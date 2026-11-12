-- Inserts.lua: Daten und reine Textfunktionen fuer "Slot einfuegen" und "Spezial einfuegen".
-- Bewusst ohne WoW-API (auch beim Laden), damit alles ausserhalb des Spiels testbar ist.
-- Vorbild: die beiden Auswahllisten des Add-ons MacroToolkit (siehe docs/plan-spezial-slot-einfuegen.md).
local ADDON, ns = ...

-- Ausruestungsplaetze { Nummer, Name der Spiel-Konstante, englischer Rueckfall, Zusatz }.
-- Der Anzeigename kommt zur Laufzeit aus der Konstante (_G[...]) und ist damit in der Spielsprache.
ns.SLOTS = {
    { 1, "INVTYPE_HEAD", "Head" },
    { 2, "INVTYPE_NECK", "Neck" },
    { 3, "INVTYPE_SHOULDER", "Shoulder" },
    { 4, "INVTYPE_BODY", "Shirt" },
    { 5, "INVTYPE_CHEST", "Chest" },
    { 6, "INVTYPE_WAIST", "Waist" },
    { 7, "INVTYPE_LEGS", "Legs" },
    { 8, "INVTYPE_FEET", "Feet" },
    { 9, "INVTYPE_WRIST", "Wrist" },
    { 10, "INVTYPE_HAND", "Hands" },
    { 11, "INVTYPE_FINGER", "Finger", " 1" },
    { 12, "INVTYPE_FINGER", "Finger", " 2" },
    { 13, "INVTYPE_TRINKET", "Trinket", " 1" },
    { 14, "INVTYPE_TRINKET", "Trinket", " 2" },
    { 15, "INVTYPE_CLOAK", "Back" },
    { 16, "INVTYPE_WEAPONMAINHAND", "Main hand" },
    { 17, "INVTYPE_WEAPONOFFHAND", "Off hand" },
    { 18, "INVTYPE_RANGED", "Ranged" },
    { 19, "INVTYPE_TABARD", "Tabard" },
}

-- Spezialzeilen: eigene Slash-Befehle /rp<code> (Handler in Specials.lua).
--   name, tip   deutsche Texte (Schluessel in Locales.lua)
--   param       nil | "raidtarget" (Ziel + Marker) | "channel" (Raid/Party/Chat) | "text"
--   danger      true: loescht Daten, rot markiert und mit Rueckfrage im Spiel
ns.SPECIALS = {
    { code = "ce", name = "Fehlermeldungen löschen", tip = "Löscht die roten Fehlermeldungen oben im Bild." },
    { code = "ex", name = "Fehlermeldungen aus", tip = "Schaltet die roten Fehlermeldungen oben im Bild aus." },
    { code = "eo", name = "Fehlermeldungen an", tip = "Schaltet die roten Fehlermeldungen oben im Bild wieder an." },
    { code = "pet", name = "Zufälliges Begleiter-Haustier", tip = "Ruft ein zufälliges Begleiter-Haustier." },
    { code = "so", name = "Soundeffekte an", tip = "Schaltet die Soundeffekte an." },
    { code = "sx", name = "Soundeffekte aus", tip = "Schaltet die Soundeffekte aus." },
    { code = "rt", name = "Schlachtzugsmarker setzen", tip = "Setzt einen Schlachtzugsmarker auf eine Einheit (Ziel und Marker rechts darunter wählen).", param = "raidtarget" },
    { code = "ev", name = "Fahrzeug verlassen", tip = "Verlässt das Fahrzeug." },
    { code = "mc", name = "Kartenkoordinaten ausgeben", tip = "Schreibt deine Position auf der Karte in den Chat." },
    { code = "tc", name = "Umhang ein/aus", tip = "Zeigt oder versteckt den Umhang." },
    { code = "th", name = "Helm ein/aus", tip = "Zeigt oder versteckt den Helm." },
    { code = "ep", name = "Passagier auswerfen", tip = "Wirft Passagiere aus deinem Fahrzeug." },
    { code = "sg", name = "Graue Gegenstände verkaufen", tip = "Verkauft alle grauen Gegenstände an den geöffneten Händler." },
    { code = "dg", name = "Graue Gegenstände löschen (!)", tip = "ACHTUNG: Löscht alle grauen Gegenstände aus den Taschen, unwiderruflich. Vorher fragt das Spiel nach, nicht im Kampf.", danger = true },
    { code = "nb", name = "Ohne Essensbonus melden", tip = "Meldet Gruppenmitglieder ohne Essensbonus (Kanal rechts darunter wählen).", param = "channel" },
    { code = "nf", name = "Ohne Fläschchen melden", tip = "Meldet Gruppenmitglieder ohne Fläschchen (Kanal rechts darunter wählen).", param = "channel" },
    { code = "fm", name = "Zufälliges Lieblingsreittier", tip = "Ruft ein zufälliges Lieblingsreittier." },
    { code = "p", name = "Nachricht ausgeben", tip = "Schreibt eine Nachricht in den Chat. Den Text \"Text\" danach im Makrotext ersetzen.", param = "text" },
}

ns.SPECIAL_BY_CODE = {}
for _, s in ipairs(ns.SPECIALS) do ns.SPECIAL_BY_CODE[s.code] = s end

-- Die Zeile, die in das Makro eingefuegt wird. p = { target, marker, channel }
function ns.SpecialLine(code, p)
    p = p or {}
    local line = "/rp" .. code
    if code == "rt" then
        line = line .. " " .. (p.target or "target") .. " " .. (p.marker or 1)
    elseif (code == "nb" or code == "nf") and p.channel and p.channel ~= "raid" then
        line = line .. " " .. p.channel
    elseif code == "p" then
        line = line .. " " .. (p.text or "Text")
    end
    return line
end

-- ---------------------------------------------------------------------------
-- Cursor-Positionen: der Client zaehlt je nach Version Zeichen oder Bytes (im Spiel gemessen,
-- siehe UI.lua). Intern wird mit Byte-Positionen gerechnet; Umlaute sind 2 Bytes lang.
-- ---------------------------------------------------------------------------
local function CharLen(c)
    if c < 0x80 then return 1 elseif c < 0xE0 then return 2 elseif c < 0xF0 then return 3 end
    return 4
end

-- Zeichen-Position -> Byte-Position (Anzahl Bytes vor dem Cursor)
function ns.CharToByte(text, charPos)
    local bytes, chars, n = 0, 0, #text
    while chars < charPos and bytes < n do
        bytes = bytes + CharLen(text:byte(bytes + 1))
        chars = chars + 1
    end
    return math.min(bytes, n)
end

-- Byte-Position -> Zeichen-Position
function ns.ByteToChar(text, bytePos)
    local bytes, chars, n = 0, 0, #text
    bytePos = math.min(bytePos, n)
    while bytes < bytePos do
        bytes = bytes + CharLen(text:byte(bytes + 1))
        chars = chars + 1
    end
    return chars
end

-- Eine Byte-Position nie mitten in ein Zeichen fallen lassen
function ns.SnapByte(text, bytePos)
    bytePos = math.max(0, math.min(bytePos, #text))
    while bytePos > 0 do
        local c = text:byte(bytePos + 1)
        if c and c >= 0x80 and c < 0xC0 then bytePos = bytePos - 1 else break end
    end
    return bytePos
end

-- Fuegt text in body ein und liefert neuer Text, neue Byte-Position hinter dem Eingefuegten.
--   pos      Cursor als Byte-Position (0 = ganz vorn)
--   asLine   true: als eigene Zeile hinter der aktuellen Zeile; false: genau am Cursor
-- Regeln: nie hinter die Kennzeile #rpmw; nie vor die erste Zeile (ein fuehrendes #show bleibt oben).
function ns.InsertText(body, pos, text, asLine)
    body = body or ""
    if body == "" then return text, #text end
    pos = ns.SnapByte(body, pos or #body)

    -- Obergrenze: Ende der letzten Inhaltszeile vor der Kennzeile
    local limit = #body
    local markerFirst = false
    local nl = body:find("\n" .. ns.MARKER .. "%s*$")
    if nl then
        limit = nl - 1
    elseif body:match("^" .. ns.MARKER .. "%s*$") then
        markerFirst = true
    end

    if markerFirst then -- nur die Kennzeile da: davor einfuegen
        if asLine then return text .. "\n" .. body, #text end
        return text .. body, #text
    end

    if pos > limit then pos = limit end
    if not asLine then
        return body:sub(1, pos) .. text .. body:sub(pos + 1), pos + #text
    end
    local lineEnd = body:find("\n", pos + 1, true)
    lineEnd = lineEnd and (lineEnd - 1) or #body
    if lineEnd > limit then lineEnd = limit end
    return body:sub(1, lineEnd) .. "\n" .. text .. body:sub(lineEnd + 1), lineEnd + 1 + #text
end
