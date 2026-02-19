-- Leader must be set before lazy
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Editor options
vim.opt.number = true
vim.opt.relativenumber = false

-- Merged sign+number column: diagnostic signs and line numbers share one
-- column so the gutter is ~2 cells narrower than having both separately.
-- Priority: cursor line -> line number; diagnostic line -> sign; else -> interval number.
local sign_icons = {
  [vim.diagnostic.severity.ERROR] = { icon = "E", hl = "DiagnosticSignError" },
  [vim.diagnostic.severity.WARN]  = { icon = "W", hl = "DiagnosticSignWarn" },
  [vim.diagnostic.severity.INFO]  = { icon = "I", hl = "DiagnosticSignInfo" },
  [vim.diagnostic.severity.HINT]  = { icon = "H", hl = "DiagnosticSignHint" },
}

function StatusCol()
  local lnum = vim.v.lnum
  local relnum = vim.v.relnum
  local is_cursor_line = (relnum == 0)

  -- Find highest-severity diagnostic on this line
  local diags = vim.diagnostic.get(0, { lnum = lnum - 1 })
  local sign = nil
  if #diags > 0 then
    local best_sev = math.huge
    for _, d in ipairs(diags) do
      if d.severity < best_sev then best_sev = d.severity end
    end
    sign = sign_icons[best_sev]
  end

  if is_cursor_line then
    return string.format("%%#LineNr#%4d ", lnum)
  elseif sign then
    return string.format("%%#%s# %s  ", sign.hl, sign.icon)
  else
    local nr = (lnum % 10 == 0) and tostring(lnum) or ""
    return string.format("%%#LineNr#%4s ", nr)
  end
end

vim.opt.statuscolumn = "%!v:lua.StatusCol()"

-- Only show line numbers for actual file buffers (not terminals, sidebars, etc.)
vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
  callback = function()
    local dominated_by_ft = {
      ["neo-tree"] = true, ["TelescopePrompt"] = true,
      ["help"] = true, ["qf"] = true, ["lazy"] = true, ["mason"] = true,
    }
    local bt = vim.bo.buftype
    local ft = vim.bo.filetype
    if bt ~= "" or dominated_by_ft[ft] then
      vim.wo.number = false
      vim.wo.relativenumber = false
      vim.wo.statuscolumn = ""
    else
      vim.wo.number = true
      vim.wo.relativenumber = false
      vim.wo.statuscolumn = "%!v:lua.StatusCol()"
    end
  end,
})

-- Redraw statuscolumn when cursor moves or diagnostics change so the
-- sign/number swap reflects the current cursor position immediately.
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "DiagnosticChanged" }, {
  callback = function() vim.cmd("redrawstatus") end,
})
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.smartindent = true
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "no"
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
  vim.o.guifont = "JetBrains Mono:h11"
  -- Visually equivalent to line-height:1.2 in CSS (GUI-only option)
  -- Reduced to 8 to make sure there's no black bar at the bottom.
  vim.opt.linespace = 8
  vim.g.neovide_opacity = 0.9
  vim.g.neovide_cursor_animation_length = 0
  vim.g.neovide_scroll_animation_length = 0.3
  vim.g.neovide_hide_mouse_when_typing = false
  vim.g.neovide_confirm_quit = false
  vim.g.neovide_remember_window_size = false
  vim.opt.cmdheight = 0
  vim.opt.laststatus = 2
  vim.g.neovide_padding_bottom = 0
end

-- virtual_lines renders each diagnostic on dedicated lines below the code.
-- This replaces virtual_text which appends to the end of the code line and
-- gets clipped at the window edge with no way to scroll (Neovim limitation).
-- However, virtual_lines itself also clips long messages because the
-- renderer uses virt_lines_overflow = 'scroll'. The format function below
-- works around this by manually inserting newlines so each segment fits
-- within the available window width.
-- Trade-off: virtual_lines consumes vertical space for every diagnostic in
-- the buffer simultaneously, which can push code down significantly in
-- files with many diagnostics. Use Ctrl+F1 (diagnostic float) for details.

-- Wraps a diagnostic message to fit within the virtual_lines rendering area.
-- The available width is: window_width - gutter - left_connectors - center(6).
-- Left connector width equals the diagnostic's column (display cells).
-- Continuation lines use 6 chars of padding instead of left+center.
local function wrap_diagnostic(diagnostic)
  local message = diagnostic.code
    and string.format("%s: %s", diagnostic.code, diagnostic.message)
    or diagnostic.message

  local win_width = vim.api.nvim_win_get_width(0)

  -- Gutter = merged sign+number column (auto-sized by Neovim via statuscolumn)
  local gutter = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].textoff

  -- First line: left connectors span the diagnostic column, center is 6 chars
  local col_offset = vim.fn.strdisplaywidth(
    (vim.api.nvim_buf_get_lines(0, diagnostic.lnum, diagnostic.lnum + 1, false)[1] or "")
      :sub(1, diagnostic.col)
  )
  -- Extra margin to account for rendering overhead that nvim_win_get_width
  -- does not reflect (e.g. Neovide padding, scrollbar, off-by-one in
  -- virtual line column accounting).
  local margin = 6
  local first_line_width = win_width - gutter - col_offset - 6 - margin
  -- Continuation lines are also indented to the diagnostic column
  local cont_line_width = win_width - gutter - col_offset - 6 - margin

  if first_line_width < 20 then first_line_width = cont_line_width end
  if cont_line_width < 20 then return message end

  local lines = {}
  local remaining = message
  local max_width = first_line_width

  while #remaining > 0 do
    if vim.fn.strdisplaywidth(remaining) <= max_width then
      table.insert(lines, remaining)
      break
    end

    -- Find the byte position where display width exceeds max_width
    local byte_pos = 0
    local display_width = 0
    while byte_pos < #remaining do
      local next_byte = byte_pos + 1
      -- Advance past multi-byte UTF-8 sequence
      local byte = remaining:byte(next_byte)
      if byte and byte >= 0xF0 then
        next_byte = byte_pos + 4
      elseif byte and byte >= 0xE0 then
        next_byte = byte_pos + 3
      elseif byte and byte >= 0xC0 then
        next_byte = byte_pos + 2
      end
      local char = remaining:sub(byte_pos + 1, next_byte)
      local char_width = vim.fn.strdisplaywidth(char)
      if display_width + char_width > max_width then break end
      display_width = display_width + char_width
      byte_pos = next_byte
    end

    if byte_pos == 0 then byte_pos = 1 end

    -- Prefer breaking at a word boundary (last space within the fitting portion)
    local break_pos = byte_pos
    local space_pos = remaining:sub(1, byte_pos):find("%s[^%s]*$")
    if space_pos then
      break_pos = space_pos
    end

    table.insert(lines, remaining:sub(1, break_pos))
    remaining = remaining:sub(break_pos + 1)
    max_width = cont_line_width
  end

  return table.concat(lines, "\n")
end

vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = { format = wrap_diagnostic },
  signs = false,
  underline = true,
  update_in_insert = false,
  float = { border = "rounded" },
})
