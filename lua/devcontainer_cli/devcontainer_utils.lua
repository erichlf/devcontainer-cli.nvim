local config = require("devcontainer_cli.config")
local windows_utils = require("devcontainer_cli.windows_utils")
local folder_utils = require("devcontainer_cli.folder_utils")

local M = {}

local prev_win = -1
local win = -1
local buffer = -1

-- window the created window detaches set things back to -1
local on_detach = function()
  prev_win = -1
  win = -1
  buffer = -1
end

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

--- on_exit callback function to delete the open buffer when devcontainer exits in a neovim terminal
local on_exit = function(job_id, code, event)
  if code == 0 then
    on_success()
    return
  end

  on_fail(code)
end

--- execute command
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

-- helper function for determine devcontainer specifics
local function get_devcontainer_data(devcontainer_root)
  local read_devcontainer 
    = "devcontainer read-configuration --include-merged-configuration --workspace-folder " .. devcontainer_root 
  remote_user_cmd = read_devcontainer .. " | jq '.configuration.remoteUser' | tr -d '" .. '"' .. "'"
  workspace_cmd = read_devcontainer .. " | jq '.workspace.workspaceFolder' | tr -d '" .. '"' .. "'"
  
  devcontainer_data = {
    remote_user = nil,
    workspace = nil,
  }

  stderr = ""
  
  job1_id = vim.fn.jobstart(
    remote_user_cmd,
    {
      stdout_buffered = true,
      on_stdout = function(_, data)
        devcontainer_data.remote_user = data[1]
        if devcontainer_data.remote_user == " " or devcontainer_data.remote_user == nil then
          vim.notify(
            "remote_user: " .. remote_user_cmd .. " " .. " " .. vim.inspect(data),
            vim.log.levels.ERROR
          )
          devcontainer_data.remote_user = nil
        end
        vim.notify(
          "remote user: " .. remote_user_cmd .. " " .. " " .. devcontainer_data.remote_user .. " " .. vim.inspect(data),
          vim.log.levels.WARN
        )
      end
    }
  )

  job2_id = vim.fn.jobstart(
    workspace_cmd,
    {
      stdout_buffered = true,
      on_stdout = function(_, data)
        devcontainer_data.workspace = data[1]
        if devcontainer_data.workspace == " " or devcontainer_data.workspace == nil then
          vim.notify(
            "workspace: " .. workspace_cmd .. " " .. " " .. vim.inspect(data),
            vim.log.levels.ERROR
          )
          devcontainer_data.workspace = nil
        end
        vim.notify(
          "workspace: " .. remote_user_cmd .. " " .. " " .. devcontainer_data.workspace .. " " .. vim.inspect(data),
          vim.log.levels.WARN
        )
      end
    }
  )
  vim.fn.jobwait({job1_id, job2_id})

  return devcontainer_data
end

-- helper function to generate devcontainer bringup command
local function get_devcontainer_up_cmd(devcontainer_parent)
  local devcontainer_data = get_devcontainer_data(devcontainer_parent)

  if devcontainer_data.remote_user == nil or devcontainer_data.workspace == nil then
    vim.notify(
      "Failed to obtain remote user or remote workspace from devcontainer.",
        vim.log.levels.ERROR
    )

    return nil
  end
  
  local command = "devcontainer up "
  if config.remove_existing_container then
    command = command .. "--remove-existing-container"
  end

  command = command .. " --workspace-folder '" .. devcontainer_parent .. "'"
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
function M.bringup(devcontainer_parent)
  local command = get_devcontainer_up_cmd(devcontainer_parent)

  if command == nil then
    prev_win = vim.api.nvim_get_current_win()

    return 
  end

  if config.interactive then
    vim.ui.input(
      windows_utils.wrap_text(
          "Devcontainer folder detected. Path: " .. devcontainer_parent .. "\n" ..
          "Spawning devcontainer with command: " .. command,
          80
      ) .. "\n\n" .. "Press q to cancel or any other key to continue\n",
      function(input)
        if (input == "q" or input == "Q") then
          vim.notify(
            "\nUser cancelled bringing up devcontainer"
          )
        else
          win, buffer = windows_utils.open_floating_window()
          exec_command(command)
        end
      end
    )
  else
    win, buffer = windows_utils.open_floating_window(on_detach)
    exec_command(command)
  end
end

function M.exec_cmd(cmd, devcontainer_parent)
  win, buffer = windows_utils.open_floating_window()
  command = "devcontainer exec --workspace-folder " .. devcontainer_parent
  command = command .. " " .. cmd
  exec_command(command)
end

function M.exec(devcontainer_parent)
  vim.ui.input(
    "Enter command:",
    function(input)
      if input ~= nil then
        M.exec_cmd(input, devcontainer_parent)
      end
    end
  )
end

return M
