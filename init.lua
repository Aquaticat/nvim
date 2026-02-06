-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Leader must be set before lazy
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Editor options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.smartindent = true
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.undofile = true
vim.opt.updatetime = 250
vim.opt.showmode = false

-- Neovide-specific settings
if vim.g.neovide then
  vim.o.guifont = "JetBrains Mono:h14"
  vim.g.neovide_cursor_animation_length = 0.05
  vim.g.neovide_scroll_animation_length = 0.1
  vim.g.neovide_hide_mouse_when_typing = true
  vim.g.neovide_confirm_quit = true
  vim.g.neovide_remember_window_size = true
end

-- Inline diagnostics
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  float = { border = "rounded" },
})

-- Load plugins via lazy.nvim
require("lazy").setup("plugins")

-- Treesitter: enable built-in highlight and indent (nvim-treesitter v2 is
-- parser-manager only; Neovim 0.11+ handles highlight/indent natively).
vim.treesitter.start = vim.treesitter.start -- ensure autostart is on
vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    -- Try to attach treesitter highlight; silently skip if no parser installed
    pcall(vim.treesitter.start, ev.buf)
  end,
})

-- JetBrains: Ctrl+W = extend selection, Ctrl+Shift+W = shrink selection
-- Uses treesitter incremental node selection.
local ts_sel_node = nil
map = vim.keymap.set
map({ "n", "v" }, "<C-w>", function()
  local ok, node = pcall(vim.treesitter.get_node)
  if not ok or not node then return end
  -- In normal mode, start selection at current node
  if vim.fn.mode() == "n" then
    ts_sel_node = node
  else
    -- In visual mode, go to parent node to extend
    ts_sel_node = (ts_sel_node and ts_sel_node:parent()) or node:parent()
  end
  if not ts_sel_node then return end
  local sr, sc, er, ec = ts_sel_node:range()
  vim.api.nvim_buf_set_mark(0, "<", sr + 1, sc, {})
  vim.api.nvim_buf_set_mark(0, ">", er + 1, ec - 1, {})
  vim.cmd("normal! gv")
end, { desc = "Extend Selection (treesitter)" })

map("v", "<C-S-w>", function()
  if not ts_sel_node then return end
  -- Find first named child to shrink into
  local child = nil
  for c in ts_sel_node:iter_children() do
    if c:named() then child = c; break end
  end
  if child then ts_sel_node = child end
  local sr, sc, er, ec = ts_sel_node:range()
  vim.api.nvim_buf_set_mark(0, "<", sr + 1, sc, {})
  vim.api.nvim_buf_set_mark(0, ">", er + 1, ec - 1, {})
  vim.cmd("normal! gv")
end, { desc = "Shrink Selection (treesitter)" })

-- Colorscheme: proof-of-concept #ccc on #000
-- Applied after plugins load so it overrides everything
vim.cmd("highlight Normal guifg=#cccccc guibg=#000000")
vim.cmd("highlight NormalFloat guifg=#cccccc guibg=#111111")
vim.cmd("highlight FloatBorder guifg=#555555 guibg=#111111")
vim.cmd("highlight CursorLine guibg=#111111")
vim.cmd("highlight CursorLineNr guifg=#cccccc guibg=#111111")
vim.cmd("highlight LineNr guifg=#555555")
vim.cmd("highlight Visual guibg=#264f78")
vim.cmd("highlight Search guifg=#000000 guibg=#cccccc")
vim.cmd("highlight IncSearch guifg=#000000 guibg=#ffffff")
vim.cmd("highlight StatusLine guifg=#cccccc guibg=#1a1a1a")
vim.cmd("highlight StatusLineNC guifg=#555555 guibg=#0a0a0a")
vim.cmd("highlight Pmenu guifg=#cccccc guibg=#1a1a1a")
vim.cmd("highlight PmenuSel guifg=#ffffff guibg=#264f78")
vim.cmd("highlight PmenuSbar guibg=#1a1a1a")
vim.cmd("highlight PmenuThumb guibg=#555555")
vim.cmd("highlight SignColumn guibg=#000000")
vim.cmd("highlight Comment guifg=#555555 gui=italic")
vim.cmd("highlight String guifg=#98c379")
vim.cmd("highlight Keyword guifg=#c678dd")
vim.cmd("highlight Function guifg=#61afef")
vim.cmd("highlight Type guifg=#e5c07b")
vim.cmd("highlight Number guifg=#d19a66")
vim.cmd("highlight Operator guifg=#cccccc")
vim.cmd("highlight Constant guifg=#d19a66")
vim.cmd("highlight Identifier guifg=#cccccc")
vim.cmd("highlight Statement guifg=#c678dd")
vim.cmd("highlight PreProc guifg=#c678dd")
vim.cmd("highlight Special guifg=#56b6c2")
vim.cmd("highlight DiagnosticError guifg=#e06c75")
vim.cmd("highlight DiagnosticWarn guifg=#e5c07b")
vim.cmd("highlight DiagnosticInfo guifg=#61afef")
vim.cmd("highlight DiagnosticHint guifg=#56b6c2")
vim.cmd("highlight WinSeparator guifg=#333333 guibg=#000000")
vim.cmd("highlight NeoTreeNormal guifg=#cccccc guibg=#0a0a0a")
vim.cmd("highlight NeoTreeNormalNC guifg=#cccccc guibg=#0a0a0a")
vim.cmd("highlight NeoTreeWinSeparator guifg=#333333 guibg=#000000")
vim.cmd("highlight TelescopeNormal guifg=#cccccc guibg=#111111")
vim.cmd("highlight TelescopeBorder guifg=#555555 guibg=#111111")
vim.cmd("highlight TelescopePromptNormal guifg=#cccccc guibg=#1a1a1a")
vim.cmd("highlight TelescopePromptBorder guifg=#555555 guibg=#1a1a1a")
vim.cmd("highlight TelescopeResultsNormal guifg=#cccccc guibg=#111111")
vim.cmd("highlight TelescopePreviewNormal guifg=#cccccc guibg=#0a0a0a")

