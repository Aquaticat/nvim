-- Visual tab bar (IDE/browser-style) using bufferline.nvim.
-- MRU cycling keymaps live in config/keymaps.lua.
return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  opts = {
    options = {
      mode = "buffers",
      diagnostics = "nvim_lsp",
      show_buffer_close_buttons = true,
      show_close_icon = false,
      separator_style = "thin",
      -- Keep neo-tree's sidebar offset
      offsets = {
        { filetype = "neo-tree", text = "Files", highlight = "Directory", padding = 1 },
      },
    },
    -- Match the PoC colorscheme (#ccc on #000)
    highlights = {
      fill            = { bg = "#000000" },
      background      = { fg = "#555555", bg = "#0a0a0a" },
      buffer_selected = { fg = "#cccccc", bg = "#000000", bold = true },
      buffer_visible  = { fg = "#777777", bg = "#0a0a0a" },
      close_button           = { fg = "#555555", bg = "#0a0a0a" },
      close_button_selected  = { fg = "#cccccc", bg = "#000000" },
      close_button_visible   = { fg = "#777777", bg = "#0a0a0a" },
      separator              = { fg = "#333333", bg = "#0a0a0a" },
      separator_selected     = { fg = "#333333", bg = "#000000" },
      separator_visible      = { fg = "#333333", bg = "#0a0a0a" },
      indicator_selected     = { fg = "#61afef", bg = "#000000" },
      modified               = { fg = "#e5c07b", bg = "#0a0a0a" },
      modified_selected      = { fg = "#e5c07b", bg = "#000000" },
      modified_visible       = { fg = "#e5c07b", bg = "#0a0a0a" },
      tab_selected           = { fg = "#cccccc", bg = "#000000" },
    },
  },
}
