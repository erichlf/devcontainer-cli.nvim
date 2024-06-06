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

-- build the initial part of a devcontainer command
---@param action (string) the action for the devcontainer to perform
-- (see man devcontainer)
---@return (string|nil) nil if no devcontainer_parent could be found otherwise
-- the basic devcontainer command for the given type
local function _devcontainer_command(action)
  local devcontainer_root = folder_utils.get_root(config.toplevel)
  if devcontainer_root == nil then
    log.error("unable to find devcontainer directory...")
    return nil
  end

  local command = "devcontainer " .. action
  command = command .. " --workspace-folder '" .. devcontainer_root .. "'"

  return command
end

-- helper function to generate devcontainer bringup command
---@return (string|nil) nil if no devcontainer_parent could be found otherwise the
-- devcontainer bringup command
local function _get_devcontainer_up_cmd()
  local command = _devcontainer_command("up")
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
function M.bringup()
  local command = _get_devcontainer_up_cmd()

  if command == nil then
    return
  end

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

-- execute the given cmd within the given devcontainer_parent
---@param cmd (string) the command to issue in the devcontainer terminal
---@param direction (string|nil) the placement of the window to be created
-- (left, right, bottom, float)
function M._exec_cmd(cmd, direction, size)
  local command = _devcontainer_command("exec")
  if command == nil then
    return
  end

  command = command .. " " .. config.shell .. " -c '" .. cmd .. "'"
  log.info(command)
  terminal.spawn(command, direction, size)
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
function M.create_connect_cmd()
  local au_id = vim.api.nvim_create_augroup("devcontainer-cli.connect", {})
  local dev_command = _devcontainer_command("exec")
  if dev_command == nil then
    return false
  end
  dev_command = dev_command .. " " .. config.nvim_binary

  vim.api.nvim_create_autocmd(
    "UILeave",
    {
      group = au_id,
      callback =
          function()
            local connect_command = {}
            if vim.env.TMUX ~= "" then
              connect_command = { "tmux split-window -h -t \"$TMUX_PANE\"" }
            elseif vim.fn.executable("allacrity") == 1 then
              connect_command = { "alacritty --working-directory . --title \"Devcontainer\" -e" }
            elseif vim.fn.executable("gnome-terminal") == 1 then
              connect_command = { "gnome-terminal --" }
            elseif vim.fn.executable("iTerm.app") == 1 then
              connect_command = { "iTerm.app" }
            elseif vim.fn.executable("Terminal.app") == 1 then
              connect_command = { "Terminal.app" }
            else
              log.error("no supported terminal emulator found.")
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

  return true
end

-- issues command to down devcontainer
function M.down()
  local workspace = folder_utils.get_root(config.toplevel)
  if workspace == nil then
    log.error("Couldn't determine project root")
    return
  end

  local tag = workspace .. "/.devcontainer/devcontainer.json"
  local command = "docker ps -q -a --filter label=devcontainer.config_file=" .. tag
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

return M
