-- Keybindings — https://wiki.hypr.land/Configuring/Basics/Binds/

-- Bare module name: conf.d/ is on package.path, set by hyprland.lua.
local programs = require("programs")

local mainMod = "SUPER"

-- ── Apps ─────────────────────────────────────────────
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(programs.terminal))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(programs.file_manager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(programs.browser))


-- ── Noctalia panels (IPC: noctalia msg panel-toggle <id>) ────
hl.bind(mainMod .. " + SPACE",  hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
hl.bind(mainMod .. " + V",      hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"))
hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"))
hl.bind(mainMod .. " + C",      hl.dsp.exec_cmd("noctalia msg settings-toggle"))
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("noctalia msg panel-toggle session"))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center calendar"))

-- ── Window control ───────────────────────────────────
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + W", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mainMod .. " + CTRL + F",  hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- ── Focus ────────────────────────────────────────────
for key, dir in pairs({
    left = "left", right = "right", up = "up", down = "down",
    h = "left",    l = "right",     k = "up",  j = "down",
}) do
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ direction = dir }))
end

-- ── Move windows ─────────────────────────────────────
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mainMod .. " + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }))
end

-- ── Resize ───────────────────────────────────────────
for _, r in ipairs({
    { key = "right", x =  30, y =   0 },
    { key = "left",  x = -30, y =   0 },
    { key = "up",    x =   0, y = -30 },
    { key = "down",  x =   0, y =  30 },
}) do
    hl.bind(mainMod .. " + CTRL + " .. r.key,
        hl.dsp.window.resize({ x = r.x, y = r.y, relative = true }),
        { repeating = true })
end

-- ── Workspaces ───────────────────────────────────────
for i = 1, 10 do
    local key = i % 10 -- workspace 10 sits on key 0
    hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + grave",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- ── Mouse drag ───────────────────────────────────────
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ── Screenshots — noctalia's built-in screencopy capture ─────
-- Annotation is a noctalia setting (Settings -> screenshot annotation tool),
-- not a separate keybind: it wraps whichever capture you take.
hl.bind(mainMod .. " + SHIFT + S",       hl.dsp.exec_cmd("noctalia msg screenshot-region"))
hl.bind(mainMod .. " + S",               hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"))
hl.bind("Print",                         hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"))
hl.bind(mainMod .. " + SHIFT + ALT + S", hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen all"))

-- ── Media keys — routed through noctalia so they raise its OSD ─────
-- Decisión: el volumen lo maneja noctalia, no wpctl. noctalia es el shell y ya
-- es el dueño de los OSD, igual que brillo, media y screenshots aquí abajo.
-- Llamar a wpctl en paralelo daría dos dueños del mismo estado y ningún OSD.
-- Si estas teclas dejan de responder, el shell está caído: revísalo con
-- `pgrep noctalia`, no cambies estos binds.
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("noctalia msg volume-up"),         { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("noctalia msg volume-down"),       { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("noctalia msg volume-mute"),       { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("noctalia msg mic-mute"),          { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("noctalia msg brightness-up"),     { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"),   { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("noctalia msg media next"),     { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("noctalia msg media toggle"),   { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("noctalia msg media toggle"),   { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("noctalia msg media previous"), { locked = true })
