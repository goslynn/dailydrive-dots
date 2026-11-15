-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- basedpyright over pyright: same engine, but ships the inlay hints, semantic
-- highlighting and "go to declaration in stubs" that upstream pyright keeps
-- for Pylance only.
vim.g.lazyvim_python_lsp = "basedpyright"

-- Keep a few lines of context around the cursor while jumping through
-- search results / LSP references.
vim.opt.scrolloff = 8
