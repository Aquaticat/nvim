local function show_neotree_context_menu()
  local Menu = require("nui.menu")
  local state = require("neo-tree.sources.manager").get_state("filesystem")
  local node = state.tree:get_node()
  local path = node:get_id()
  local fs = require("neo-tree.sources.filesystem.commands")
  local cc = require("neo-tree.sources.common.commands")

  -- neo-tree commands expect state.config (normally set by the mapping handler)
  state.config = state.config or {}

  local actions = {
    ["New"]                  = function() fs.add(state) end,
    ["Rename"]               = function() fs.rename(state) end,
    ["Delete"]               = function() fs.delete(state) end,
    ["Copy"]                 = function() cc.copy_to_clipboard(state) end,
    ["Cut"]                  = function() cc.cut_to_clipboard(state) end,
    ["Paste"]                = function() cc.paste_from_clipboard(state) end,
    ["Copy Path"]            = function()
      local rel = vim.fn.fnamemodify(path, ":.")
      vim.fn.setreg("+", rel)
      vim.notify("Copied: " .. rel)
    end,
    ["Open in Terminal"]     = function()
      local dir = node.type == "directory" and path or vim.fn.fnamemodify(path, ":h")
      vim.fn.jobstart({ "xdg-terminal-exec" }, { cwd = dir, detach = true })
    end,
    ["Reveal in File Manager"] = function()
      local dir = node.type == "directory" and path or vim.fn.fnamemodify(path, ":h")
      vim.fn.jobstart({ "xdg-open", dir }, { detach = true })
    end,
  }

  local menu = Menu({
    relative = "cursor",
    position = { row = 1, col = 0 },
    border = { style = "rounded" },
    win_options = { winhighlight = "Normal:Normal,FloatBorder:FloatBorder" },
  }, {
    lines = {
      Menu.item("New"),
      Menu.item("Rename"),
      Menu.item("Delete"),
      Menu.separator("", { char = "─" }),
      Menu.item("Copy"),
      Menu.item("Cut"),
      Menu.item("Paste"),
      Menu.separator("", { char = "─" }),
      Menu.item("Copy Path"),
      Menu.item("Open in Terminal"),
      Menu.item("Reveal in File Manager"),
    },
    keymap = {
      focus_next = { "j", "<Down>" },
      focus_prev = { "k", "<Up>" },
      close = { "<Esc>", "<C-c>", "<RightMouse>" },
      submit = { "<CR>", "<LeftMouse>" },
    },
    on_submit = function(item)
      local action = actions[item.text]
      if action then action() end
    end,
  })

  menu:mount()
  menu:on("BufLeave", function() menu:unmount() end)
end

-- Right-click context menu setup.
-- Why mousemodel=extend: Neovim's default popup_setpos intercepts <RightMouse>
-- at the C level, bypassing all user mappings. With "extend" we get the raw
-- mouse event and can handle focus-switching + popup rendering ourselves.
-- Why <RightRelease> not <RightMouse>: showing the popup on button-down causes
-- the release event to immediately dismiss it.
-- Why nui.Menu not :popup: the :popup command renders inside the target window
-- and gets clipped to neo-tree's narrow 30-column width.
local function setup_neotree_context_menu()
  vim.o.mousemodel = "extend"

  -- Suppress Neovim's built-in MenuPopup autocmd (it assumes default PopUp items)
  vim.api.nvim_create_augroup("nvim.popupmenu", { clear = true })

  local function handle_right_up()
    local pos = vim.fn.getmousepos()
    local target_win = pos.winid
    if target_win ~= 0 and target_win ~= vim.api.nvim_get_current_win() then
      vim.api.nvim_set_current_win(target_win)
    end
    if pos.line > 0 then
      pcall(vim.api.nvim_win_set_cursor, 0, { pos.line, math.max(0, pos.column - 1) })
    end

    if vim.bo.filetype == "neo-tree" then
      show_neotree_context_menu()
    else
      vim.cmd("popup PopUp")
    end
  end

  for _, mode in ipairs({ "n", "v", "i", "x", "s", "o" }) do
    vim.keymap.set(mode, "<RightMouse>", "<Nop>", { silent = true })
    vim.keymap.set(mode, "<RightRelease>", handle_right_up, { silent = true })
  end
end

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
    -- JetBrains: Alt+1 = toggle project view (works from insert mode)
    { "<A-1>", "<Cmd>Neotree toggle<CR>", mode = { "i", "n" }, desc = "Toggle File Tree" },
    -- JetBrains: Alt+F1 = select in / reveal current file
    { "<A-F1>", "<Cmd>Neotree reveal<CR>", mode = { "i", "n" }, desc = "Reveal in File Tree" },
  },
  opts = {
    close_if_last_window = true,
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
  config = function(_, opts)
    setup_neotree_context_menu()
    require("neo-tree").setup(opts)
  end,
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
