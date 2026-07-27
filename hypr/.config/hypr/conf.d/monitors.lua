-- Monitors — https://wiki.hypr.land/Configuring/Basics/Monitors/
--
-- This file replaces shikane, which used to own monitor config as a separate
-- daemon. Hyprland's Lua config can express the same rule natively, so there's
-- no second source of truth any more.
--
-- Behaviour (unchanged from the old shikane profiles):
--   HDMI connected     -> external only, laptop panel off
--   HDMI not connected -> laptop panel only
--
-- Hardware on this machine:
--   eDP-1     laptop panel, 2560x1600@60, Lenovo LEN151WQXGA
--   HDMI-A-1  external monitor port
--
-- To find the identity of a new display: `hyprctl monitors all`.

local LAPTOP   = "eDP-1"
local EXTERNAL = "HDMI-A-1"

-- Catch-all first, so the named outputs below take precedence over it for any
-- display we do describe.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.monitor({ output = LAPTOP,   mode = "2560x1600@60", position = "0x0", scale = 1.25 })
hl.monitor({ output = EXTERNAL, mode = "preferred",    position = "0x0", scale = 1.25 })

-- Is the external display connected? `ignored` lets the monitor.removed
-- handler discount the monitor that is in the middle of going away, which is
-- still present in hl.get_monitors() while the event fires.
local function external_connected(ignored)
    for _, m in ipairs(hl.get_monitors()) do
        if m.name == EXTERNAL and m.name ~= ignored then
            return true
        end
    end
    return false
end

-- The laptop panel is only ever disabled while the external is actually
-- present, so there is no path here that leaves every output disabled.
local function sync(ignored)
    hl.monitor({ output = LAPTOP, disabled = external_connected(ignored) })
end

hl.on("monitor.added",   function() sync(nil) end)
hl.on("monitor.removed", function(m) sync(m and m.name or nil) end)

-- Apply once at startup too: the events above only cover hotplug, and a
-- display present at login never emits monitor.added.
sync(nil)
