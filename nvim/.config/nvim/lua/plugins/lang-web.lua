-- HTML / CSS. LazyVim has no lang extra for plain web files, so the servers
-- are wired here: html and cssls come from vscode-langservers-extracted (via
-- Mason), emmet_language_server expands abbreviations (div.card>ul>li*3) and
-- ranks them through blink.cmp alongside the LSP items.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        html = {},
        cssls = {},
        emmet_language_server = {
          filetypes = {
            "html",
            "css",
            "scss",
            "less",
            "javascriptreact",
            "typescriptreact",
            "vue",
            "svelte",
          },
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "html", "css", "scss" } },
  },
}
