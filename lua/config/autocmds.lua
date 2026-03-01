--region Treesitter highlight - attach native TS highlight on FileType
-- nvim-treesitter v2 is parser-manager only; Neovim 0.11+ handles
-- highlight/indent natively.
vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    -- Try to attach treesitter highlight; silently skip if no parser installed
    pcall(vim.treesitter.start, ev.buf)
  end,
})
--endregion Treesitter highlight

--region GUI editor mode - auto-insert in file buffers, smart mouse click
-- Neovide bug/limitation: clicking neo-tree from insert mode doesn't work.
-- Workaround: intercept <LeftMouse> in insert mode -- if the click target is
-- a non-file window (neo-tree, telescope, etc.), stopinsert first so the
-- click lands in normal mode where those plugins expect it. If the click is
-- within a file buffer, stay in insert mode.
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

-- NON-ACTIONABLE: This defer_fn(50ms) approach is inherently racy -- if another
-- autocmd or plugin fires between the defer and the mode check, insert mode
-- could engage unexpectedly. However, immediate startinsert conflicts with
-- plugin windows that expect normal mode on BufEnter. The 50ms delay is the
-- least-bad compromise: it lets plugin autocmds settle before we check context.
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
--endregion GUI editor mode

--region MRU buffer tracking - ordered list for Ctrl+Tab cycling
-- Tracks file buffers in most-recently-used order. The list is a global so
-- keymaps.lua can read it for Ctrl+Tab / Ctrl+Shift+Tab instant cycling.
_G._mru_bufs = _G._mru_bufs or {}

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= "" then return end
    -- Move this buffer to the front of the MRU list
    local list = _G._mru_bufs
    for i, b in ipairs(list) do
      if b == ev.buf then
        table.remove(list, i)
        break
      end
    end
    table.insert(list, 1, ev.buf)
  end,
})

-- Prune deleted buffers lazily (on BufDelete)
vim.api.nvim_create_autocmd("BufDelete", {
  callback = function(ev)
    local list = _G._mru_bufs
    for i, b in ipairs(list) do
      if b == ev.buf then
        table.remove(list, i)
        break
      end
    end
  end,
})
--endregion MRU buffer tracking

--region File system watcher - immediate reload on external changes
-- Uses libuv fs_event to get OS-level file change notifications.
-- Attaches a watcher per file buffer; detaches on BufDelete/BufWipeout.
-- When a change is detected, schedules checktime on the main loop so
-- Neovim reloads the buffer contents (respects autoread).
local watched = {}

local function attach_watcher(buf)
  if watched[buf] then return end
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" or vim.fn.filereadable(path) ~= 1 then return end

  local handle = vim.uv.new_fs_event()
  if not handle then return end

  local flags = { recursive = false }
  handle:start(path, flags, function(err)
    if err then return end
    -- Schedule on main loop -- Neovim API is not thread-safe
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(buf) then
        handle:stop()
        handle:close()
        watched[buf] = nil
        return
      end
      vim.api.nvim_buf_call(buf, function()
        vim.cmd("silent! checktime")
      end)
    end)
  end)

  watched[buf] = handle
end

local function detach_watcher(buf)
  local handle = watched[buf]
  if handle then
    handle:stop()
    if not handle:is_closing() then handle:close() end
    watched[buf] = nil
  end
end

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(ev) attach_watcher(ev.buf) end,
})

vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
  callback = function(ev) detach_watcher(ev.buf) end,
})

-- Re-attach after :write since some OS/fs combos replace the inode on save
vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function(ev)
    detach_watcher(ev.buf)
    attach_watcher(ev.buf)
  end,
})
--endregion File system watcher

-- NOT POSSIBLE: "hover to show info" (mouse-hover triggers LSP hover popup).
-- Neovim has no mouse-hover event -- CursorHold tracks the text cursor, not
-- the mouse pointer. CursorHoldI-based workarounds were tried but the hover
-- float's background lingers because Neovim doesn't reliably dismiss
-- non-focusable floats on insert-mode cursor movement. Use Ctrl+Q (mapped in
-- lsp.lua) for on-demand hover instead.
