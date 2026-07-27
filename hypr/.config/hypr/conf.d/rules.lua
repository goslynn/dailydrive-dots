-- Window rules — https://wiki.hypr.land/Configuring/Basics/Window-Rules/
--
-- Lua shape: match{} holds the selectors, everything else is the effect.
-- Rules are evaluated top to bottom, so order matters.

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "float-settings-dialogs",
    -- nm-connection-editor dropped with network-manager-applet; noctalia's
    -- control center owns network config now.
    match = { class = "^(pavucontrol|pwvucontrol|blueman-manager)$" },
    float = true,
})

hl.window_rule({
    name  = "float-jetbrains-toolbox",
    match = { class = "^(jetbrains-toolbox)$" },
    float = true,
})

hl.window_rule({
    name  = "jetbrains-splash-no-focus",
    match = { class = "^(jetbrains-.*)$", title = "^(win|Windows)$" },
    no_initial_focus = true,
})

hl.window_rule({
    name  = "pip-float-pin",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    pin   = true,
})

-- Portal file chooser (xdg-desktop-portal-termfilechooser launches kitty+yazi)
hl.window_rule({
    name   = "termfilechooser",
    match  = { class = "^(termfilechooser)$" },
    float  = true,
    size   = { "monitor_w*0.6", "monitor_h*0.65" },
    center = true,
})
