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

-- Toggle LSP inlay hints for clippy only
map("n", "<Space>th", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local current = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
  vim.lsp.inlay_hint.enable(not current, { bufnr = bufnr })
end, { desc = "Toggle inlay hints" })

-- Toggle Clippy vs basic check for rust-analyzer
map("n", "<Space>tc", function()
  local clients = vim.lsp.get_clients({ name = "rust-analyzer" })
  if #clients == 0 then
    vim.notify("rust-analyzer not active", vim.log.levels.WARN)
    return
  end

  local client = clients[1]
  local settings = client.config.settings or {}

  -- Ensure structure exists
  settings["rust-analyzer"] = settings["rust-analyzer"] or {}
  settings["rust-analyzer"].check = settings["rust-analyzer"].check or {}

  -- Toggle
  local current = settings["rust-analyzer"].check.command
  local new_cmd = (current == "clippy") and "check" or "clippy"
  settings["rust-analyzer"].check.command = new_cmd

  -- Notify server of config change (no restart needed)
  client.notify("workspace/didChangeConfiguration", { settings = settings })

  vim.notify("rust-analyzer check: " .. new_cmd, vim.log.levels.INFO)
end, { desc = "Toggle Clippy/check" })

-- Toggle LSP inlay hints
map("n", "<Space>td", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