-------------------------------------------------------------------------------
-- JetBrains Windows Keymap
-------------------------------------------------------------------------------
local map = vim.keymap.set

-- Clipboard (Neovide handles system clipboard via unnamedplus)
map({ "n", "v" }, "<C-c>", '"+y', { desc = "Copy" })
map({ "n", "v" }, "<C-x>", '"+d', { desc = "Cut" })
map({ "n", "v", "i" }, "<C-v>", function()
  -- Paste from system clipboard in all modes
  local mode = vim.fn.mode()
  if mode == "i" then
    vim.api.nvim_paste(vim.fn.getreg("+"), true, -1)
  else
    vim.cmd('normal! "+p')
  end
end, { desc = "Paste" })

-- Undo / Redo
map({ "n", "i" }, "<C-z>", "<Cmd>undo<CR>", { desc = "Undo" })
map({ "n", "i" }, "<C-S-z>", "<Cmd>redo<CR>", { desc = "Redo" })

-- Open directory via native KDE file dialog, then cd + refresh neo-tree
map("n", "<C-o>", function()
  local cmd = vim.fn.executable("kdialog") == 1
    and "kdialog --getexistingdirectory " .. vim.fn.fnameescape(vim.fn.getcwd())
    or  "zenity --file-selection --directory"
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      local dir = (data and data[1] or ""):gsub("%s+$", "")
      if dir == "" then return end
      vim.schedule(function()
        vim.cmd("cd " .. vim.fn.fnameescape(dir))
        vim.notify("Opened: " .. dir, vim.log.levels.INFO)
        pcall(vim.cmd, "Neotree dir=" .. vim.fn.fnameescape(dir))
      end)
    end,
  })
end, { desc = "Open Directory" })

-- Save
map({ "n", "i", "v" }, "<C-s>", "<Cmd>wa<CR>", { desc = "Save All" })

-- Select All
map("n", "<C-a>", "ggVG", { desc = "Select All" })

-- Duplicate line (Ctrl+D in JetBrains)
map("n", "<C-d>", function()
  local line = vim.api.nvim_get_current_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, { line })
  vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
end, { desc = "Duplicate Line" })

-- Delete line (Ctrl+Y in JetBrains)
map("n", "<C-y>", "dd", { desc = "Delete Line" })
map("i", "<C-y>", "<Esc>ddi", { desc = "Delete Line" })

-- Move line up/down (Alt+Shift+Up/Down)
map("n", "<A-S-Up>", "<Cmd>move .-2<CR>==", { desc = "Move Line Up" })
map("n", "<A-S-Down>", "<Cmd>move .+1<CR>==", { desc = "Move Line Down" })
map("i", "<A-S-Up>", "<Esc><Cmd>move .-2<CR>==gi", { desc = "Move Line Up" })
map("i", "<A-S-Down>", "<Esc><Cmd>move .+1<CR>==gi", { desc = "Move Line Down" })
map("v", "<A-S-Up>", ":move '<-2<CR>gv=gv", { desc = "Move Selection Up", silent = true })
map("v", "<A-S-Down>", ":move '>+1<CR>gv=gv", { desc = "Move Selection Down", silent = true })

-- Comment (Ctrl+/ -- Neovim 0.10+ has gc built-in via mini comment or default)
map("n", "<C-/>", "gcc", { desc = "Toggle Comment", remap = true })
map("v", "<C-/>", "gc", { desc = "Toggle Comment", remap = true })
map("i", "<C-/>", "<Esc>gcca", { desc = "Toggle Comment", remap = true })

-- New line below / above
map("n", "<S-CR>", "o", { desc = "New Line Below" })
map("i", "<S-CR>", "<Esc>o", { desc = "New Line Below" })
map("n", "<C-A-CR>", "O", { desc = "New Line Above" })
map("i", "<C-A-CR>", "<Esc>O", { desc = "New Line Above" })

-- Find in current file (Ctrl+F -> Neovim search)
map("n", "<C-f>", "/", { desc = "Find in File" })

-- Replace in current file
map("n", "<C-r>", ":%s/", { desc = "Replace in File" })

-- Go to line (Ctrl+G)
map("n", "<C-g>", ":", { desc = "Go to Line" })

-- Close buffer (Ctrl+F4)
map("n", "<C-F4>", "<Cmd>bd<CR>", { desc = "Close Buffer" })

-- Extend / Shrink selection (Ctrl+W / Ctrl+Shift+W) -- see treesitter config
-- These are set up in treesitter.lua via incremental selection

-- File tree: Alt+1 toggle, Alt+F1 reveal (mapped in neo-tree.lua)

-- LSP keymaps are set up on LspAttach in lsp.lua

-- Search keymaps (Telescope) are set up in telescope.lua

-- Double-Shift "Search Everywhere"
-- A KWin script (dshift) registers Shift as a modifier-only shortcut and
-- detects double-taps. On match it calls key-helper-service via D-Bus, which
-- sends nvim_input("<F20>") over msgpack-rpc to the Neovim Unix socket.
-- This bypasses Wayland/winit entirely. Guarded by vim.g.neovide so terminal
-- nvim instances ignore stray triggers.
if vim.g.neovide then
  map("n", "<F20>", function()
    require("telescope.builtin").find_files({ prompt_title = "Search Everywhere" })
  end, { desc = "Search Everywhere (Double-Shift via daemon)" })
end
