# Neovim Config

A Neovim configuration designed to behave like a JetBrains IDE, with insert-mode-first keymaps and GUI editor conventions. Built for [Neovide](https://neovide.dev/).

## Requirements

- [Neovide](https://neovide.dev/)
- Neovim 0.11+
- `tree-sitter` CLI (for parser compilation)
- [JetBrains Mono](https://www.jetbrains.com/lp/mono/) font

## Structure

```
init.lua                    -- Bootstrap lazy.nvim, load config modules
lua/
  config/
    options.lua             -- Editor options, Neovide settings, diagnostics
    keymaps.lua             -- All insert-mode-primary keymaps (GUI editor mode)
    autocmds.lua            -- Treesitter highlight, auto-insert, smart mouse click
    colorscheme.lua         -- Custom dark theme (#ccc on #000, One Dark accents)
  plugins/
    lsp.lua                 -- Mason + mason-lspconfig + LSP keymaps (LspAttach)
    blink-cmp.lua           -- Autocompletion (blink.cmp + friendly-snippets)
    neo-tree.lua            -- File tree (left panel, opens on startup)
    telescope.lua           -- Fuzzy finder (files, grep, buffers, symbols)
    treesitter.lua          -- Parser manager (v2 API, auto-installs parsers)
    colorscheme.lua         -- Placeholder (theme is in config/colorscheme.lua)
```

## Key Design Decisions

- **Insert-mode-first**: The editor auto-enters insert mode in file buffers. All keymaps (navigation, LSP, search) are bound in insert mode to match JetBrains muscle memory.
- **JetBrains Windows keymap**: Ctrl+C/X/V clipboard, Ctrl+Z/Shift+Ctrl+Z undo/redo, Ctrl+D duplicate line, Ctrl+Y delete line, Ctrl+/ toggle comment, etc.
- **Treesitter selection**: Ctrl+W extends, Ctrl+Shift+W shrinks (using treesitter node hierarchy).
- **Plugin management**: [lazy.nvim](https://github.com/folke/lazy.nvim) with pinned versions for stability.

## Key Bindings

### Navigation & Editing (Insert Mode)

- `Ctrl+S` -- Save all
- `Ctrl+Z` / `Ctrl+Shift+Z` -- Undo / Redo
- `Ctrl+D` -- Duplicate line
- `Ctrl+Y` -- Delete line
- `Ctrl+/` -- Toggle comment
- `Ctrl+F` -- Find in file
- `Ctrl+R` -- Replace in file
- `Ctrl+W` -- Extend selection (treesitter)
- `Alt+Shift+Up/Down` -- Move line up/down
- `Home` / `End` -- Start/end of line
- `Ctrl+Left/Right` -- Word jump

### Search (Telescope)

- `Ctrl+Shift+N` -- Find file
- `Ctrl+Shift+F` -- Find in files (live grep)
- `Ctrl+E` -- Recent files
- `Ctrl+Tab` -- Switch buffer
- `Ctrl+F12` -- File structure (LSP symbols)
- `Ctrl+Shift+A` -- Find action
- `Double-Shift` (F20) -- Search everywhere (requires external custom scripts those differ from environment to environment to map Double-Shift to send F20 via RPC)

### LSP (Insert Mode)

- `Ctrl+B` -- Go to definition
- `Alt+F7` -- Find usages
- `Ctrl+Q` -- Quick documentation
- `Ctrl+P` -- Parameter info
- `Alt+Enter` -- Code action
- `Shift+F6` -- Rename symbol
- `Ctrl+Alt+L` -- Reformat code
- `F2` / `Shift+F2` -- Next/prev diagnostic

### File Tree (Neo-tree)

- `Alt+1` -- Toggle file tree
- `Alt+F1` -- Reveal current file

