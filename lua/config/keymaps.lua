-- >100 lines: all insert-mode-primary keymaps live here so binding conflicts
-- are visible in one place; splitting would scatter related GUI-mode keys.
local map = vim.keymap.set

-------------------------------------------------------------------------------
-- Treesitter selection: Ctrl+W = extend, Ctrl+Shift+W = shrink
-- Uses treesitter incremental node selection.
-- Bound in insert mode too: exits insert, selects, enters visual.
-------------------------------------------------------------------------------
local ts_sel_node = nil

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

-- Invalidate stale treesitter selection state when leaving a buffer
vim.api.nvim_create_autocmd("BufLeave", {
  callback = function() ts_sel_node = nil end,
})

-------------------------------------------------------------------------------
-- Escape: if popups/completion are open, close them and stay in insert mode.
-- Otherwise, pass through to normal mode (needed for :commands like :messages).
-------------------------------------------------------------------------------
map("i", "<Esc>", function()
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

-- Open directory via native KDE file dialog, then cd + refresh neo-tree.
-- NOTE: Shadows Neovim's built-in <C-o> (one-shot normal-mode command from
-- insert mode). The other keymaps in this file that use <C-o> as a prefix
-- string (e.g., <C-o>b) still work because they are distinct key sequences.
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

-- Replace in current file.
-- NOTE: Shadows Neovim's built-in <C-r> (insert from register). JetBrains
-- muscle memory wins here; use <C-r><C-r> or ":put" for register pasting.
map("i", "<C-r>", "<C-o>:%s/", { desc = "Replace in File" })

-- Opens the command line; user still types the line number + Enter.
map("i", "<C-g>", "<C-o>:", { desc = "Command Line" })

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
