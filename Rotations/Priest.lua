-- Rotations/Priest.lua – Rotation fuer Priester (PRIEST), Rueckfall fuer "Beste Rotation".
--
-- STATUS: unverified
--   unverified      = Zauber-IDs aus dem Gedaechtnis eingetragen, weder im Spiel noch im Wiki geprueft
--   helper-matched  = deckt sich mit dem Dump der Blizzard-Rotationshilfe ("/mw rotation", siehe unten)
--   game-verified   = vom Nutzer im Spiel geprueft
--
-- WIE DIE ROTATION ENTSTEHT
--   1. Erste Quelle im Addon ist die Rotationshilfe des Spiels (C_AssistedCombat.GetRotationSpells), siehe Core.lua.
--   2. Diese Datei ist der Rueckfall, falls die Hilfe nichts liefert. "dots" = Aufbau/Dauerschaden in dieser
--      Reihenfolge, "fillers" = Fuellzauber (der erste bekannte wird ns.FILLER_REPEAT-mal ans Ende gesetzt).
--   3. Welche Zauber der Charakter kennt, entscheidet das Spiel (Level, Talente, Spezialisierung).
--   4. Nachvollziehen/Erneuern: "/mw rotation" auf einem Charakter dieser Klasse ausfuehren; der Dump landet in
--      SavedVariables/rp-macro-writer.lua unter rotationDump. Der Agent "rotation-helper" gleicht ihn mit dieser
--      Datei ab und aktualisiert sie.
--
-- AENDERUNGSVERLAUF
--   2026-11-11  Ausgangsstand aus der Sammeltabelle uebernommen (unverified).
--   2026-11-11  Neu aufgebaut mit Varianten retail (Shadow, Midnight 12.1.5; Method + Noxxic) und classic
--               (Classic/Forever, Shadow-Levelrotation; Icy Veins/Noob to Boss). Kein Dump vorhanden. unverified.
--   2026-11-11  classic.trees fuer Disziplin/Heilig/Schatten (Leveln, Schaden-Makro; Noob to Boss, Icy Veins). Keine Baender. unverified.
local ADDON, ns = ...

ns.RegisterRotation("PRIEST", {
    status = "unverified",
    updated = "2026-11-11",
    source = "Method + Noxxic (Retail 12.1.5), Icy Veins + Noob to Boss (Classic); kein Dump der Rotationshilfe",
    retail = {
        sources = {
            "https://www.method.gg/guides/shadow-priest/playstyle-and-rotation (Retail 12.1.5, Shadow, 2026-11-11)",
            "https://www.noxxic.com/wow/guide/shadow-priest/dps-rotation-and-cooldowns (Retail 12.1.5, SimC-Liste, 2026-11-11)",
        },
        comparison = "Method und Noxxic stimmen ueberein: Vampiric Touch halten, Shadow Word: Madness, Mind Blast, Mind Flay als Fueller. Shadow Word: Pain nur mit Invoked Nightmare, daher nicht aufgenommen. Kein Dump der Rotationshilfe vorhanden.",
        dots = {
            { 34914, "Vampiric Touch" },
            { 335467, "Shadow Word: Madness" },
            { 8092, "Mind Blast" },
        },
        fillers = {
            { 15407, "Mind Flay" },
        },
    },
    classic = {
        trees = {
            [1] = {
                name = "Discipline",
                sources = {
                    "https://noobtoboss.com/?p=5402 (Classic Discipline Leveling 1-60, Auszug 2026-11-11)",
                    "https://www.icy-veins.com/wow-classic/discipline-priest-leveling-talent-build-from-1-to-60 (Classic; Seite per Abruf gesperrt, nur Suchauszug)",
                },
                comparison = "Disziplin hat keinen eigenen Schadenszauber; Quellen: Holy Fire als Eroeffnung (ab Stufe 20), Shadow Word: Pain wenn das Ziel lange lebt, 1-2 Smite, dann Zauberstab (Zauberstab nicht per Makro). Vor Stufe 20 nur Smite/Mind Blast (Bekannt-Filter). Reihenfolge der Registerkarten (Disziplin, Heilig, Schatten) ist Standard in Classic, nicht per Wowhead-Rechner belegt (Seite lieferte keinen Text). Rang-1-IDs 14914/589/585 nur teils per Wowhead /classic/spell= bestaetigt. Kein Dump.",
                dots = {
                    { 14914, "Holy Fire" },
                    { 589, "Shadow Word: Pain" },
                },
                fillers = {
                    { 585, "Smite" },
                },
            },
            [2] = {
                name = "Holy",
                sources = {
                    "https://noobtoboss.com/?p=5398 (Classic Priest Leveling, Auszug 2026-11-11)",
                    "https://www.icy-veins.com/wow-classic/holy-priest-leveling-talent-build-from-1-to-60 (Classic; Seite per Abruf gesperrt, nur Suchauszug)",
                },
                comparison = "Heilig: Spirit wird zu Zauberkraft, daher Holy Fire + Smite als Leveln-Schaden; Shadow Word: Pain als Dauerschaden. Die Quellen geben fuer Heilig/Disziplin dasselbe Muster an (Holy Fire oder Mind Blast, SW:Pain, Smite, Zauberstab). Heilzauber gehoeren nicht in dieses Schadensmakro. Wowhead-Heiliggerleveling-Guide lieferte keinen Text.",
                dots = {
                    { 14914, "Holy Fire" },
                    { 589, "Shadow Word: Pain" },
                },
                fillers = {
                    { 585, "Smite" },
                },
            },
            [3] = {
                name = "Shadow",
                sources = {
                    "https://noobtoboss.com/?p=5398 (Classic Priest Leveling, Auszug 2026-11-11: Shield, Mind Blast, SW:Pain, Mind Flay)",
                    "https://icy-veins.com/wow-classic/shadow-priest-leveling-talent-build-from-1-to-60 (Classic, nur Suchauszug)",
                },
                comparison = "Beide: Shadow Word: Pain, Mind Blast, Mind Flay bis zum Tod, Zauberstab bei wenig Mana. Mind Flay ist Talent (bei Stufe unter Talentkauf vom Bekannt-Filter ausgelassen, dann Smite). Power Word: Shield bewusst nicht aufgenommen (Selbstziel, Platz). Keine Stufenbaender: Quellen nennen keine Aenderung der Zauberreihenfolge, nur Talentkauf.",
                dots = {
                    { 589, "Shadow Word: Pain" },
                    { 8092, "Mind Blast" },
                },
                fillers = {
                    { 15407, "Mind Flay" },
                    { 585, "Smite" },
                },
            },
        },
        sources = {
            "https://www.icy-veins.com/wow-classic/shadow-priest-leveling-talent-build-from-1-to-60 (Classic, nur Suchauszug)",
            "https://noobtoboss.com/?p=5409 (Classic Shadow Leveling, nur Suchauszug)",
        },
        comparison = "Beide: Mind Blast, Shadow Word: Pain, Mind Flay, dann Wand/Smite. IDs 585/589 auf Wowhead classic geprueft. Quellen nur aus Suchauszuegen, schwach belegt; kein Dump.",
        dots = {
            { 589, "Shadow Word: Pain" },
            { 8092, "Mind Blast" },
        },
        fillers = {
            { 15407, "Mind Flay" },
            { 585, "Smite" },
        },
    },
    dots = {
        { 589, "Shadow Word: Pain" },
        { 8092, "Mind Blast" },
    },
    fillers = {
        { 15407, "Mind Flay" },
        { 585, "Smite" },
    },
})
