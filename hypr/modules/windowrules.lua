--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- Quickshell settings panel: keep it floating and centered instead of tiled
hl.window_rule({
    name  = "float-quickshell-settings",
    match = { class = "^org.quickshell$", title = "^Configurações$" },

    float  = true,
    center = true,
    pin    = true,
    size   = "720 480",
})

-- Picture-in-Picture do navegador (Firefox): sempre float, nunca tiled, e
-- fixada na tela (pin) pra acompanhar a troca de workspace em vez de ficar
-- pra trás na workspace onde foi aberta.
hl.window_rule({
    name  = "float-pin-pip",
    match = { class = "^firefox$", title = "^Picture-in-Picture$" },

    float = true,
    pin   = true,
})

hl.window_rule({
    name  = "btop",
    match = { class = "monitor" },
    size  = { "monitor_w * 0.7", "monitor_h * 0.7" }, 
    float = true,
    pin   = true,
    -- move  = { "(monitor_w - window_w) - 20","(monitor_h - window_h) - 20"}
})

hl.window_rule({
    name  = "bluetui",
    match = { class = "bluetui" },
    size  = { "monitor_w * 0.6", "monitor_h * 0.6" }, 
    float = true,
    pin   = true,
    -- move  = { "80","(monitor_h - window_h) - 10"}
})

hl.window_rule({
    name  = "wlctl",
    match = { class = "wlctl" },
    size  = { "monitor_w * 0.6", "monitor_h * 0.6" }, 
    float = true,
    pin   = true,
    -- move  = { "80","(monitor_h - window_h) - 10"}
})
