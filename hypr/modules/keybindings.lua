---------------------
---- KEYBINDINGS ----
---------------------

local programs = require("modules.programs")

-- "keybinds.lua" é GERADO por hypr/scripts/sync-hypr-keybinds.sh a partir
-- de quickshell/State/keybinds.json (Configurações > aba Atalhos) - não
-- existe até o usuário mexer em algum atalho pela primeira vez, por isso o
-- pcall (mesmo padrão de theme_colors.lua/window_radius.lua em
-- appearance.lua). Sem o arquivo (ou sem uma ação específica dentro dele),
-- cai nos valores hardcoded abaixo - são os mesmos atalhos de sempre,
-- viram só o "default" desse sistema agora.
local keybindsOk, keybindsData = pcall(require, "keybinds")
local mainMod = (keybindsOk and keybindsData.main_mod) or "SUPER" -- Sets "Windows" key as main modifier
local keybindOverrides = (keybindsOk and keybindsData.overrides) or {}
local customBinds = (keybindsOk and keybindsData.custom_binds) or {}

-- Monta "mainMod + TECLA1 + TECLA2" a partir do override daquela ação (se
-- existir) ou do "defaultExtra" hardcoded ali no chamador - até 2 teclas
-- extras além do mainMod, então até 3 no total. Só as ações NOMEADAS
-- abaixo passam por aqui; setas de foco/mover, workspaces 1-9-0, arrasto
-- de mouse e teclas de mídia XF86 continuam com bind fixo mais abaixo
-- neste arquivo, de propósito (não fazem parte da aba Atalhos).
local function keybind(id, defaultExtra)
    local extra = keybindOverrides[id] or defaultExtra
    local combo = mainMod
    for _, key in ipairs(extra) do
        combo = combo .. " + " .. key
    end
    return combo
end

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(keybind("terminal", { "T" }), hl.dsp.exec_cmd(programs.terminal))
local closeWindowBind = hl.bind(keybind("closeWindow", { "Q" }), hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)
hl.bind(keybind("exitMenu", { "M" }), hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(keybind("fileManager", { "E" }), hl.dsp.exec_cmd(programs.fileManager))
hl.bind(keybind("floatToggle", { "V" }), hl.dsp.window.float({ action = "toggle" }))
hl.bind(keybind("menu", { "R" }), hl.dsp.exec_cmd(programs.menu))
hl.bind(keybind("pseudo", { "P" }), hl.dsp.window.pseudo())
hl.bind(keybind("togglesplit", { "J" }), hl.dsp.layout("togglesplit"))    -- dwindle only
hl.bind(keybind("nextWallpaper", { "W" }), hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle-wallpaper.sh next"))
hl.bind(keybind("settings", { "C" }), hl.dsp.exec_cmd(programs.settingsWin))

-- Atalhos personalizados criados na aba Atalhos (comando de shell livre,
-- sem ação nomeada correspondente) - mesma convenção de mainMod + até 2
-- teclas extras dos binds acima.
for _, bind in ipairs(customBinds) do
    local combo = mainMod
    for _, key in ipairs(bind.keys) do
        combo = combo .. " + " .. key
    end
    hl.bind(combo, hl.dsp.exec_cmd(bind.command))
end

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Move active window within its current workspace with mainMod + SHIFT + arrow keys
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Move active window to the previous/next workspace with mainMod + SHIFT + CTRL + arrow keys
hl.bind(mainMod .. " + SHIFT + CTRL + left",  hl.dsp.window.move({ workspace = "-1" }))
hl.bind(mainMod .. " + SHIFT + CTRL + right", hl.dsp.window.move({ workspace = "+1" }))
hl.bind(mainMod .. " + SHIFT + CTRL + up",    hl.dsp.window.move({ workspace = "-1" }))
hl.bind(mainMod .. " + SHIFT + CTRL + down",  hl.dsp.window.move({ workspace = "+1" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(keybind("specialWorkspace", { "S" }),   hl.dsp.workspace.toggle_special("magic"))
hl.bind(keybind("screenshot", { "SHIFT", "S" }), hl.dsp.exec_cmd(programs.captureAuto)) -- captura de tela (clique/arrasta/fora)
hl.bind(keybind("screenrecord", { "SHIFT", "G" }), hl.dsp.exec_cmd(programs.recordAuto))  -- gravação de tela, mesmo esquema

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
