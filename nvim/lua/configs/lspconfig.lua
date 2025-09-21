require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"

-- Basic servers using vim.lsp.enable
local servers = { "html", "cssls" }
vim.lsp.enable(servers)

-- Rust analyzer with custom settings
lspconfig.rust_analyzer.setup {
  on_attach = require("nvchad.configs.lspconfig").on_attach,
  on_init = require("nvchad.configs.lspconfig").on_init,
  capabilities = require("nvchad.configs.lspconfig").capabilities,
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = true,
      },
      checkOnSave = {
        enable = false,
      },
    },
  },
} 
