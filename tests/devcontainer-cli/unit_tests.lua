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

local folder_utils = require("devcontainer-cli.folder_utils")

describe("folder_utils.get_root:", function()
  it(
    "check if first devcontainer directory when toplevel is false",
    function()
      -- dbg()
      -- This test assumes that we are in the root folder of the project
      local project_root = vim.fn.getcwd()
      -- We change the current directory to a subfolder
      vim.fn.chdir("lua/devcontainer-cli")
      local devcontainer_cli_folder = vim.fn.getcwd()
      -- First we check that the we properly changed the directory
      assert(devcontainer_cli_folder == project_root .. "/lua/devcontainer-cli")
      -- Verify that the project root is at the current level when toplevel is false
      local root_folder = folder_utils.get_root(false)
      -- From the subfolder, we check that the get_root function returns the folder where the git repo is located instead of the CWD
      print("ROOT: " .. root_folder)
      print("PROJECT_ROOT: " .. project_root)
      assert(root_folder == project_root)
      -- After running the test we come back to the initial location
      vim.fn.chdir(project_root)
    end
  )
end)

describe("folder_utils.get_root:", function()
  it(
    "check if top most devcontainer directory when toplevel is true",
    function()
      -- dbg()
      -- This test assumes that we are in the root folder of the project
      local project_root = vim.fn.getcwd()
      -- We change the current directory to a subfolder
      vim.fn.chdir("lua/devcontainer-cli")
      local devcontainer_cli_folder = vim.fn.getcwd()
      -- First we check that the we properly changed the directory
      assert(devcontainer_cli_folder == project_root .. "/lua/devcontainer-cli")

      -- Verify that the project root is at HOME (location of top most devcontainer directory) when toplevel is true
      project_root = os.getenv("HOME")
      local root_folder = folder_utils.get_root(true)

      -- From the subfolder, we check that the get_root function returns the folder where the git repo is located instead of the CWD
      print("ROOT: " .. root_folder)
      print("PROJECT_ROOT: " .. project_root)
      assert(root_folder == project_root)

      vim.fn.chdir(project_root)
    end
  )
end)

describe("folder_utils.get_configs:", function()
  it(
    "finds the root, nested and top level devcontainer configs",
    function()
      local root = vim.fn.tempname()
      vim.fn.mkdir(root .. "/.devcontainer/b", "p")
      vim.fn.mkdir(root .. "/.devcontainer/a", "p")
      vim.fn.writefile({ "{}" }, root .. "/.devcontainer/devcontainer.json")
      vim.fn.writefile({ "{}" }, root .. "/.devcontainer/a/devcontainer.json")
      vim.fn.writefile({ "{}" }, root .. "/.devcontainer/b/devcontainer.json")
      vim.fn.writefile({ "{}" }, root .. "/.devcontainer.json")

      local configs = folder_utils.get_configs(root)

      assert(#configs == 4)
      assert(configs[1] == root .. "/.devcontainer/devcontainer.json")
      assert(configs[2] == root .. "/.devcontainer.json")
      assert(configs[3] == root .. "/.devcontainer/a/devcontainer.json")
      assert(configs[4] == root .. "/.devcontainer/b/devcontainer.json")

      vim.fn.delete(root, "rf")
    end
  )

  it(
    "returns an empty list when there is no config",
    function()
      local root = vim.fn.tempname()
      vim.fn.mkdir(root, "p")

      assert(#folder_utils.get_configs(root) == 0)

      vim.fn.delete(root, "rf")
    end
  )
end)

describe("folder_utils.get_config_name:", function()
  local function write_config(lines)
    local path = vim.fn.tempname()
    vim.fn.writefile(lines, path)
    return path
  end

  it(
    "reads the name through comments and trailing commas",
    function()
      local path = write_config({
        "// a line comment with a } brace",
        "{",
        "  /* a block",
        "     comment */",
        "  \"name\": \"GPU // dev\",",
        "  \"image\": \"debian\",",
        "}",
      })

      assert(folder_utils.get_config_name(path) == "GPU // dev")

      vim.fn.delete(path)
    end
  )

  it(
    "preserves comma-bracket sequences inside name strings",
    function()
      local path = write_config({
        "{",
        "  \"name\": \"quoted \\\",} and ,]\",",
        "}",
      })

      assert(folder_utils.get_config_name(path) == "quoted \",} and ,]")

      vim.fn.delete(path)
    end
  )

  it(
    "returns nil when the name is missing or the config is invalid",
    function()
      local without_name = write_config({ "{ \"image\": \"debian\" }" })
      local invalid = write_config({ "not json" })

      assert(folder_utils.get_config_name(without_name) == nil)
      assert(folder_utils.get_config_name(invalid) == nil)
      assert(folder_utils.get_config_name(vim.fn.tempname()) == nil)

      vim.fn.delete(without_name)
      vim.fn.delete(invalid)
    end
  )
end)
