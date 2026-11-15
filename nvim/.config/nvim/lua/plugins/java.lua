-- jdtls on top of the lang.java extra.
--
-- The JDKs come from nix/home/packages.nix (xdg.dataFile."jdks/*"):
--   25  runs jdtls itself — current releases won't start on anything older
--   21  what projects compile against by default, same as `java` on PATH
-- A project that sets maven.compiler.release / toolchain 25 picks the 25
-- runtime automatically; the default only covers projects that don't say.
local jdks = vim.fn.expand("~/.local/share/jdks")

return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      if vim.uv.fs_stat(jdks .. "/25/bin/java") then
        table.insert(opts.cmd, 2, "--java-executable=" .. jdks .. "/25/bin/java")
      end
      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          configuration = {
            runtimes = {
              { name = "JavaSE-21", path = jdks .. "/21", default = true },
              { name = "JavaSE-25", path = jdks .. "/25" },
            },
          },
        },
      })
    end,
  },
}
