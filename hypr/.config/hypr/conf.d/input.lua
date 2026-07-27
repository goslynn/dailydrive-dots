-- Input devices — keyboard, mouse, touchpad, gestures
--
-- Note: the Lua keys are underscored (tap_to_click, tap_and_drag) where the
-- old hyprlang ones were hyphenated (tap-to-click, tap-and-drag).

hl.config({
    input = {
        kb_layout = "us",
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
