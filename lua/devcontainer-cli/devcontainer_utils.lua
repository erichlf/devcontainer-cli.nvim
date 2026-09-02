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

local config       = require("devcontainer-cli.config")
local folder_utils = require("devcontainer-cli.folder_utils")
local terminal     = require("devcontainer-cli.terminal")
local log          = require("devcontainer-cli.log")

local M            = {}

-- wrap the given text at max_width
---@param text (string) the text to wrap
---@return (string) the text wrapped
local function _wrap_text(text)
  local wrapped_lines = {}
  for line in text:gmatch("[^\n]+") do
    local current_line = ""
    for word in line:gmatch("%S+") do
      if #current_line + #word <= terminal.columns then
        current_line = current_line .. word .. " "
      else
        table.insert(wrapped_lines, current_line)
        current_line = word .. " "
      end
    end
    table.insert(wrapped_lines, current_line)
  end
  return table.concat(wrapped_lines, "\n")
end

---@class ParsedArgs
---@field direction string?
---@field cmd string?
---@field size number?

---Take a users command arguments in the format "cmd='git commit' direction='float'" size='42'
---and parse this into a table of arguments
---{cmd = "git commit", direction = "float", size = "42"}
---@param args string
---@return ParsedArgs
function M.parse(args)
  local p = {
    single = "'(.-)'",
    double = '"(.-)"',
  }
  local result = {}
  if args then
    local quotes = args:match(p.single) and p.single or args:match(p.double) and p.double or nil
    if quotes then
      -- 1. extract the quoted command
      local pattern = "(%S+)=" .. quotes
      for key, value in args:gmatch(pattern) do
        quotes = p.single
        value = vim.fn.shellescape(value)
        result[vim.trim(key)] = vim.fn.expandcmd(value:match(quotes))
      end
      -- 2. then remove it from the rest of the argument string
      args = args:gsub(pattern, "")
    end

    for _, part in ipairs(vim.split(args, " ")) do
      if #part > 1 then
        local arg = vim.split(part, "=")
        local key, value = arg[1], arg[2]
        if key == "size" then
          value = tonumber(value)
        end
        result[key] = value
      end
    end
  end
  return result
end

---@class Workspace
---@field root string the workspace folder handed to the devcontainer cli
---@field config string the absolute path of the devcontainer.json to use

-- the devcontainer config that was last selected, keyed by workspace folder
local _selected_configs = {}

