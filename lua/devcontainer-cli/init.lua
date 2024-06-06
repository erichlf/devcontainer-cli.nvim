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

local M = {}

local devcontainer_cli = require("devcontainer-cli.devcontainer_cli")
local config = require("devcontainer-cli.config")
local log = require("devcontainer-cli.log")

-- setup the devcontainer-cli plugin
---@param opts (table) the options to set (see config/init.lua)
function M.setup(opts)

  log.debug("Setting up devcontainer-cli")
  config.setup(opts)

  log.debug("Creating devcontainer-cli user commands")
  -- Docker
  vim.api.nvim_create_user_command(
    "DevcontainerUp",
    devcontainer_cli.up,
    {
      nargs = 0,
      desc = "Bringup devcontainer.",
    }
  )

  vim.api.nvim_create_user_command(
    "DevcontainerExec",
    devcontainer_cli.exec,
    {
      nargs = "?",
      desc = "Execute command in devcontainer.",
    }
  )

  vim.api.nvim_create_user_command(
    "DevcontainerToggle",
    devcontainer_cli.toggle,
    {
      nargs = 0,
      desc = "Toggle the current devcontainer window.",
    }
  )

  vim.api.nvim_create_user_command(
    "DevcontainerConnect",
    devcontainer_cli.connect,
    {
      nargs = 0,
      desc = "Connect to devcontainer.",
    }
  )

  vim.api.nvim_create_user_command(
    "DevcontainerDown",
    devcontainer_cli.down,
    {
      nargs = 0,
      desc = "Kill the current devcontainer.",
    }
  )

  log.debug("Finished setting up devcontainer-cli")
end

return M
