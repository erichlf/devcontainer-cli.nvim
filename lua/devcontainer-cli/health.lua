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

local start = vim.health.start or vim.health.start
local ok = vim.health.ok or vim.health.ok
local error = vim.health.error or vim.health.error

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