-- determine which devcontainer config should be used, asking the user to pick
-- one whenever the workspace contains more than a single config
---@param callback (function) called with the resolved Workspace, and not called
-- at all when nothing could be resolved
---@param force_select (boolean|nil) prompt even if a config was already selected
local function _resolve_workspace(callback, force_select)
  local root = folder_utils.get_root(config.toplevel)
  if root == nil then
    log.error("unable to find devcontainer directory...")
    return
  end

  local fixed_devcontainer_json_path = config.fixed_devcontainer_json_path
  if fixed_devcontainer_json_path ~= nil and fixed_devcontainer_json_path ~= "" then
    local path = vim.startswith(fixed_devcontainer_json_path, "/") and fixed_devcontainer_json_path or
        (root .. "/" .. fixed_devcontainer_json_path)
    if vim.fn.filereadable(path) ~= 1 then
      log.error("configured devcontainer config '" .. path .. "' does not exist...")
      return
    end

    callback({ root = root, config = path })
    return
  end

  local configs = folder_utils.get_configs(root)
  if #configs == 0 then
    log.error("unable to find a devcontainer.json in '" .. root .. "'...")
    return
  end

  if not force_select then
    local selected = _selected_configs[root]
    if config.reuse_fixed_path and selected ~= nil and vim.tbl_contains(configs, selected) then
      callback({ root = root, config = selected })
      return
    end

    if #configs == 1 then
      _selected_configs[root] = configs[1]
      callback({ root = root, config = configs[1] })
      return
    end
  end

  vim.ui.select(
    configs,
    {
      prompt = "Select a devcontainer config:",
      format_item = function(item)
        local relative = item:sub(#root + 2)
        local name = folder_utils.get_config_name(item)
        if name == nil then
          return relative
        end

        return name .. " (" .. relative .. ")"
      end,
    },
    function(choice)
      if choice == nil then
        log.info("no devcontainer config selected, ignoring.")
        return
      end

      _selected_configs[root] = choice
      callback({ root = root, config = choice })
    end
  )
end

-- build the initial part of a devcontainer command
---@param action (string) the action for the devcontainer to perform
-- (see man devcontainer)
---@param workspace (Workspace) the workspace folder and config to act on
---@return (string) the basic devcontainer command for the given action
local function _devcontainer_command(action, workspace)
  local command = "devcontainer " .. action
  command = command .. " --workspace-folder " .. vim.fn.shellescape(workspace.root)
  command = command .. " --config " .. vim.fn.shellescape(workspace.config)
  command = command .. " --id-label " .. vim.fn.shellescape("devcontainer.config_file=" .. workspace.config)

  return command
end

-- prompt the user for the devcontainer config to use from now on
function M.select_config()
  _resolve_workspace(
    function(workspace)
      log.info("using devcontainer config: " .. workspace.config)
    end,
    true
  )
end

-- helper function to generate devcontainer bringup command
---@param workspace (Workspace) the workspace folder and config to bring up
---@return (string) the devcontainer bringup command
local function _get_devcontainer_up_cmd(workspace)
  local command = _devcontainer_command("up", workspace)

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
function M.bringup()
  _resolve_workspace(
    function(workspace)
      local command = _get_devcontainer_up_cmd(workspace)

      if config.interactive then
        vim.ui.input(
          {
            prompt = _wrap_text(
              "Spawning devcontainer with command: " .. command
            ) .. "\n\n" .. "Press q to cancel or any other key to continue\n"
          },
          function(input)
            if (input == "q" or input == "Q") then
              log.info("\nUser cancelled bringing up devcontainer")
            else
              terminal.spawn(command)
            end
          end
        )
        return
      end

      terminal.spawn(command)
    end
  )
end

-- execute the given cmd within the given devcontainer_parent
---@param cmd (string) the command to issue in the devcontainer terminal
---@param direction (string|nil) the placement of the window to be created
-- (left, right, bottom, float)
function M._exec_cmd(cmd, direction, size)
  _resolve_workspace(
    function(workspace)
      local command = _devcontainer_command("exec", workspace)
      command = command .. " " .. config.shell .. " -c '" .. cmd .. "'"
      log.info(command)
      terminal.spawn(command, direction, size)
    end
  )
end

-- execute a given cmd within the given devcontainer_parent
---@param cmd (string|nil) the command to issue in the devcontainer terminal
---@param direction (string|nil) the placement of the window to be created
-- (left, right, bottom, float)
---@param size (number|nil) size of the window to create
function M.exec(cmd, direction, size)
  if terminal.is_open() then
    log.warn("there is already a devcontainer process running.")
    return
  end

  if cmd == nil or cmd == "" then
    vim.ui.input(
      { prompt = "Enter command:" },
      function(input)
        if input ~= nil then
          M._exec_cmd(input, direction, size)
        else
          log.warn("no command received, ignoring.")
        end
      end
    )
  else
    M._exec_cmd(cmd, direction, size)
  end
end

-- create the necessary functions needed to connect to nvim in a devcontainer
---@param on_created (function) called once the autocommand has been created
function M.create_connect_cmd(on_created)
  _resolve_workspace(
    function(workspace)
      local au_id = vim.api.nvim_create_augroup("devcontainer-cli.connect", {})
      local dev_command = _devcontainer_command("exec", workspace) .. " " .. config.nvim_binary

      vim.api.nvim_create_autocmd(
        "UILeave",
        {
          group = au_id,
          callback = function()
            local connect_command = {}
            if vim.env.TMUX ~= nil then
              connect_command = { "tmux split-window -h -t \"$TMUX_PANE\"" }
              dev_command = vim.fn.shellescape(dev_command)
            elseif vim.fn.executable("wezterm") == 1 then
              connect_command = { "wezterm cli split-pane --right --cwd . -- bash -c" }
              dev_command = "\"" .. dev_command .. "\""
            elseif vim.fn.executable("alacritty") == 1 then
              connect_command = { "alacritty --working-directory . --title \"Devcontainer\" -e" }
            elseif vim.fn.executable("gnome-terminal") == 1 then
              connect_command = { "gnome-terminal --" }
            elseif vim.fn.executable("iTerm.app") == 1 then
              connect_command = { "iTerm.app" }
            elseif vim.fn.executable("Terminal.app") == 1 then
              connect_command = { "Terminal.app" }
            else
              log.error("no supported terminal emulator found.")
              return
            end

            table.insert(connect_command, dev_command)
            local command = table.concat(connect_command, " ")
            vim.schedule(
              function()
                vim.fn.jobstart(command, { detach = true })
              end
            )
          end
        }
      )

      on_created()
    end
  )
end

-- issues command to down devcontainer
function M.down()
  _resolve_workspace(
    function(workspace)
      local tag = vim.fn.shellescape("label=devcontainer.config_file=" .. workspace.config)
      local command = "docker ps -q -a --filter " .. tag
      log.debug("Attempting to get pid of devcontainer using command: " .. command)
      local result = vim.fn.systemlist(command)

      if #result == 0 then
        log.warn("Couldn't find devcontainer to kill")
        return
      end

      local pid = result[1]
      command = "docker kill " .. pid
      log.info("Killing docker container with pid: " .. pid)
      terminal.spawn(command)
    end
  )
end

return M
