-- Treesitter: enable built-in highlight and indent (nvim-treesitter v2 is
-- parser-manager only; Neovim 0.11+ handles highlight/indent natively).
vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    -- Try to attach treesitter highlight; silently skip if no parser installed
    pcall(vim.treesitter.start, ev.buf)
  end,
})

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
