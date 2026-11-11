// Prueft Generator.lua in einer Lua-VM (fengari) und kompiliert alle Lua-Dateien als Syntaxpruefung.
// Aufruf:  cd tests && npm install && npm test
const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');

const root = path.join(__dirname, '..');
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);

for (const file of ['Locales.lua', 'Generator.lua', 'Rotations.lua', 'Core.lua', 'UI.lua', 'Minimap.lua']) {
  const src = fs.readFileSync(path.join(root, file));
  const status = lauxlib.luaL_loadbuffer(L, src, src.length, to_luastring('@' + file));
  if (status !== lua.LUA_OK) {
    console.log('SYNTAXFEHLER', file, to_jsstring(lua.lua_tostring(L, -1)));
    process.exitCode = 1;
  } else {
    console.log('Syntax ok:', file);
  }
  lua.lua_pop(L, 1);
}

const harness = `
local chunk = assert(load(GEN, "@Generator.lua"))
local ns = chunk("rp-macro-writer", {})
local fails = 0
local function case(title, steps, patch, expected, expectedWarnings)
  local opts = ns.NewOpts()
  for k, v in pairs(patch) do opts[k] = v end
  local body, warnings = ns.BuildMacro(steps, opts)
  if expected ~= "" then expected = expected .. "\\n" .. ns.MARKER end
  local ok = body == expected and (expectedWarnings == nil or #warnings == expectedWarnings)
  if not ok then
    fails = fails + 1
    print("FAIL " .. title .. "\\n  erwartet:\\n" .. expected .. "\\n  erhalten (" .. #warnings .. " Warnungen):\\n" .. body)
  else
    print("OK   " .. title)
  end
end

local any = { hostility = "any", life = "any" }
local function with(base, extra)
  local t = {}
  for k, v in pairs(base) do t[k] = v end
  for k, v in pairs(extra) do t[k] = v end
  return t
end
local dots = {
  { kind = "spell", name = "Verderbnis" },
  { kind = "spell", name = "Fluch der Pein" },
  { kind = "spell", name = "Feuerbrand" },
}
local list = "Verderbnis, Fluch der Pein, Feuerbrand"

-- Automatik
case("Auto: ein Zauber = einfacher Cast", { dots[1] }, {},
  "#showtooltip\\n/cast [harm,nodead] Verderbnis", 0)
case("Auto: mehrere Zauber = Cast-Sequenz mit Reset", dots, {},
  "#showtooltip\\n/castsequence [harm,nodead] reset=target/combat " .. list, 0)
case("Auto: ein Gegenstand = /use", { { kind = "item", name = "Gesundheitsstein" } }, any,
  "#showtooltip\\n/use Gesundheitsstein", 0)
case("Auto: Freund und tot", { { kind = "spell", name = "Wiederbelebung" } },
  { hostility = "help", life = "dead", showTooltip = false },
  "/cast [help,dead] Wiederbelebung", 0)

-- Fokus auf Mouseover und Angriff starten
case("Fokus: Mouseover als Fokus, Fokus als Ziel, Angriff am Ende", { dots[1] },
  { focusMouseover = true, target = "focus", startAttack = true, fallbackTarget = true },
  "#showtooltip\\n/focus [@mouseover,harm,nodead][]\\n/cast [@focus,harm,nodead][harm,nodead] Verderbnis\\n/startattack [@focus,harm,nodead][harm,nodead]", 0)
-- Beispiel des Nutzers: Fokus setzen und anvisieren, Begleiter, Ziel des Ziels als Rueckfall
case("Beispiel: Fokus, anvisieren, Begleiter, Ziel des Ziels, Angriff",
  { dots[1], dots[3] },
  { focusMouseover = true, targetFocus = true, petAttack = true, targetTarget = true,
    startAttack = true, resetTarget = false, resetCombat = false, showTooltip = false },
  "/focus [@mouseover,harm,nodead][]\\n/target focus\\n/petattack\\n/castsequence [harm,nodead,exists][@targettarget,harm,nodead,exists][@target] Verderbnis, Feuerbrand\\n/startattack [harm,nodead]", 0)
case("Ziel des Ziels: einfacher Cast, Freund ohne Bedingung braucht exists", { dots[1] },
  with(any, { targetTarget = true, showTooltip = false }),
  "/cast [][@targettarget,exists][@target] Verderbnis", 0)
case("Fokus: ohne Bedingungen braucht exists", { dots[1] },
  with(any, { focusMouseover = true, target = "focus", showTooltip = false, fallbackTarget = true }),
  "/focus [@mouseover,exists][]\\n/cast [@focus,exists][] Verderbnis", 0)
case("Angriff: ohne Bedingungen bleibt schlicht", { dots[1] },
  with(any, { startAttack = true, showTooltip = false, noChannel = true }),
  "/cast [nochanneling] Verderbnis\\n/startattack", 0)
case("Angriff: nach Sequenz, nochanneling gilt nicht fuer den Angriff", dots,
  { startAttack = true, noChannel = true, showTooltip = false },
  "/castsequence [harm,nodead,nochanneling] reset=target/combat " .. list .. "\\n/startattack [harm,nodead]", 0)

case("Fokus ohne Rueckfall: Bedingung steht nur einmal", { dots[1] }, { target = "focus", showTooltip = false },
  "/cast [@focus,harm,nodead] Verderbnis", 0)
case("Mouseover ohne Rueckfall, Sequenz", dots, { target = "mouseover", showTooltip = false, resetTarget = false, resetCombat = false },
  "/castsequence [@mouseover,harm,nodead] " .. list, 0)
case("Aktuelles Ziel: Rueckfall-Option aendert nichts", { dots[1] }, { target = "target", fallbackTarget = true, showTooltip = false },
  "/cast [harm,nodead] Verderbnis", 0)

case("Vorlage des Nutzers: Ziel des Ziels mit exists, Reset nach 2 Sekunden",
  { { kind = "spell", name = "Finsterer Stoß" }, { kind = "spell", name = "Meucheln" } },
  { targetTarget = true, resetTarget = false, resetCombat = false, resetSeconds = 2, showTooltip = false },
  "/castsequence [harm,nodead,exists][@targettarget,harm,nodead,exists][@target] reset=2 Finsterer Stoß, Meucheln", 0)

-- Sequenz-Optionen
case("Sequenz: Sekunden-Reset, Begleiter, Auto-Ziel", dots,
  { resetSeconds = 6, petAttack = true, autoTarget = true },
  "#showtooltip\\n/targetenemy [noharm][dead]\\n/petattack\\n/castsequence [harm,nodead] reset=target/combat/6 " .. list)
case("Sequenz: Mouseover ohne Reset", dots,
  { resetTarget = false, resetCombat = false, target = "mouseover", showTooltip = false, fallbackTarget = true },
  "/castsequence [@mouseover,harm,nodead][harm,nodead] " .. list)
case("Sequenz: ohne Bedingungen", dots, with(any, { resetCombat = false }),
  "#showtooltip\\n/castsequence reset=target " .. list)
case("Sequenz: nicht kanalisierend", dots, with(any, { noChannel = true }),
  "#showtooltip\\n/castsequence [nochanneling] reset=target/combat " .. list)

-- Andere Arten
case("Zufall mit Fokus", dots, { mode = "random", target = "focus", fallbackTarget = true },
  "#showtooltip\\n/castrandom [@focus,harm,nodead][harm,nodead] " .. list)
local mods = {
  { kind = "spell", name = "Fluch der Pein" },
  { kind = "spell", name = "Fluch der Elemente", mod = "shift" },
  { kind = "spell", name = "Fluch der Sprachen", mod = "ctrl" },
  { kind = "spell", name = "Fluch der Schwäche", mod = "shift" },
  { kind = "spell", name = "Verderbnis" },
}
case("Zusatztaste: doppelte und ueberzaehlige werden gemeldet", mods, { mode = "modifier" },
  "#showtooltip\\n/cast [mod:shift,harm,nodead] Fluch der Elemente; [mod:ctrl,harm,nodead] Fluch der Sprachen; [harm,nodead] Fluch der Pein", 2)
case("Zusatztaste: Mouseover ohne Bedingungen braucht exists", { mods[1], mods[2] },
  with(any, { mode = "modifier", target = "mouseover", showTooltip = false, fallbackTarget = true }),
  "/cast [mod:shift,@mouseover,exists][mod:shift] Fluch der Elemente; [@mouseover,exists][] Fluch der Pein", 0)
case("Zeilen mit Gegenstand", { dots[1], { kind = "item", name = "Gesundheitsstein" } },
  with(any, { mode = "lines", showTooltip = false }),
  "/cast Verderbnis\\n/use Gesundheitsstein", 1)
case("Leer", {}, {}, "", 0)

local long = {}
for i = 1, 10 do long[i] = { kind = "spell", name = "Ein ziemlich langer Zaubername " .. i } end
local body, w = ns.BuildMacro(long, ns.NewOpts())
if #body <= 255 or #w ~= 1 then fails = fails + 1; print("FAIL Laengenwarnung") else print("OK   Laengenwarnung bei " .. #body .. " Zeichen") end

local marked = ns.IsOurMacro("#showtooltip\\n/cast X\\n#rpmw") and not ns.IsOurMacro("/cast X\\n#rpmwx")
  and not ns.IsOurMacro("/say #rpmw") and not ns.IsOurMacro(nil)
if marked then print("OK   Kennung wird erkannt, Aehnliches nicht") else fails = fails + 1; print("FAIL Kennung") end
local np = (not ns.NameProblem("Feuerball", "cast")) and ns.NameProblem("A[B]", "cast")
  and ns.NameProblem("A\\nB", "cast") and (not ns.NameProblem("A,B", "cast"))
  and ns.NameProblem("A,B", "sequence") and ns.NameProblem("A,B", "random")
  and ns.NameProblem("A;B", "modifier") and (not ns.NameProblem("A;B", "sequence"))
if np then print("OK   Namen mit Sonderzeichen") else fails = fails + 1; print("FAIL Namen mit Sonderzeichen") end

local function strip(s) return (s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("||", "|")) end
local sample = "#showtooltip\\n/castsequence [@mouseover,harm,nodead][mod:shift] reset=target/combat Verderbnis, Feuerbrand\\n\\n/startattack\\n#rpmw"
local hl = ns.Highlight(sample)
local hlOk = strip(hl) == sample and hl:find("|cff66ccff@mouseover|r", 1, true) and hl:find("|cff7fe07fharm|r", 1, true)
  and hl:find("|cffd19bffreset=target/combat|r", 1, true) and hl:find("|cffffa040/castsequence|r", 1, true)
  and ns.Highlight("") == "" and strip(ns.Highlight("/cast [x Foo|bar")) == "/cast [x Foo|bar"
if hlOk then print("OK   Syntaxfarben") else fails = fails + 1; print("FAIL Syntaxfarben: " .. hl) end

local o = ns.NewOpts()
local _, w1 = ns.BuildMacro({ { kind = "spell", name = "A,B" }, { kind = "spell", name = "C" } }, o)
local _, w2 = ns.BuildMacro({ { kind = "spell", name = "A,B" } }, o)
if #w1 == 1 and #w2 == 0 then print("OK   Namenswarnung in der Vorschau") else fails = fails + 1; print("FAIL Namenswarnung " .. #w1 .. "/" .. #w2) end
do
  local c = ns.Compact("#showtooltip\\n/castsequence [harm,nodead] reset=target/combat A, B, C\\n/cast [mod:shift] X; [harm] Y\\n#rpmw")
  local ok = c == "#showtooltip\\n/castsequence [harm,nodead] reset=target/combat A,B,C\\n/cast [mod:shift] X;[harm] Y\\n#rpmw"
  if ok then print("OK   Kuerzen") else fails = fails + 1; print("FAIL Kuerzen: " .. c) end
end
do
  local steps = { dots[1], dots[3] }
  for i = 1, 3 do steps[#steps + 1] = { kind = "spell", name = "Schattenblitz" } end
  local o2 = ns.NewOpts()
  o2.focusMouseover = true; o2.targetFocus = true; o2.petAttack = true; o2.startAttack = true; o2.target = "focus"; o2.fallbackTarget = true
  local b, w = ns.BuildMacro(steps, o2)
  if #b <= 255 and #w == 0 and b:find("\\n/tar focus\\n", 1, true) then print("OK   Gekuerzt auf " .. #b .. " Zeichen") else fails = fails + 1; print("FAIL Gekuerzt (" .. #b .. "):\\n" .. b) end
end
do
  local rotChunk = assert(load(ROT, "@Rotations.lua"))
  local rns = { MAX_STEPS = 10 }
  rotChunk("rp-macro-writer", rns)
  local known = { [980] = true, [172] = true, [686] = true, [348] = true }
  local ids = rns.PickRotation("WARLOCK", function(id) return known[id] end)
  local okW = ids and #ids == 3 + rns.FILLER_REPEAT and ids[1] == 980 and ids[#ids] == 686
  local none = rns.PickRotation("WARLOCK", function() return false end)
  local okN = none and #none == 0
  local okU = rns.PickRotation("NOCLASS", function() return true end) == nil
  local allClasses = true
  for _, c in ipairs({ "WARLOCK", "MAGE", "PRIEST", "HUNTER", "DRUID", "ROGUE", "WARRIOR", "PALADIN", "SHAMAN", "DEATHKNIGHT", "MONK", "DEMONHUNTER", "EVOKER" }) do
    local r = rns.PickRotation(c, function() return true end)
    if not r or #r < 2 then allClasses = false end
  end
  if okW and okN and okU and allClasses then print("OK   Rotationen") else fails = fails + 1; print("FAIL Rotationen") end
end
return fails
`;
lua.lua_pushstring(L, to_luastring(fs.readFileSync(path.join(root, 'Generator.lua'), 'utf8')));
lua.lua_setglobal(L, to_luastring('GEN'));
lua.lua_pushstring(L, to_luastring(fs.readFileSync(path.join(root, 'Rotations.lua'), 'utf8')));
lua.lua_setglobal(L, to_luastring('ROT'));
if (lauxlib.luaL_dostring(L, to_luastring(harness)) !== lua.LUA_OK) {
  console.log('LAUFZEITFEHLER', to_jsstring(lua.lua_tostring(L, -1)));
  process.exitCode = 1;
} else {
  const fails = lua.lua_tointeger(L, -1);
  console.log(fails === 0 ? 'ALLE TESTS OK' : fails + ' TEST(S) FEHLGESCHLAGEN');
  if (fails) process.exitCode = 1;
}
