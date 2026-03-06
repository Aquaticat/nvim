-- Capabilities shared by all LSP servers, extended by blink.cmp when available.
local function make_capabilities()
  local caps = vim.lsp.protocol.make_client_capabilities()
  local ok, blink = pcall(require, "blink.cmp")
  if ok then caps = blink.get_lsp_capabilities(caps) end
  -- Neovim 0.11 disables didChangeWatchedFiles on Linux because libuv's
  -- inotify wrapper can't do recursive watching without one handle per
  -- directory (blocks main thread on large trees). Enable it when a viable
  -- external watcher is available: inotifywait (native backend) or watchexec
  -- (custom backend injected below).
  if vim.fn.executable('inotifywait') == 1 or vim.fn.executable('watchexec') == 1 then
    caps.workspace.didChangeWatchedFiles.dynamicRegistration = true
  end
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

--region watchexec LSP file watcher backend
-- Neovim's built-in inotifywait backend is preferred when available.
-- When only watchexec is on PATH, inject a custom _watchfunc that spawns
-- `watchexec --only-emit-events --emit-events-to stdio` and parses its
-- simple `<event>:<path>` output format. Runs as an external process so
-- it never blocks Neovim's main thread.
if vim.fn.executable('inotifywait') ~= 1 and vim.fn.executable('watchexec') == 1 then
  local watch = vim._watch
  local watchfiles = require('vim.lsp._watchfiles')

  ---@param path string Directory to watch recursively
  ---@param opts vim._watch.Opts? Watch options (include/exclude patterns)
  ---@param callback vim._watch.Callback Callback for file events
  ---@return fun() cancel Stops the watcher
  local function watchexec_backend(path, opts, callback)
    local obj = vim.system({
      'watchexec',
      '--only-emit-events',
      '--emit-events-to', 'stdio',
      '--no-meta',
      '-w', path,
    }, {
      stdout = function(err, data)
        if err then error(err) end
        for line in vim.gsplit(data or '', '\n', { plain = true, trimempty = true }) do
          local event, filepath = line:match('^(%w+):(.+)$')
          if not event or not filepath then goto continue end

          -- Apply include/exclude filters
          if opts and opts.include_pattern and opts.include_pattern:match(filepath) == nil then
            goto continue
          end
          if opts and opts.exclude_pattern and opts.exclude_pattern:match(filepath) ~= nil then
            goto continue
          end

          local change_type
          if event == 'create' then
            change_type = watch.FileChangeType.Created
          elseif event == 'modify' then
            change_type = watch.FileChangeType.Changed
          elseif event == 'remove' then
            change_type = watch.FileChangeType.Deleted
          end

          if change_type then
            callback(filepath, change_type)
          end

          ::continue::
        end
      end,
      stderr = function(err, data)
        if err then error(err) end
        if data and #vim.trim(data) > 0 then
          vim.schedule(function()
            vim.notify('watchexec: ' .. data, vim.log.levels.ERROR)
          end)
        end
      end,
    })

    return function()
      obj:kill(2)
    end
  end

  watchfiles._watchfunc = watchexec_backend
end
--endregion watchexec LSP file watcher backend

--region BufWritePost LSP notify fallback
-- Last resort when neither inotifywait nor watchexec is available.
-- Manually notify all LSP clients about saved files so servers like tsgo
-- pick up dependency changes. Only covers in-editor saves, not external
-- changes (git checkout, CI artifacts, etc.).
if vim.fn.executable('inotifywait') ~= 1 and vim.fn.executable('watchexec') ~= 1 then
  vim.api.nvim_create_autocmd("BufWritePost", {
    callback = function(ev)
      local uri = vim.uri_from_fname(vim.api.nvim_buf_get_name(ev.buf))
      local params = {
        changes = {
          { uri = uri, type = vim.lsp.protocol.FileChangeType.Changed },
        },
      }
      for _, client in ipairs(vim.lsp.get_clients()) do
        client:notify("workspace/didChangeWatchedFiles", params)
      end
    end,
  })
end
--endregion BufWritePost LSP notify fallback

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
