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
      root_folder = folder_utils.get_root(true)

      -- From the subfolder, we check that the get_root function returns the folder where the git repo is located instead of the CWD
      print("ROOT: " .. root_folder)
      print("PROJECT_ROOT: " .. project_root)
      assert(root_folder == project_root)

      vim.fn.chdir(project_root)
    end
  )
end)
