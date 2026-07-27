-- Hyprland — entry point. Real config lives in conf.d/
--
-- Each require() is its own Lua scope, so an error in one file does not stop
-- the others from loading. Order still matters for anything that overrides an
-- earlier value, so it's kept the same as the old hyprlang source order.
--
-- Why package.path instead of require("conf.d/style"): Lua module names
-- translate every "." into a path separator, so both "conf.d/style" and the
-- absolute path form turn into conf/d/style.lua and fail to resolve. Putting
-- conf.d on the search path lets the files keep their directory name and be
-- required by bare module name.
--
-- programs.lua is not required here: it's a plain data module (it returns a
-- table rather than calling into hl.*), pulled in by the files that use it.

package.path = os.getenv("HOME") .. "/.config/hypr/conf.d/?.lua;" .. package.path

-- Boot-time
require("monitors")
require("env")

-- Look & behavior
require("xwayland")
require("style")
require("layout")
require("input")

-- Runtime
require("autostart")
require("rules")
require("keybinds")

-- For Noctalia Color templates
require("noctalia").apply_theme()
