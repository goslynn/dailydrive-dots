-- Catppuccin Frappé, the same palette as kitty/btop/yazi (see README
-- "Theming"). The plugin itself is already part of LazyVim's core specs.
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = { flavour = "frappe" },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin-frappe" },
  },
}
