local config = require("devcontainer-cli.config")

local M = {}

-- number of columns for displaying text
local terminal_columns = config.terminal_columns

-- wrap the given text at max_width
---@param text (string) the text to wrap
---@return (string) the text wrapped
function M.wrap_text(text)
  local wrapped_lines = {}
  for line in text:gmatch("[^\n]+") do
    local current_line = ""
    for word in line:gmatch("%S+") do
      if #current_line + #word <= terminal_columns then
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

-- create a floating window
---@param on_detach (function) call back for when the window is detached
---@return integer, integer the window and buffer numbers
function M.open_floating_window(on_detach)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'devcontainer-cli')
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<CMD>close<CR>', {})
  vim.api.nvim_buf_set_keymap(buf, 'n', '<esc>', '<CMD>close<CR>', {})

  local width = math.ceil(
    math.min(vim.o.columns, math.max(terminal_columns, vim.o.columns - 20))
  )
  local height = math.ceil(math.min(vim.o.lines, math.max(20, vim.o.lines - 10)))

  local row = math.ceil(vim.o.lines - height) * 0.5 - 1
  local col = math.ceil(vim.o.columns - width) * 0.5 - 1

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = "devcontainer-cli",
    title_pos = "center",
    -- noautocommand = false,
  })
  -- Attach autocommand for when the buffer is detached (closed)
  vim.api.nvim_buf_attach(buf, false, {
    on_detach = on_detach
  })

  return win, buf
end

-- send text to the given buffer
---@param text (string) the text to send
---@param buffer (integer) the buffer to send text to
function M.send_text(text, buffer)
  local text_tbl = vim.split(M.wrap_text(text), "\n")

  -- Set the content of the buffer
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, text_tbl)
end

return M
