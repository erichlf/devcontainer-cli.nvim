local remote_nvim = require("remote-nvim")
local utils = require("remote-nvim.utils")
local M = {}

local function verify_binary(binary_name)
  local succ, _ = pcall(utils.find_binary, binary_name)
  if not succ then
    vim.health.error(("`%s` executable not found."):format(binary_name))
  else
    vim.health.ok(("`%s` executable found."):format(binary_name))
  end
end
-- TODO: create a test that checks that a devcontainer can be brought up, 
-- this needs to be done after creating the ability to stop a container
-- TODO: create a test that checks that a command can be executed within the 
-- running container

function M.check()
  vim.health.start("devcontainer_cli")
  local required_binaries = {
    "docker",
    "devcontainer-cli",
  }
  for _, bin_name in ipairs(required_binaries) do
    verify_binary(bin_name)
  end
end

return M
