require("nvchad.configs.lspconfig").defaults()

-- Basic servers
local servers = { "html", "cssls" }
vim.lsp.enable(servers)

-- Rust is handled by rustaceanvim plugin, not manual lspconfig 
