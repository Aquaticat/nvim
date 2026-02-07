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
-- Bound in insert mode too: exits insert, selects, enters visual.
local ts_sel_node = nil
map = vim.keymap.set

local function extend_selection()
  local ok, node = pcall(vim.treesitter.get_node)
  if not ok or not node then return end
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    ts_sel_node = (ts_sel_node and ts_sel_node:parent()) or node:parent()
  else
    ts_sel_node = node
  end
  if not ts_sel_node then return end
  local sr, sc, er, ec = ts_sel_node:range()
  vim.api.nvim_buf_set_mark(0, "<", sr + 1, sc, {})
  vim.api.nvim_buf_set_mark(0, ">", er + 1, ec - 1, {})
  vim.cmd("normal! gv")
end

map({ "n", "v" }, "<C-w>", extend_selection, { desc = "Extend Selection (treesitter)" })
map("i", "<C-w>", function()
  vim.cmd("stopinsert")
  extend_selection()
end, { desc = "Extend Selection (treesitter)" })

local function shrink_selection()
  if not ts_sel_node then return end
  local child = nil
  for c in ts_sel_node:iter_children() do
    if c:named() then child = c; break end
  end
  if child then ts_sel_node = child end
  local sr, sc, er, ec = ts_sel_node:range()
  vim.api.nvim_buf_set_mark(0, "<", sr + 1, sc, {})
  vim.api.nvim_buf_set_mark(0, ">", er + 1, ec - 1, {})
  vim.cmd("normal! gv")
end

map("v", "<C-S-w>", shrink_selection, { desc = "Shrink Selection (treesitter)" })

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
-- GUI Editor Mode: auto-enter insert mode in file buffers.
-- Neovide bug/limitation: clicking neo-tree from insert mode doesn't work.
-- Workaround: intercept <LeftMouse> in insert mode -- if the click target is
-- a non-file window (neo-tree, telescope, etc.), stopinsert first so the
-- click lands in normal mode where those plugins expect it. If the click is
-- within a file buffer, stay in insert mode.
-------------------------------------------------------------------------------
local function is_file_buf(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  return vim.bo[buf].buftype == ""
end

vim.keymap.set("i", "<LeftMouse>", function()
  -- Determine which window the click will land in
  local mouse = vim.fn.getmousepos()
  local target_win = mouse.winid
  if target_win ~= 0 and vim.api.nvim_win_is_valid(target_win) then
    local target_buf = vim.api.nvim_win_get_buf(target_win)
    if not is_file_buf(target_buf) then
      -- Clicking a plugin window: leave insert mode so the plugin gets
      -- its expected normal-mode context, then forward the click.
      vim.cmd("stopinsert")
    end
  end
  -- Forward the actual mouse click
  local key = vim.api.nvim_replace_termcodes("<LeftMouse>", true, false, true)
  vim.api.nvim_feedkeys(key, "ni", false)
end, { desc = "Smart click: stopinsert for plugin windows" })

-- Enter insert mode on startup and when entering file buffers
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function(ev)
    if not is_file_buf(ev.buf) then return end
    if not vim.bo[ev.buf].modifiable then return end
    vim.defer_fn(function()
      if not vim.api.nvim_buf_is_valid(ev.buf) then return end
      local cur_buf = vim.api.nvim_get_current_buf()
      if cur_buf == ev.buf and vim.fn.mode() == "n" and is_file_buf(cur_buf) then
        vim.cmd("startinsert")
      end
    end, 50)
  end,
})

-------------------------------------------------------------------------------
-- Escape: if popups/completion are open, close them and stay in insert mode.
-- Otherwise, pass through to normal mode (needed for :commands like :messages).
-------------------------------------------------------------------------------
vim.keymap.set("i", "<Esc>", function()
  local closed_any = false
  -- Close floating windows (hover, diagnostics, etc.)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local ok, cfg = pcall(vim.api.nvim_win_get_config, win)
      if ok and cfg.relative ~= "" then
        pcall(vim.api.nvim_win_close, win, true)
        closed_any = true
      end
    end
  end
  -- Close completion menu
  if vim.fn.pumvisible() == 1 then
    local key = vim.api.nvim_replace_termcodes("<C-e>", true, false, true)
    vim.api.nvim_feedkeys(key, "n", false)
    closed_any = true
  end
  -- Nothing to close: leave insert mode (for :commands, etc.)
  if not closed_any then
    local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    vim.api.nvim_feedkeys(esc, "n", false)
  end
end, { desc = "Close popups or exit to normal mode" })

-------------------------------------------------------------------------------
-- Standard GUI navigation keymaps (insert mode)
-------------------------------------------------------------------------------
local map = vim.keymap.set

