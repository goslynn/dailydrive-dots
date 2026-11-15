-- Git beyond lazygit (<leader>gg, from snacks) and gitsigns (]h [h, <leader>gh…):
-- diffview gives a side-by-side review UI for whole commits, ranges and file
-- history, which lazygit's inline diff doesn't.
return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    keys = {
      { "<leader>gv", "", desc = "+diffview" },
      { "<leader>gvo", "<cmd>DiffviewOpen<cr>", desc = "Working tree vs HEAD" },
      { "<leader>gvf", "<cmd>DiffviewFileHistory %<cr>", desc = "Current file history" },
      { "<leader>gvF", "<cmd>DiffviewFileHistory<cr>", desc = "Repo history" },
      { "<leader>gvm", "<cmd>DiffviewOpen origin/HEAD...HEAD<cr>", desc = "Branch vs default branch" },
      { "<leader>gvc", "<cmd>DiffviewClose<cr>", desc = "Close diffview" },
    },
    opts = {},
  },
}
