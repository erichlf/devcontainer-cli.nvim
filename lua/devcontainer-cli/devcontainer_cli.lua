-- Copyright (c) 2024 Erich L Foster
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local config = require("devcontainer-cli.config")
local utils = require("devcontainer-cli.devcontainer_utils")

local M = {}

local function define_autocommands()
  local au_id = vim.api.nvim_create_augroup("devcontainer.docker.terminal", {})
  vim.api.nvim_create_autocmd("UILeave", {
    group = au_id,
    callback = function()
      -- It connects with the Devcontainer just after quiting neovim.
      -- TODO: checks that the devcontainer is not already connected
      -- TODO: checks that there is a devcontainer running
      vim.schedule(
        function()
          local command = config.nvim_plugin_folder .. "/bin/connect_to_devcontainer.sh"
          vim.fn.jobstart(command, { detach = true })
        end
      )
    end,
  })
end

-- executes a given command in the devcontainer of the current project directory
---@param opts (table) options for executing the command
function M.exec(opts)
  local args = opts.args
  vim.validate({ args = { args, "string", true } })

  local parsed = {
    cmd = nil,
    direction = nil,
    size = nil,
  }

  if args ~= nil then
    parsed = utils.parse(args)

    vim.validate({
      cmd = { parsed.cmd, "string", true },
      direction = { parsed.direction, "string", true },
      size = { parsed.size, "number", true },
    })
    if parsed.cmd == nil and parsed.direction == nil and parsed.size == nil then
      parsed.cmd = args
    end
  end

  utils.exec(parsed.cmd, parsed.direction, parsed.size)
end

-- toggle the current devcontainer window
function M.toggle()
  utils.toggle()
end

-- bring up the devcontainer in the current project directory
function M.up()
  utils.bringup()
end

-- Thanks to the autocommand executed after leaving the UI, after closing the
-- neovim window the devcontainer will be automatically open in a new terminal
function M.connect()
  define_autocommands()
  vim.cmd("wqa")
end

return M