-- Home / End
map("i", "<Home>", "<C-o>^", { desc = "Start of line (first non-blank)" })
map("i", "<End>", "<End>", { desc = "End of line" })
map("i", "<C-Home>", "<C-o>gg", { desc = "Start of file" })
map("i", "<C-End>", "<C-o>G<End>", { desc = "End of file" })

-- Word jump
map("i", "<C-Left>", "<C-o>b", { desc = "Word left" })
map("i", "<C-Right>", "<S-Right>", { desc = "Word right" })

-- Delete word
map("i", "<C-BS>", "<C-w>", { desc = "Delete word backward" })
map("i", "<C-Del>", "<C-o>dw", { desc = "Delete word forward" })

-- Shift+arrow selection
vim.opt.keymodel = "startsel,stopsel"
vim.opt.selectmode = ""  -- use visual mode, not select mode

-- Ctrl+Shift word-select
map("i", "<C-S-Left>", "<C-o>vb", { desc = "Select word left" })
map("i", "<C-S-Right>", "<C-o>ve", { desc = "Select word right" })

-------------------------------------------------------------------------------
-- JetBrains Windows Keymap (insert mode as primary mode)
-------------------------------------------------------------------------------

-- Clipboard
map({ "i", "n", "v" }, "<C-c>", function()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    vim.cmd('normal! "+y')
    vim.cmd("startinsert")
  end
end, { desc = "Copy" })

map({ "i", "n", "v" }, "<C-x>", function()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    vim.cmd('normal! "+d')
    vim.cmd("startinsert")
  else
    vim.cmd('normal! "+dd')
    vim.cmd("startinsert")
  end
end, { desc = "Cut" })

map({ "i", "n", "v" }, "<C-v>", function()
  vim.api.nvim_paste(vim.fn.getreg("+"), true, -1)
end, { desc = "Paste" })

-- Undo / Redo
map("i", "<C-z>", "<Cmd>undo<CR>", { desc = "Undo" })
map("i", "<C-S-z>", "<Cmd>redo<CR>", { desc = "Redo" })

-- Open directory via native KDE file dialog, then cd + refresh neo-tree
map("i", "<C-o>", function()
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
map({ "i", "n", "v" }, "<C-s>", "<Cmd>wa<CR>", { desc = "Save All" })

-- Select All
map("i", "<C-a>", "<Esc>ggVG", { desc = "Select All" })

-- Duplicate line (Ctrl+D in JetBrains)
map("i", "<C-d>", function()
  local line = vim.api.nvim_get_current_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, { line })
  vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
end, { desc = "Duplicate Line" })

-- Delete line (Ctrl+Y in JetBrains)
map("i", "<C-y>", function()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row - 1, row, true, {})
end, { desc = "Delete Line" })

-- Move line up/down (Alt+Shift+Up/Down)
map("i", "<A-S-Up>", "<C-o><Cmd>move .-2<CR>", { desc = "Move Line Up" })
map("i", "<A-S-Down>", "<C-o><Cmd>move .+1<CR>", { desc = "Move Line Down" })
map("v", "<A-S-Up>", ":move '<-2<CR>gv=gv", { desc = "Move Selection Up", silent = true })
map("v", "<A-S-Down>", ":move '>+1<CR>gv=gv", { desc = "Move Selection Down", silent = true })

-- Comment (Ctrl+/ -- Neovim 0.10+ has gc built-in)
map("i", "<C-/>", function()
  vim.cmd("stopinsert")
  vim.api.nvim_feedkeys("gcc", "m", false)
  vim.schedule(function() vim.cmd("startinsert") end)
end, { desc = "Toggle Comment" })
map("v", "<C-/>", "gc", { desc = "Toggle Comment", remap = true })

-- New line below / above
map("i", "<S-CR>", "<C-o>o", { desc = "New Line Below" })
map("i", "<C-A-CR>", "<C-o>O", { desc = "New Line Above" })

-- Find in current file (Ctrl+F)
map("i", "<C-f>", "<C-o>/", { desc = "Find in File" })

-- Replace in current file
map("i", "<C-r>", "<C-o>:%s/", { desc = "Replace in File" })

-- Go to line (Ctrl+G)
map("i", "<C-g>", "<C-o>:", { desc = "Go to Line" })

-- Close buffer (Ctrl+F4)
map("i", "<C-F4>", "<Cmd>bd<CR>", { desc = "Close Buffer" })

-- File tree: Alt+1 toggle, Alt+F1 reveal (mapped in neo-tree.lua)
-- LSP keymaps are set up on LspAttach in lsp.lua
-- Search keymaps (Telescope) are set up in telescope.lua

-- Double-Shift "Search Everywhere"
if vim.g.neovide then
  map({ "i", "n" }, "<F20>", function()
    if vim.fn.mode() == "i" then vim.cmd("stopinsert") end
    require("telescope.builtin").find_files({ prompt_title = "Search Everywhere" })
  end, { desc = "Search Everywhere (Double-Shift via daemon)" })
end
