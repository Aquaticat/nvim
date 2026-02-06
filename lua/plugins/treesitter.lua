return {
  -- nvim-treesitter v2: parser manager only.
  -- Highlight/indent use Neovim's built-in treesitter support (vim.treesitter).
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    -- Install parsers on first load
    require("nvim-treesitter").install({
      "lua", "vim", "vimdoc", "query",
      "python", "javascript", "typescript", "json", "yaml", "toml",
      "bash", "markdown", "markdown_inline", "html", "css",
      "c", "cpp", "rust", "go",
    })
  end,
}

