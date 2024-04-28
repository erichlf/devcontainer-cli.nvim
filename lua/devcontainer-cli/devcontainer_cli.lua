local config = require("devcontainer-cli.config")
local devcontainer_utils = require("devcontainer-cli.devcontainer_utils")

local M = {}

local function define_autocommands()
  local au_id = vim.api.nvim_create_augroup("devcontainer.docker.terminal", {})
  vim.api.nvim_create_autocmd("UILeave", {
    group = au_id,
    callback = function()
      -- It connects with the Devcontainer just after quiting neovim.
      -- TODO: checks that the devcontainer is not already connected
      -- TODO: checks that there is a devcontainer running
      vim.schedule(function()
        local command = config.nvim_plugin_folder .. "/bin/connect_to_devcontainer.sh"
        vim.fn.jobstart(command, { detach = true })
      end)
    end,
  })
end

-- executes a given command in the devcontainer of the current project directory
---@param opts (table) options for executing the command
function M.exec(opts)
  vim.validate({ args = { opts.args, "string" } })
  if opts.args == nil or opts.args == "" then
    devcontainer_utils.exec()
  else
    devcontainer_utils.exec_cmd(opts.args)
  end
end

-- bring up the devcontainer in the current project directory
function M.up()
  devcontainer_utils.bringup(vim.loop.cwd())
end

-- Thanks to the autocommand executed after leaving the UI, after closing the
-- neovim window the devcontainer will be automatically open in a new terminal
function M.connect()
  define_autocommands()
  vim.cmd("wqa")
end

return M
