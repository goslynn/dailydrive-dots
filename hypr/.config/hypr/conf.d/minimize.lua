-- Minimize / restore — Hyprland has no real minimize, so this fakes one.
--
-- Minimizing (SUPER+N, bound in keybinds.lua) sends the window to a hidden
-- special workspace without following it. Those windows, and only those,
-- show up in noctalia's bottom bar (bar.bottombar, widget from the
-- vgonz/minimized plugin in noctalia/.local/share/noctalia/plugins/). Clicking
-- one there runs M.restore through `hyprctl eval`.
--
-- The bar does not poll: every window move or close pokes it to re-read
-- `hyprctl clients`. It is a cheap one-shot IPC call, and filtering here
-- would mean knowing the workspace a window just left, which the event does
-- not say.
--
-- Keyboard restore is an alt+tab over the same bar (binds in keybinds.lua):
-- SUPER+TAB opens the switcher submap and selects the newest minimized
-- window, more TABs step to older ones (SHIFT+TAB steps back), letting go of
-- SUPER restores the selection and ESC backs out.
--
-- "Letting go of SUPER" is watched with a timer polling hl.is_key_down, not
-- with a release bind: Hyprland drops a modifier's release bind once another
-- key (the TAB) was pressed while it was held, which is exactly the alt+tab
-- case.
--
-- The bar owns the list and its order, so all this side sends is a session
-- id, a sequence number and an offset from the newest window. Each IPC call
-- is its own process and they can land out of order; the bar keeps the
-- highest sequence per session and drops anything for a session that ended.
--
-- Not covered: an app's own minimize button. Hyprland ignores client minimize
-- requests and exposes no Lua event for them.

local M = {}

M.workspace = "special:minimized"
M.switcher = "minimized-switcher"

local function to_bar(event)
    hl.exec_cmd("noctalia msg plugin vgonz/minimized:bar all " .. event)
end

local function refresh_bar()
    to_bar("refresh")
end

local session, seq, offset = 0, 0, 0
local release_watch = nil

local function send(event)
    seq = seq + 1
    to_bar(string.format("%s %d:%d:%d", event, session, seq, offset))
end

local function super_down()
    return hl.is_key_down("Super_L") or hl.is_key_down("Super_R")
end

local function finish(event)
    if release_watch then
        release_watch:set_enabled(false)
        release_watch = nil
    end
    hl.dispatch(hl.dsp.submap("reset"))
    send(event)
end

function M.switch_start()
    if release_watch then release_watch:set_enabled(false) end
    -- Clock-based so ids keep growing across `hyprctl reload`, which resets
    -- this file's locals but not the bar's memory of ended sessions.
    session, offset = math.max(session + 1, os.time() * 100), 0
    hl.dispatch(hl.dsp.submap(M.switcher))
    send("select")
    release_watch = hl.timer(function()
        if not super_down() then finish("commit") end
    end, { timeout = 30, type = "repeat" })
end

function M.switch_step(delta)
    return function()
        offset = offset + delta
        send("select")
    end
end

function M.switch_cancel()
    finish("cancel")
end

-- Back onto the regular workspace you are on (not the special one), focused.
local function bring_back(w)
    local ws = hl.get_active_workspace()
    if not ws then return end

    hl.dispatch(hl.dsp.window.move({ workspace = ws.id, window = w }))
    hl.dispatch(hl.dsp.focus({ window = w }))
end

function M.restore(address)
    for _, w in ipairs(hl.get_windows()) do
        if w.address == address then
            if w.workspace and w.workspace.name == M.workspace then
                bring_back(w)
            end
            return
        end
    end
end

-- Focusing a minimized window by other means (focus cycling, an app asking
-- for attention) would otherwise pop special:minimized open as an overlay
-- with the window still "minimized". Treat it as a restore instead.
--
-- window.active fires twice per activation (callback gets the window and a
-- number). The second call sees the window already moved and does nothing.
hl.on("window.active", function(w)
    if not w or not w.workspace or w.workspace.name ~= M.workspace then return end
    bring_back(w)
end)

hl.on("window.move_to_workspace", refresh_bar)
hl.on("window.destroy", refresh_bar)

return M
