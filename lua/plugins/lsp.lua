-- Capabilities shared by all LSP servers, extended by blink.cmp when available.
local function make_capabilities()
  local caps = vim.lsp.protocol.make_client_capabilities()
  local ok, blink = pcall(require, "blink.cmp")
  if ok then caps = blink.get_lsp_capabilities(caps) end
  return caps
end

--region LspAttach keymaps - JetBrains-style bindings in insert mode
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local buf = ev.buf
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
    end

    map("i", "<C-b>", function()                                             -- Ctrl+B
      vim.cmd("stopinsert")
      vim.lsp.buf.definition()
    end, "Go to Definition")
    map("i", "<A-F7>", function()                                            -- Alt+F7
      vim.cmd("stopinsert")
      vim.lsp.buf.references()
    end, "Find Usages")
    map("i", "<C-q>", vim.lsp.buf.hover, "Quick Documentation")             -- Ctrl+Q
    map("i", "<C-p>", vim.lsp.buf.signature_help, "Parameter Info")          -- Ctrl+P
    map("i", "<A-CR>", vim.lsp.buf.code_action, "Code Action")              -- Alt+Enter
    map("i", "<S-F6>", vim.lsp.buf.rename, "Rename Symbol")                 -- Shift+F6
    map({ "i", "v" }, "<C-A-l>", function()                                  -- Ctrl+Alt+L
      vim.lsp.buf.format({ async = true })
    end, "Reformat Code")
    map("i", "<F2>", function() vim.diagnostic.goto_next() end, "Next Diagnostic")
    map("i", "<S-F2>", function() vim.diagnostic.goto_prev() end, "Previous Diagnostic")
    map("i", "<C-F1>", vim.diagnostic.open_float, "Error Description")       -- Ctrl+F1

    -- Enable inlay hints for this buffer (pcall guards older Neovim versions
    -- where the API signature differs or doesn't exist)
    pcall(function() vim.lsp.inlay_hint.enable(true, { bufnr = buf }) end)
  end,
})
--endregion LspAttach keymaps

-- Per-server config via Neovim 0.11 native vim.lsp.config().
-- mason-lspconfig's automatic_enable calls vim.lsp.enable() for installed
-- servers, which picks up these configs automatically.
vim.lsp.config("*", {
  capabilities = make_capabilities(),
})

-- tsgo's parseInlayHints expects VSCode-style nested objects under
-- "inlayHints" (e.g. parameterNames.enabled), not flat includeInlay* keys.
-- The flat keys only work at the section root via ParseWorker's default case.
local tsgo_inlay_hints = {
  parameterNames = { enabled = "all", suppressWhenArgumentMatchesName = false },
  parameterTypes = { enabled = true },
  variableTypes = { enabled = true, suppressWhenTypeMatchesName = false },
  propertyDeclarationTypes = { enabled = true },
  functionLikeReturnTypes = { enabled = true },
  enumMemberValues = { enabled = true },
}

vim.lsp.config("tsgo", {
  settings = {
    typescript = { inlayHints = tsgo_inlay_hints },
    javascript = { inlayHints = tsgo_inlay_hints },
  },
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
      ensure_installed = { "lua_ls", "dprint", "oxlint", "tsgo" },
      -- automatic_enable = true is the default: installed servers get
      -- vim.lsp.enable()'d automatically using the vim.lsp.config() above.
    },
  },
}
