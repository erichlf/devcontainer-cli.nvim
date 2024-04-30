local M = {}

local start = vim.health.start or vim.health.report_start
local ok = vim.health.ok or vim.health.report_ok
local warn = vim.health.warn or vim.health.report_warn
local error = vim.health.error or vim.health.report_error

local function verify_binary(binary_name)
  if vim.fn.executable(binary_name) ~= 1 then
    error(("`%s` executable not found."):format(binary_name), ("Install %s"):format(binary_name))
  else
    ok(("`%s` executable found."):format(binary_name))
  end
end

local function verify_plugin_dependencies(plugin_name)
  if require(plugin_name) then
    ok(("`%s` plugin found."):format(plugin_name))
  else
    error(("`%s` plugin not found."):format(plugin_name), ("Add %s to dependencies in Lazy.git"):format(plugin_name))
  end
end

-- TODO: create a check for DevcontainerUp, this needs to be done after
-- creating the ability to stop a container
-- TODO: create a check for DevcontainerExec

function M.check()
  start("devcontainer-cli")
  local required_binaries = {
    "docker",
    "devcontainer",
  }
  local plugin_dependencies = {
    "toggleterm",
  }
  for _, bin_name in ipairs(required_binaries) do
    verify_binary(bin_name)
  end
  for _, plugin_name in ipairs(plugin_dependencies) do
    verify_plugin_dependencies(plugin_name)
  end
end

return M
