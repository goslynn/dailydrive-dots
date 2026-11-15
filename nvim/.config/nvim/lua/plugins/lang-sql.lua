-- PostgreSQL on top of the lang.sql extra (vim-dadbod + dadbod-ui +
-- dadbod-completion + sqlfluff).
--
--   <leader>D        toggle dadbod-ui: add a connection as
--                    postgresql://user:pass@localhost:5432/db, then table and
--                    column names complete in the query buffer
--   postgres_lsp     syntax errors as you type, hover, and — once it can reach
--                    a database (postgres-language-server.jsonc in the project
--                    root) — schema-aware completion and type checks. Upstream
--                    only attaches when that .jsonc exists; here it also runs
--                    in any git repo or loose .sql file, for the syntax half.
--
-- The extra calls sqlfluff with --dialect=ansi, which flags every Postgres
-- construct (::casts, RETURNING, $$ bodies, ON CONFLICT) as a lint error.
-- A project's own .sqlfluff still wins over these args.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        postgres_lsp = {
          root_markers = { "postgres-language-server.jsonc", ".git" },
          workspace_required = false,
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function()
      require("lint").linters.sqlfluff.args = { "lint", "--format=json", "--dialect=postgres", "-" }
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters = {
        sqlfluff = { args = { "format", "--dialect=postgres", "-" } },
      },
    },
  },
}
