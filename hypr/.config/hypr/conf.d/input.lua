-- Input devices — keyboard, mouse, touchpad, gestures
--
-- Note: the Lua keys are underscored (tap_to_click, tap_and_drag) where the
-- old hyprlang ones were hyphenated (tap-to-click, tap-and-drag).

-- ── Keyboard layouts ─────────────────────────────────
-- Cycle order. The first entry is what the session starts on, and what it
-- returns to on `hyprctl reload` (the config re-executes, so `current` resets).
--
-- Why one layout at a time instead of kb_layout = "us,es" plus an xkb group
-- toggle: Hyprland 0.56 has no switchxkblayout in its Lua API — enumerate
-- hl.dsp with `hyprctl eval` and it simply isn't there — so once both layouts
-- are loaded into one keymap nothing can move the active group index. xkb's
-- own grp: options can't carry the bind either; the closest is
-- grp:win_space_toggle, i.e. SUPER + SPACE, which keybinds.lua already gives
-- to the launcher.
--
-- Rewriting kb_layout does the whole job anyway: Hyprland rebuilds the keymap
-- for every keyboard (including the virtual one noctalia types through) and
-- emits `activelayout` on socket2, which is what noctalia's bar widget reads
-- (show_keyboard_layout in its config.toml).
local layouts = { "us", "es" }
local current = 1

local M = {}

--- Switch to the next layout in `layouts`, wrapping around.
--- Bound to SUPER + SHIFT + SPACE in keybinds.lua.
function M.cycle_layout()
    current = current % #layouts + 1
    hl.config({ input = { kb_layout = layouts[current] } })
end

hl.config({
    input = {
        kb_layout = layouts[current],
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            tap_to_click = true,
            tap_and_drag = true,
        },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

return M
