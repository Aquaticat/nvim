---@module "neominimap.config.meta"
return {
  "Isrothy/neominimap.nvim",
  version = "v3.*",
  lazy = false,
  init = function()
    vim.g.neominimap = {
      auto_enable = true,
      layout = "split",
      split = {
        direction = "right",
        minimap_width = 10,
      },
      diagnostic = { enabled = true },
      treesitter = { enabled = true },
      exclude_filetypes = { "help", "neo-tree", "lazy", "mason" },
    }
  end,
  keys = {
    { "<leader>nm", "<cmd>Neominimap Toggle<cr>", desc = "Toggle minimap" },
    { "<leader>nf", "<cmd>Neominimap Focus<cr>", desc = "Focus minimap" },
    { "<leader>nu", "<cmd>Neominimap Unfocus<cr>", desc = "Unfocus minimap" },
  },
}
