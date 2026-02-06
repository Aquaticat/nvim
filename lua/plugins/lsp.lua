-- Capabilities shared by all LSP servers, extended by blink.cmp when available.
local function make_capabilities()
  local caps = vim.lsp.protocol.make_client_capabilities()
  local ok, blink = pcall(require, "blink.cmp")
  if ok then caps = blink.get_lsp_capabilities(caps) end
  return caps
end

-- JetBrains-style LSP keymaps, applied on every LspAttach event.
-- All bound in insert mode (primary editing mode) -- GUI editor mode.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local buf = ev.buf
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
    end

    -- Ctrl+B: go to definition (leaves insert to jump, re-enters at target)
    map("i", "<C-b>", function()
      vim.cmd("stopinsert")
      vim.lsp.buf.definition()
    end, "Go to Definition")

    -- Alt+F7: find usages
    map("i", "<A-F7>", function()
      vim.cmd("stopinsert")
      vim.lsp.buf.references()
    end, "Find Usages")

    -- Ctrl+Q: quick documentation (hover popup)
    map("i", "<C-q>", vim.lsp.buf.hover, "Quick Documentation")

    -- Ctrl+P: parameter info / signature help
    map("i", "<C-p>", vim.lsp.buf.signature_help, "Parameter Info")

    -- Alt+Enter: code action
    map("i", "<A-CR>", vim.lsp.buf.code_action, "Code Action")

    -- Shift+F6: rename symbol
    map("i", "<S-F6>", vim.lsp.buf.rename, "Rename Symbol")

    -- Ctrl+Alt+L: reformat
    map({ "i", "v" }, "<C-A-l>", function()
      vim.lsp.buf.format({ async = true })
    end, "Reformat Code")

    -- F2 / Shift+F2: next/prev diagnostic
    map("i", "<F2>", function()
      vim.diagnostic.goto_next()
    end, "Next Diagnostic")
    map("i", "<S-F2>", function()
      vim.diagnostic.goto_prev()
    end, "Previous Diagnostic")

    -- Ctrl+F1: error description float
    map("i", "<C-F1>", vim.diagnostic.open_float, "Error Description")

    -- Enable inlay hints for this buffer
    if vim.lsp.inlay_hint then
      vim.lsp.inlay_hint.enable(true, { bufnr = buf })
    end
  end,
})

-- Per-server config via Neovim 0.11 native vim.lsp.config().
-- mason-lspconfig's automatic_enable calls vim.lsp.enable() for installed
-- servers, which picks up these configs automatically.
vim.lsp.config("*", {
  capabilities = make_capabilities(),
})

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        checkThirdParty = false,
        library = { vim.env.VIMRUNTIME },
      },
      diagnostics = { globals = { "vim" } },
      telemetry = { enable = false },
    },
  },
})

return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    opts = {},
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      -- Auto-install servers when you open a relevant file type.
      -- Add more servers here as needed.
      ensure_installed = { "lua_ls" },
      -- automatic_enable = true is the default: installed servers get
      -- vim.lsp.enable()'d automatically using the vim.lsp.config() above.
    },
  },
}
