return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = {
    -- All telescope shortcuts work from insert mode (GUI editor mode).
    { "<C-S-n>", function() require("telescope.builtin").find_files() end, mode = { "i", "n" }, desc = "Find File" },
    { "<C-S-f>", function() require("telescope.builtin").live_grep() end, mode = { "i", "n" }, desc = "Find in Files" },
    { "<C-e>", function() require("telescope.builtin").oldfiles() end, mode = { "i", "n" }, desc = "Recent Files" },
    { "<C-Tab>", function() require("telescope.builtin").buffers() end, mode = { "i", "n" }, desc = "Switch Buffer" },
    { "<C-F12>", function() require("telescope.builtin").lsp_document_symbols() end, mode = { "i", "n" }, desc = "File Structure" },
    { "<C-S-a>", function() require("telescope.builtin").commands() end, mode = { "i", "n" }, desc = "Find Action" },
  },
  opts = {
    defaults = {
      prompt_prefix = "  ",
      selection_caret = "  ",
      sorting_strategy = "ascending",
      layout_config = {
        prompt_position = "top",
        horizontal = { preview_width = 0.5 },
      },
    },
  },
}
