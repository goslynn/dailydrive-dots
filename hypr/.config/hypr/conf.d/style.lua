-- Look & feel — general/decoration/animations
--
-- Border colors are not set here: noctalia's generated
-- ~/.config/hypr/noctalia.lua sets general.col.active_border/inactive_border
-- via apply_theme(), called last from the entry point, so anything set here
-- would just be overwritten.

hl.config({
    general = {
        gaps_in  = 4,
        gaps_out = 8,
        border_size = 2,
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 12,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 6,
            render_power = 2,
            color = "rgba(11111baa)",
        },
        blur = {
            enabled = false,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("snap", { type = "bezier", points = { { 0.2, 0.9 }, { 0.1, 1.0 } } })

hl.animation({ leaf = "windows",    enabled = true, speed = 3, bezier = "snap",    style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "snap",    style = "popin 90%" })
hl.animation({ leaf = "border",     enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "snap",    style = "slide" })
