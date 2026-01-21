local cmp = require "cmp"

-- Get NvChad's default cmp config
local default_opts = require "nvchad.configs.cmp"

-- Override just the mappings to make Tab confirm instead of cycle
default_opts.mapping["<Tab>"] = cmp.mapping.confirm { select = true }
default_opts.mapping["<S-Tab>"] = cmp.mapping.select_prev_item()

-- Disable auto-popup, only trigger with Ctrl+Space
default_opts.completion = {
  autocomplete = false
}

return default_opts
