local config       = require("devcontainer-cli.config")
local folder_utils = require("devcontainer-cli.folder_utils")
local log          = require("devcontainer-cli.log")

local Terminal     = require('toggleterm.terminal').Terminal
local mode         = require('toggleterm.terminal').mode

local M            = {}

-- valid window directions
M.directions       = {
  "float",
  "horizontal",
  "tab",
  "vertical",
}

-- window management variables
local _terminal    = nil

-- when the created window detaches set things back to -1
local _on_detach   = function()
  _terminal = nil
end

-- on_fail callback
---@param exit_code (number) the exit code from the failed job
local _on_fail     = function(exit_code)
  log.error("Devcontainer process has failed! exit_code: " .. exit_code)

  vim.cmd("silent! :checktime")
end

local _on_success  = function()
  log.info("Devcontainer process succeeded!")
end

-- on_exit callback function to delete the open buffer when devcontainer exits
-- in a neovim terminal
---@param code (number) the exit code
local _on_exit     = function(code)
  if code == 0 then
    _on_success()
    return
  end

  _on_fail(code)
end

local _on_open     = function(term)
  -- ensure that we are not in insert mode
  vim.cmd("stopinsert")
  vim.api.nvim_buf_set_keymap(
    term.bufnr,
    'n',
    '<esc>',
    '<CMD>lua vim.api.nvim_buf_delete(' .. term.bufnr .. ', { force = true } )<CR><CMD>close<CR>',
    { noremap = true, silent = true }
  )
  vim.api.nvim_buf_set_keymap(
    term.bufnr,
    'n',
    'q',
    '<CMD>lua vim.api.nvim_buf_delete(' .. term.bufnr .. ', { force = true } )<CR><CMD>close<CR>',
    { noremap = true, silent = true }
  )
  vim.api.nvim_buf_set_keymap(term.bufnr, 'n', 't', '<CMD>close<CR>', { noremap = true, silent = true })
end

-- check if the value is in the given table
local function tableContains(tbl, value)
  for _, item in ipairs(tbl) do
    if item == value then
      return true
    end
  end

  return false
end

-- number of columns for displaying text
M.columns = config.terminal_columns

-- create a new window and execute the given command
---@param cmd (string) the command to execute in the devcontainer terminal
---@param direction (string|nil) the placement of the window to be created (float, horizontal, vertical)
---@param size (number|nil) the size of the window to be created
function M.spawn(cmd, direction, size)
  direction = vim.F.if_nil(direction, "float")
  if tableContains(M.directions, direction) == false then
    log.error("Invalid direction: " .. direction)
    return
  end

  -- create the terminal
  _terminal = Terminal:new {
    cmd = cmd,
    hidden = false,
    display_name = "devcontainer-cli",
    direction = vim.F.if_nil(direction, "float"),
    dir = folder_utils.get_root(config.toplevel),
    size = size,
    close_on_exit = false,
    on_open = _on_open,
    auto_scroll = true,
    on_exit = function(_, _, code, _)
      _on_exit(code)
      _on_detach()
    end, -- callback for when process closes
  }
  -- start in insert mode
  _terminal:set_mode(mode.NORMAL)
  -- now execute the command
  _terminal:open()
end

-- check if there is already a terminal window open
---@return true if a terminal window is already open
function M.is_open()
  return _terminal ~= nil
end

-- toggle the current terminal
function M.toggle()
  if _terminal == nil then
    vim.notify("No devcontainer window to toggle.", vim.log.levels.WARN)
    return
  end

  _terminal:toggle()
end

return M
