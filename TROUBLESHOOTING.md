# Troubleshooting

Hard-won lessons from debugging Neovim + Neovide, recorded here so we don't
re-learn them the hard way.

## Right-click / mouse event handling

### `mousemodel=popup_setpos` intercepts `<RightMouse>` at the C level

Neovim's default `mousemodel=popup_setpos` handles `<RightMouse>` entirely
in C code before any Lua or VimScript mapping gets a chance to run. No user
mapping — global or buffer-local — will ever fire for `<RightMouse>` or
`<RightRelease>` while this mouse model is active.

**Fix:** Set `vim.o.mousemodel = "extend"` and reimplement popup_setpos
behavior (move cursor, show popup) in your own `<RightRelease>` mapping.

### Cross-window right-clicks are silently dropped

With `popup_setpos`, right-clicking on a window that doesn't have focus
produces **no event at all** — no `MenuPopup`, no `WinEnter`, no `BufEnter`,
nothing. The click is silently consumed. This means the PopUp menu only ever
appears when the click lands in the already-focused window.

### Use `<RightRelease>`, not `<RightMouse>`, for showing menus

If you show a popup menu on `<RightMouse>` (button down), the subsequent
`<RightRelease>` (button up) immediately dismisses it. The user has to hold
the button down to keep the menu visible. Show the menu on `<RightRelease>`
instead, and map `<RightMouse>` to `<Nop>` to prevent the default behavior.

### `:popup PopUp` renders inside the current window

The `:popup` command positions the menu relative to the cursor inside the
current window and clips to that window's width. For narrow sidebars like
neo-tree (30 columns), this produces a tiny, unusable menu. Use nui.nvim's
`Menu` component instead — it renders as a floating window that isn't
constrained by the parent window's dimensions.

### Map across all modes

With `mousemodel=extend`, right-click events can arrive in any mode
(normal, visual, insert, etc.). Map `<RightMouse>` and `<RightRelease>` in
modes `n`, `v`, `i`, `x`, `s`, `o` to ensure consistent behavior.

## Neo-tree plugin internals

### Commands require `state.config`

Neo-tree's filesystem commands (`add`, `rename`, `delete`, etc.) expect
`state.config` to be a table. This field is normally set by neo-tree's
internal mapping handler in `ui/renderer.lua`. When calling commands from
outside that system (e.g., a custom context menu), you must set it yourself:

```lua
state.config = state.config or {}
```

Without this, commands crash with `attempt to index field 'config' (a nil
value)` in `get_folder_node`.

### Neovim's built-in `MenuPopup` autocmd conflicts with custom menus

Neovim ships a `MenuPopup` autocmd (in the `nvim.popupmenu` augroup) that
tries to enable/disable default PopUp items like "Go to definition" every
time a popup menu opens. If you replace the PopUp menu contents, this autocmd
errors with `E329: No menu "Go to definition"`. Suppress it with:

```lua
vim.api.nvim_create_augroup("nvim.popupmenu", { clear = true })
```

## Select mode clipboard (Ctrl+C / Ctrl+X)

### `\x1b` + `v` collapses select-mode selection before yanking

When switching from select mode to visual mode for clipboard operations,
using `normal! \x1bv` (Escape then `v`) first exits select mode to **normal
mode**, which collapses the selection. The subsequent `v` starts a new
characterwise visual selection at the cursor position, so `"+y` only yanks a
single character.

**Fix:** Use `normal! \x07` (`<C-g>`) instead, which toggles directly from
select mode to visual mode while **preserving the selection**. This applies
to both copy (`"+y`) and cut (`"+d`) handlers.

```lua
-- WRONG: collapses selection
vim.cmd("normal! \x1bv")

-- RIGHT: preserves selection
vim.cmd("normal! \x07")
```

## Debugging mouse events

When mouse events aren't behaving as expected, add file-based logging:

```lua
local LOG = vim.fn.stdpath("log") .. "/debug.log"
local function log(msg)
  local f = io.open(LOG, "a")
  if f then f:write(os.date("%H:%M:%S") .. " " .. msg .. "\n"); f:close() end
end
```

`vim.notify` and `print` are unreliable for mouse event debugging because
they can be swallowed by mode changes or popup rendering. Writing to a file
and tailing it (`tail -f`) in another terminal gives a reliable event trace.
