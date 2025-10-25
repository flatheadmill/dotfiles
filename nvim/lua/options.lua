require "nvchad.options"

-- add yours here!

local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!

-- Disable mouse completely
o.mouse = ""

-- Disable search highlighting
o.hlsearch = false
o.wildmode = 'longest:full,full'

-- Remove ! from spellcapcheck for Rust to handle //! doc comments
vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function()
    vim.opt_local.spellcapcheck = [[.[?]\_[\])'"	 ]\+]]
  end,
})
