return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = {
    -- JetBrains: Ctrl+Shift+N = Go to File
    { "<C-S-n>", function() require("telescope.builtin").find_files() end, desc = "Find File" },
    -- JetBrains: Ctrl+Shift+F = Find in Files (grep)
    { "<C-S-f>", function() require("telescope.builtin").live_grep() end, desc = "Find in Files" },
    -- JetBrains: Ctrl+E = Recent Files
    { "<C-e>", function() require("telescope.builtin").oldfiles() end, desc = "Recent Files" },
    -- JetBrains: Ctrl+Tab = Switcher (buffer list)
    { "<C-Tab>", function() require("telescope.builtin").buffers() end, desc = "Switch Buffer" },
    -- JetBrains: Ctrl+F12 = File Structure (LSP symbols)
    { "<C-F12>", function() require("telescope.builtin").lsp_document_symbols() end, desc = "File Structure" },
    -- JetBrains: Ctrl+Shift+A = Find Action (commands)
    { "<C-S-a>", function() require("telescope.builtin").commands() end, desc = "Find Action" },
    -- Double-Shift "Search Everywhere": unified search (files + actions)
    -- Since bare double-shift is hard to detect reliably in terminal/Neovide,
    -- we bind it to Ctrl+Shift+A (Find Action) AND provide a leader shortcut.
    { "<leader><leader>", function()
      -- "Search Everywhere": combined file + command search
      require("telescope.builtin").find_files({
        prompt_title = "Search Everywhere",
      })
    end, desc = "Search Everywhere" },
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
