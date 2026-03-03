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
    vim.opt_local.spellcapcheck = [[.[?]\_[\])'"	 ]\+]]
    vim.cmd("compiler cargo")
    vim.bo.makeprg = "cargo"
    vim.bo.errorformat = [[%Eerror%m,%Wwarning%m,%C %f:%l:%c]]
  end,
})                                                                                  
