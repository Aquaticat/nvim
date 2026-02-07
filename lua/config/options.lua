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

-- Inline diagnostics
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  float = { border = "rounded" },
})
