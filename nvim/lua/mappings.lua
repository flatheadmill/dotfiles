require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })

-- Terminal mode: Ctrl+q to escape to normal mode
map("t", "<C-q>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- Terminal mode: Ctrl+w also escapes to normal mode (for quick window switching)
map("t", "<C-w>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- Quick file operations in same directory as current buffer
map("n", ",e", ":edit <C-R>=expand('%:p:h') . '/' <CR>", { desc = "Edit file in same dir" })
map("n", ",s", ":split <C-R>=expand('%:p:h') . '/' <CR>", { desc = "Split file in same dir" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
