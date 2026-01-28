require("nvchad.configs.lspconfig").defaults()

-- Basic servers
local servers = { "html", "cssls", "ts_ls" }
vim.lsp.enable(servers)

-- Rust is handled by rustaceanvim plugin, not manual lspconfig 

vim.lsp.config.clangd = {
	cmd = { "clangd" },
	filetypes = { "c", "cpp", "objc", "objcpp" },
	root_markers = { "compile_commands.json", ".clangd", ".git" },
	on_attach = require("nvchad.configs.lspconfig").on_attach,
	capabilities = require("nvchad.configs.lspconfig").capabilities,
}

vim.lsp.enable("clangd")
