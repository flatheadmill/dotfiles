require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })

-- Terminal mode: Ctrl+q to escape to normal mode
map("t", "<C-q>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- Unmap Ctrl+x in terminal mode (used for Claude CLI interrupt)
vim.keymap.del("t", "<C-x>")

-- Terminal mode: Ctrl+w also escapes to normal mode (for quick window switching)
-- map("t", "<C-w>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- Quick file operations in same directory as current buffer
map("n", ",e", ":edit <C-R>=expand('%:p:h') . '/' <CR>", { desc = "Edit file in same dir" })
map("n", ",s", ":split <C-R>=expand('%:p:h') . '/' <CR>", { desc = "Split file in same dir" })

-- Toggle LSP inlay hints
map("n", "<Space>th", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local current = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
  vim.lsp.inlay_hint.enable(not current, { bufnr = bufnr })
end, { desc = "Toggle inlay hints" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
