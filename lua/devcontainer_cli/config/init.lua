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
  -- If set to True [default_value] it can take extra time as you force to start from scratch
  remove_existing_container = true,
  -- dependencies that have to be installed in the devcontainer (remoteUser = root)
  dotfiles_repository = "git@github.com:erichlf/dotfiles",
  -- branch to checkout for repositories (this is a feature not supported by devcontainers in general, but we do)
  dotfiles_repository = "devcontainer",
  -- directory for the setup environment
  dotfiles_targetPath = "~/dotfiles",
  -- command that's executed for installed the dependencies from the setup_environment_repo
  dotfiles_installCommand = "install.sh",
}

local options

function ConfigModule.setup(opts)
  opts = vim.tbl_deep_extend("force", default_config, opts or {})
  options = opts
end

return setmetatable(ConfigModule, {
  __index = function(_, key)
    if options == nil then
      return vim.deepcopy(default_config)[key]
    end
    return options[key]
  end,
})
