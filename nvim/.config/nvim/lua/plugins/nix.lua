-- LSPs that come from Nix (nix/home/packages.nix) instead of Mason.
--
--   nil_ls    lang.nix; already on PATH, and Mason would build it with cargo
--             (statix, its linter, and nixfmt, its formatter, are Nix too)
--   marksman  lang.markdown; Mason's build is a self-contained .NET binary
--             that aborts at startup without libicu, which nix-ld doesn't
--             provide ("Couldn't find a valid ICU package")
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nil_ls = { mason = false },
        marksman = { mason = false },
      },
    },
  },
}
