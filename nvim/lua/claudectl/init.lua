local M = {}

function M.find_terminal()
    for _, w in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(w)
        if vim.api.nvim_buf_get_name(buf):match("%.local/bin/claude$") then
            return w
        end
    end
end

function M.find_code_win()
    for _, w in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(w)
        if vim.bo[buf].buftype ~= "terminal" then
            return w
        end
    end
end

function M.show(file, line)
    local term = M.find_terminal()
    local code = M.find_code_win()
    if not code then return "no code window found" end

    vim.api.nvim_set_current_win(code)
    vim.cmd.edit(vim.fn.expand(file))
    if line then
        vim.api.nvim_win_set_cursor(code, {line, 0})
        vim.api.nvim_win_call(code, function()
            vim.cmd("normal! zz")
        end)
    end
    if term then
        vim.api.nvim_set_current_win(term)
    end
end

return M
