-- Entry point. Everything lives under lua/: config/ is LazyVim's own layout
-- (options, keymaps, autocmds, the lazy.nvim bootstrap) and plugins/ holds the
-- specs that extend or override it. Extras are toggled from :LazyExtras and
-- persisted in lazyvim.json next to this file.
require("config.lazy")
