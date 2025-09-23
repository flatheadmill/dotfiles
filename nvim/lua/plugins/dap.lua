return {
  {
    "mfussenegger/nvim-dap",
    lazy = false,  -- Load immediately, don't wait
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap = require("dap")

      -- CodeLLDB adapter
      dap.adapters.codelldb = {
        type = 'server',
        port = "${port}",
        executable = {
          command = vim.fn.expand("~/.local/share/nvim/mason/packages/codelldb/extension/adapter/codelldb"),
          args = {"--port", "${port}"},
        }
      }

      -- Rust configuration
      dap.configurations.rust = {
        {
          name = "Debug",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/', 'file')
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
        },
      }

      -- Shift + Function key bindings for debugging
      vim.keymap.set('n', '<leader>kf', dap.continue, { desc = "Debug: Start/Continue" })
      vim.keymap.set('n', '<leader>kd', dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
      vim.keymap.set('n', '<C-k>d', dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
      vim.keymap.set('n', '-', dap.step_over, { desc = "Debug: Step Over" })
      vim.keymap.set('n', '=', dap.step_into, { desc = "Debug: Step Into" })
      vim.keymap.set('n', '<S-=>', dap.step_out, { desc = "Debug: Step Out" })

      -- Register which-key group for debug menu
      local wk_ok, wk = pcall(require, "which-key")
      if wk_ok then
        wk.add({
          { "<leader>k", group = "󰃤 Debug" },
        })
      end

      -- Auto-open UI
      require("dapui").setup()
      require("nvim-dap-virtual-text").setup()

      -- Auto open/close DAP UI
      local dapui = require("dapui")
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },
}
