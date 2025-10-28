require "nvchad.options"

-- add yours here!

local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!

-- Disable mouse completely
o.mouse = ""

-- Disable search highlighting
o.hlsearch = false
o.wildmode = 'longest:full,full'

-- Disable persistent undo (file-based undo history)
o.undofile = false

-- Rust-specific settings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function()
    -- Remove ! from spellcapcheck for //! doc comments
    vim.opt_local.spellcapcheck = [[.[?]\_[\])'"	 ]\+]]
    -- Set cargo as compiler for :make! build/test/check/clippy
    vim.cmd("compiler cargo")
  end,
})
