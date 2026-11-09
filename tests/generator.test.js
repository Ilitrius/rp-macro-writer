// Prueft Generator.lua in einer Lua-VM (fengari) und kompiliert alle Lua-Dateien als Syntaxpruefung.
// Aufruf:  cd tests && npm install && npm test
const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');

const root = path.join(__dirname, '..');
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);

for (const file of ['Generator.lua', 'Core.lua', 'UI.lua']) {
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
local ns = chunk("MakroWriter", {})
local fails = 0
local function case(title, steps, patch, expected, expectedWarnings)
  local opts = ns.NewOpts()
  for k, v in pairs(patch) do opts[k] = v end
  local body, warnings = ns.BuildMacro(steps, opts)
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
  { focusMouseover = true, target = "focus", startAttack = true },
  "#showtooltip\\n/focus [@mouseover,harm,nodead]\\n/cast [@focus,harm,nodead][harm,nodead] Verderbnis\\n/startattack [@focus,harm,nodead][harm,nodead]", 0)
case("Fokus: ohne Bedingungen braucht exists", { dots[1] },
  with(any, { focusMouseover = true, target = "focus", showTooltip = false }),
  "/focus [@mouseover,exists]\\n/cast [@focus,exists][] Verderbnis", 0)
case("Angriff: ohne Bedingungen bleibt schlicht", { dots[1] },
  with(any, { startAttack = true, showTooltip = false, noChannel = true }),
  "/cast [nochanneling] Verderbnis\\n/startattack", 0)
case("Angriff: nach Sequenz, nochanneling gilt nicht fuer den Angriff", dots,
  { startAttack = true, noChannel = true, showTooltip = false },
  "/castsequence [harm,nodead,nochanneling] reset=target/combat " .. list .. "\\n/startattack [harm,nodead]", 0)

-- Sequenz-Optionen
case("Sequenz: Sekunden-Reset, Begleiter, Auto-Ziel", dots,
  { resetSeconds = 6, petAttack = true, autoTarget = true },
  "#showtooltip\\n/targetenemy [noharm][dead]\\n/petattack\\n/castsequence [harm,nodead] reset=target/combat/6 " .. list)
case("Sequenz: Mouseover ohne Reset", dots,
  { resetTarget = false, resetCombat = false, target = "mouseover", showTooltip = false },
  "/castsequence [@mouseover,harm,nodead][harm,nodead] " .. list)
case("Sequenz: ohne Bedingungen", dots, with(any, { resetCombat = false }),
  "#showtooltip\\n/castsequence reset=target " .. list)
case("Sequenz: nicht kanalisierend", dots, with(any, { noChannel = true }),
  "#showtooltip\\n/castsequence [nochanneling] reset=target/combat " .. list)

-- Andere Arten
case("Zufall mit Fokus", dots, { mode = "random", target = "focus" },
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
  with(any, { mode = "modifier", target = "mouseover", showTooltip = false }),
  "/cast [mod:shift,@mouseover,exists][mod:shift] Fluch der Elemente; [@mouseover,exists][] Fluch der Pein", 0)
case("Zeilen mit Gegenstand", { dots[1], { kind = "item", name = "Gesundheitsstein" } },
  with(any, { mode = "lines", showTooltip = false }),
  "/cast Verderbnis\\n/use Gesundheitsstein", 1)
case("Leer", {}, {}, "", 0)

local long = {}
for i = 1, 10 do long[i] = { kind = "spell", name = "Ein ziemlich langer Zaubername " .. i } end
local body, w = ns.BuildMacro(long, ns.NewOpts())
if #body <= 255 or #w ~= 1 then fails = fails + 1; print("FAIL Laengenwarnung") else print("OK   Laengenwarnung bei " .. #body .. " Zeichen") end
return fails
`;
lua.lua_pushstring(L, to_luastring(fs.readFileSync(path.join(root, 'Generator.lua'), 'utf8')));
lua.lua_setglobal(L, to_luastring('GEN'));
if (lauxlib.luaL_dostring(L, to_luastring(harness)) !== lua.LUA_OK) {
  console.log('LAUFZEITFEHLER', to_jsstring(lua.lua_tostring(L, -1)));
  process.exitCode = 1;
} else {
  const fails = lua.lua_tointeger(L, -1);
  console.log(fails === 0 ? 'ALLE TESTS OK' : fails + ' TEST(S) FEHLGESCHLAGEN');
  if (fails) process.exitCode = 1;
}
