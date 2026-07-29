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
    size   = "720 480",
})

-- Quickshell voice chat widget: floating, centered, small - drag it with
-- SUPER + clique-esquerdo, como qualquer outra janela flutuante.
hl.window_rule({
    name  = "float-quickshell-voice",
    match = { class = "^org.quickshell$", title = "^Helena Voz$" },

    float = true,
    -- Canto superior-direito, 20px de margem das duas bordas (220 de
    -- largura + 20 de margem = 240 subtraído de monitor_w).
    move  = "monitor_w-240 20",
    size  = "220 260",
})
