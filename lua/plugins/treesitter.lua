return {
  -- nvim-treesitter v2: parser manager only.
  -- Highlight/indent use Neovim's built-in treesitter support (vim.treesitter).
  -- Requires the `tree-sitter` CLI to compile parsers (mise use -g tree-sitter).
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    local wanted = {
      "lua", "vim", "vimdoc", "query",
      "python", "javascript", "typescript", "json", "yaml", "toml",
      "bash", "markdown", "markdown_inline", "html", "css",
      "c", "cpp", "rust", "go",
    }

    -- Only install parsers that are not yet present, so startup stays silent.
    local installed = require("nvim-treesitter").get_installed()
    local installed_set = {}
    for _, lang in ipairs(installed) do
      installed_set[lang] = true
    end

    local missing = vim.tbl_filter(function(lang)
      return not installed_set[lang]
    end, wanted)

    if #missing > 0 then
      require("nvim-treesitter").install(missing)
    end
  end,
}

