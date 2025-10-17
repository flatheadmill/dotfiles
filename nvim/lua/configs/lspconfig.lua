require("nvchad.configs.lspconfig").defaults()

-- Basic servers
local servers = { "html", "cssls" }
vim.lsp.enable(servers)

-- Rust analyzer with custom settings using new vim.lsp.config
vim.lsp.config.rust_analyzer = {
  cmd = { 'rust-analyzer' },
  root_markers = { 'Cargo.toml', 'rust-project.json' },
  on_attach = require("nvchad.configs.lspconfig").on_attach,
  on_init = require("nvchad.configs.lspconfig").on_init,
  capabilities = require("nvchad.configs.lspconfig").capabilities,
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = true,
      },
      checkOnSave = {
        enable = true,
      },
    },
  },
}

vim.lsp.enable('rust_analyzer') 
