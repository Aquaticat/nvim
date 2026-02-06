return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  lazy = false, -- load eagerly so the tree shows on startup
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  keys = {
    -- JetBrains: Alt+1 = toggle project view
    { "<A-1>", "<Cmd>Neotree toggle<CR>", desc = "Toggle File Tree" },
    -- JetBrains: Alt+F1 = select in / reveal current file
    { "<A-F1>", "<Cmd>Neotree reveal<CR>", desc = "Reveal in File Tree" },
  },
  opts = {
    close_if_last_window = true,
    -- Auto-show file tree on startup (like JetBrains project view)
    open_on_setup = true,
    filesystem = {
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      filtered_items = {
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
    window = {
      position = "left",
      width = 30,
      mappings = {
        -- Single click opens files / toggles directories (like JetBrains)
        ["<LeftRelease>"] = "open",
      },
    },
  },
  -- Open the tree after plugin loads
  init = function()
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        vim.schedule(function()
          vim.cmd("Neotree show")
        end)
      end,
    })
  end,
}
