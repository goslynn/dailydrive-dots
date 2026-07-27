-- Look & feel — general/decoration/animations

-- dofile, not require: the palette lives outside the hypr tree and its filename
-- (hyprland.lua) would collide with the entry point as a module name. It's pure
-- data, so loading it directly is simpler than another package.path entry.
local c = dofile(os.getenv("HOME") .. "/.config/themes/catppuccin/mocha/hyprland.lua")

hl.config({
    general = {
        gaps_in  = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border   = { colors = { c.blue, c.mauve }, angle = 45 },
            inactive_border = c.surface0,
        },
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
