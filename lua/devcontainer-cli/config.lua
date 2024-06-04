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

local ConfigModule = {}
local file_path = debug.getinfo(1).source:sub(2)
local default_config = {
  -- whather to verify that the final devcontainer should be run
  interactive = false,
  -- use the .devcontainer directory closest to root in the directory tree
  toplevel = true,
  -- Folder where the nvim-devcontainer-cli is installed
  nvim_plugin_folder = file_path:gsub("init.lua", "") .. "../../../",
  -- Remove existing container each time DevcontainerUp is executed
  -- If set to True [default_value] it can take extra time as you force to
  -- start from scratch
  remove_existing_container = true,
  -- dotfiles to be downloaded
  dotfiles_repository = "git@github.com:erichlf/dotfiles",
  -- branch to checkout for repositories (this is a feature not supported by
  -- devcontainers in general, but we do)
  dotfiles_branch = "main",
  -- directory for the setup environment
  dotfiles_targetPath = "~/dotfiles",
  -- command that's executed for installed the dependencies from the
  -- setup_environment_repo
  dotfiles_installCommand = "install.sh",
  -- The number of columns to wrap text at
  terminal_columns = 80,
  -- The particular binary to use for connecting to in the devcontainer
  -- Most likely this should remain nvim
  nvim_binary = "nvim",
  -- The shell to use for executing command. Available sh, bash, zsh or any
  -- other that uses '-c' to signify a command is to follow
  shell = 'bash',
}

local options

function ConfigModule.setup(opts)
  opts = vim.tbl_deep_extend("force", default_config, opts or {})
  options = opts
end

return setmetatable(ConfigModule,
  {
    __index = function(_, key)
      if options == nil then
        return vim.deepcopy(default_config)[key]
      end
      return options[key]
    end,
  }
)
