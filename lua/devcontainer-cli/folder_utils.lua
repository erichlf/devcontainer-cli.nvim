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

-- return true if directory exists
local function _directory_exists(target_folder)
  return (vim.fn.isdirectory(target_folder) == 1)
end

-- return true if file exists and is readable
local function _file_exists(target_file)
  return (vim.fn.filereadable(target_file) == 1)
end

-- get the devcontainer path for the given directory
---@param directory (string) the directory containing .devcontainer
---@return (string|nil) directory if a devcontainer exists within it or nil otherwise
local function _get_devcontainer_parent(directory)
  local devcontainer_directory = directory .. '/.devcontainer'

  if _directory_exists(devcontainer_directory) then
    return directory
  end

  if _file_exists(directory .. '/.devcontainer.json') then
    return directory
  end

  return nil
end

-- get the root directory the devcontainer given a directory
---@param directory (string) to begin search in
---@param toplevel (boolean) flag indicating if the directory closes to root should be
-- returned
---@return (string|nil) the devcontainer directory closest to the root directory
-- or the first if toplevel is true, and nil if no directory was found
local function _get_root_directory(directory, toplevel)
  local parent_directory = vim.fn.fnamemodify(directory, ':h')
  local devcontainer_parent = _get_devcontainer_parent(directory)

  -- Base case: If we've reached the root directory
  if parent_directory == directory then
    return devcontainer_parent
  end

  if not toplevel and devcontainer_parent ~= nil then
    return devcontainer_parent
  end

  local upper_devcontainer_directory = _get_root_directory(parent_directory, toplevel)
  -- no devcontainer higher up so return what was found here
  if upper_devcontainer_directory == nil then
    return devcontainer_parent
  end

  -- return the highest level devcontainer
  return upper_devcontainer_directory
end

-- find the .devcontainer directory closes to the root upward from the current
-- directory
---@param toplevel (boolean) flag indicating if the directory closes to root should be
-- returned
---@return (string|nil) the devcontainer directory closest to the root directory
-- or the first if toplevel is true, and nil if no directory was found
function M.get_root(toplevel)
  local current_directory = vim.fn.getcwd()
  return _get_root_directory(current_directory, toplevel)
end

-- collect every devcontainer config reachable from the given workspace folder
-- the layouts recognized are the ones understood by the devcontainer cli:
-- <root>/.devcontainer/devcontainer.json, <root>/.devcontainer.json and
-- <root>/.devcontainer/<name>/devcontainer.json
---@param root (string) the workspace folder to search in
---@return (string[]) the absolute paths of the configs found, possibly empty
function M.get_configs(root)
  local configs = {}

  for _, candidate in ipairs({
    root .. '/.devcontainer/devcontainer.json',
    root .. '/.devcontainer.json',
  }) do
    if _file_exists(candidate) then
      table.insert(configs, candidate)
    end
  end

  local nested = vim.fn.glob(root .. '/.devcontainer/*/devcontainer.json', true, true)
  table.sort(nested)
  vim.list_extend(configs, nested)

  return configs
end

-- strip the comments and trailing commas that devcontainer.json allows but
-- that are not valid json
---@param text (string) the raw contents of a devcontainer.json
---@return (string) the equivalent valid json
local function _strip_jsonc(text)
  local out = {}
  local index = 1
  local length = #text
  local in_string = false

  while index <= length do
    local char = text:sub(index, index)
    local next_char = text:sub(index + 1, index + 1)

    if in_string then
      if char == '\\' then
        table.insert(out, text:sub(index, index + 1))
        index = index + 2
      else
        in_string = (char ~= '"')
        table.insert(out, char)
        index = index + 1
      end
    elseif char == '"' then
      in_string = true
      table.insert(out, char)
      index = index + 1
    elseif char == '/' and next_char == '/' then
      index = text:find('\n', index) or (length + 1)
    elseif char == '/' and next_char == '*' then
      local _, stop = text:find('*/', index + 2, true)
      index = (stop or length) + 1
    else
      table.insert(out, char)
      index = index + 1
    end
  end

  text = table.concat(out)
  out = {}
  index = 1
  length = #text
  in_string = false

  while index <= length do
    local char = text:sub(index, index)

    if in_string then
      table.insert(out, char)
      if char == '\\' then
        index = index + 1
        if index <= length then
          table.insert(out, text:sub(index, index))
        end
      elseif char == '"' then
        in_string = false
      end
    elseif char == '"' then
      in_string = true
      table.insert(out, char)
    elseif char == ',' then
      local next_index = index + 1
      while next_index <= length and text:sub(next_index, next_index):match('%s') do
        next_index = next_index + 1
      end
      local next_char = text:sub(next_index, next_index)
      if next_char ~= '}' and next_char ~= ']' then
        table.insert(out, char)
      end
    else
      table.insert(out, char)
    end

    index = index + 1
  end

  return table.concat(out)
end

-- read the name declared by a devcontainer config
---@param path (string) the absolute path of a devcontainer.json
---@return (string|nil) the declared name, or nil when absent or unparseable
function M.get_config_name(path)
  if not _file_exists(path) then
    return nil
  end

  local ok, decoded = pcall(
    function()
      return vim.json.decode(_strip_jsonc(table.concat(vim.fn.readfile(path), '\n')))
    end
  )

  if not ok or type(decoded) ~= 'table' or type(decoded.name) ~= 'string' or decoded.name == '' then
    return nil
  end

  return decoded.name
end

return M
