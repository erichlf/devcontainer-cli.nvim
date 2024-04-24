local config = require("devcontainer_cli.config")
local windows_utils = require("devcontainer_cli.windows_utils")
local folder_utils = require("devcontainer_cli.folder_utils")

local M = {}

-- window management variables
local prev_win = -1
local win = -1
local buffer = -1

-- window the created window detaches set things back to -1
local on_detach = function()
  prev_win = -1
  win = -1
  buffer = -1
end

-- on_fail callback
-- @param exit_code the exit code from the failed job
local on_fail = function(exit_code)
  vim.notify(
      "Devcontainer process has failed! exit_code: " .. exit_code,
      vim.log.levels.ERROR
  )

  vim.cmd("silent! :checktime")
end

local on_success = function()
    vim.notify("Devcontainer process succeeded!", vim.log.levels.INFO)
end

-- on_exit callback function to delete the open buffer when devcontainer exits 
-- in a neovim terminal
-- @param job_id the id of the running job
-- @param code the exit code
-- @param event thrown by job
local on_exit = function(job_id, code, event)
  if code == 0 then
    on_success()
    return
  end

  on_fail(code)
end

--- execute command
-- @param cmd the command to execute in the devcontainer terminal
local function exec_command(cmd)
  vim.fn.termopen(
    cmd, 
    { 
      on_exit = on_exit,
      on_stdout = function(_, data, _)
        vim .api.nvim_win_call(
          win,
          function()
            vim.cmd("normal! G")
          end
        ) 
      end,
    }
  )
  vim.api.nvim_set_current_buf(buffer)
end

-- create a new window and execute the given command
-- @param cmd the command to execute in the devcontainer terminal
function spawn_and_execute(cmd)
  prev_win = vim.api.nvim_get_current_win()
  win, buffer = windows_utils.open_floating_window()
  exec_command(cmd)
end

-- build the initial part of a devcontainer command
-- @param action the action for the devcontainer to perform 
-- (see man devcontainer) 
-- @param cwd the current working directory. Used as a starting place to find 
-- .devcontainer directory
-- @return nil if no devcontainer_parent could be found otherwise 
-- the basic devcontainer command for the given type
local function devcontainer_command(action, cwd)
  devcontainer_root = folder_utils.get_root(cwd)
  if devcontainer_root == nil then
    vim.notify("Unable to find devcontainer directory...", vim.log.levels.ERROR)
    return nil
  end

  local command = "devcontainer " .. action
  command = command .. " --workspace-folder '" .. devcontainer_root .. "'"

  return command
end

-- helper function to generate devcontainer bringup command
-- @param cwd the current working directory. Used as a starting place to find 
-- .devcontainer directory
-- @return nil if no devcontainer_parent could be found otherwise the 
-- devcontainer bringup command
local function get_devcontainer_up_cmd(cwd)
  local command = devcontainer_command("up", cwd)
  if command == nil then
    return command
  end
  
  if config.remove_existing_container then
    command = command .. " --remove-existing-container"
  end
	command = command .. " --update-remote-user-uid-default off"

  if config.dotfiles_repository == "" or config.dotfiles_repository == nil then
    return command
  end

  command = command .. " --dotfiles-repository '" .. config.dotfiles_repository 
  -- only include the branch if it exists
  if config.dotfiles_branch ~= "" and config.dotfiles_branch ~= nil then
    command = command .. " -b " .. config.dotfiles_branch
  end
  command = command .. "'"

  if config.dotfiles_targetPath ~= "" and config.dotfiles_targetPath ~= nil then
    command = command .. " --dotfiles-target-path '" .. config.dotfiles_targetPath .. "'"
  end

  if config.dotfiles_install_command ~= "" and config.dotfiles_install_command ~= nil then
    command = command .. " --dotfiles-install-command '" .. config.dotfiles_install_command .. "'"
  end

  return command
end

-- issues command to bringup devcontainer
-- @param cwd the current working directory. Used as a starting place to find 
-- .devcontainer directory
function M.bringup(cwd)
  local command = get_devcontainer_up_cmd(cwd)

  if command == nil then
    return 
  end

  if config.interactive then
    vim.ui.input(
      {prompt=windows_utils.wrap_text(
            "Spawning devcontainer with command: " .. command
        ) .. "\n\n" .. "Press q to cancel or any other key to continue\n"
      },
      function(input)
        if (input == "q" or input == "Q") then
          vim.notify(
            "\nUser cancelled bringing up devcontainer"
          )
        else
          spawn_and_execute(command)
        end
      end
    )
    return
  end

  spawn_and_execute(command)
end

-- execute the given cmd within the given devcontainer_parent
-- @param cmd the command to issue in the devcontainer terminal
-- @param cwd the current working directory. Used as a starting place to find 
-- .devcontainer directory
function M.exec_cmd(cmd, cwd)
  command = devcontainer_command("exec", cwd)
  if command == nil then
    return
  end

  command = command .. " " .. cmd
  spawn_and_execute(command)
end

-- execute a given cmd within the given devcontainer_parent
-- @param cwd the current working directory. Used as a starting place to find 
-- .devcontainer directory
-- @param devcontainer_parent the location guess for .devcontainer directory
function M.exec(cwd)
  vim.ui.input(
    {prompt="Enter command:"},
    function(input)
      if input ~= nil then
        M.exec_cmd(input, devcontainer_parent)
      end
    end
  )
end

return M
