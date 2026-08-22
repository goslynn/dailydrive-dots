-- Program aliases — a module, required by the files that reference them.
--
-- Under hyprlang these were `$terminal` style globals. In Lua each require()d
-- file is its own scope, so consumers pull them in explicitly:
--
--   local programs = require("conf.d/programs")
--
-- Default file manager: yazi (registered as the inode/directory handler via
-- mimeapps.list), launched inside kitty since it's a TUI.

return {
    terminal     = "kitty",
    browser      = "brave-origin",
    file_manager = "kitty -e yazi",
}
