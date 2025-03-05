# Devcontainer CLI (NVIM Plugin)

![GitHub Workflow Status](http://img.shields.io/github/actions/workflow/status/erichlf/devcontainer-cli.nvim/default.yml?branch=main&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

Develop your next Repo in a Devcontainer using *nvim* thanks to the
[Devconatiner CLI](https://github.com/devcontainers/cli) and this plugin
![devcontainer-cli in action](doc/gifs/devcontainer-cli-description.gif)

As you can see in the GIF above, guake with tmux is being used. Any of the ones
recommended [here](https://www.lazyvim.org/) would work. For dotfiles setup I created
a version of my dotfiles that doesn't have any private submodules. These dotfiles
are probably more than what anyone would want, but if feel free to use them. The
one gotcha with them is that it requires the environment variable DEV_WORKSPACE
to be set. I would recommend looking at the `devcontainer-cli` branch of
[my dotfiles](https://github.com/erichlf/dotfiles). The `install.sh` script ends
up calling `script/devcontainer-cli` which is quite simple, but should get you
some pretty good ideas of how things can be setup.

---

## Intro

First, what problem is this plugin trying to solve?

**Situation:**

Your favorite editor is **nvim** and you are currently developing a
containerized application (using Docker).

**Problem:**

Your team is using a devcontainer (or a docker container) and you want to still
use **nvim** with [LSP](https://microsoft.github.io/language-server-protocol/)
and [DAP](https://microsoft.github.io/debug-adapter-protocol/) (among other
plugins), but you don't want to have to run all the cumbersome commands.

**Solution:**

There are multiple IDEs out there who give you the possibility to execute
themself inside the Docker container you are developing, fixing the problems
above, but there is nothing which works out-of-the-box for **nvim**. Recently,
Microsoft opened the command line tool,
([Devconatiner CLI](https://github.com/devcontainers/cli)), which allows developers
to run devcontainers without VScode.

The current **nvim** plugin aims to take advantage of `devcontainer-cli` for
creating your own local development environment on top of a containerized
applications. This plugin allows you use LSP capabilities for external modules
(installed inside the Docker container), and also debug your application
([DAP](https://microsoft.github.io/debug-adapter-protocol/)).

But, what is happening under the hood?

1. First, `devcontainer-cli` is used for setting up your devcontainer, building
   the image based on the instructions defined in your
   [devcontainer.json](.devcontainer/devcontainer.json) and initializing a
   container based on such image.
2. Once the container is running, your dotfiles are installed in the docker
   container together with a set of dependencies. To install any dependencies
   you need either the dotfiles setup script will need to do that or you can
   use devcontainer features to install them. A very nice devcontainer feature
   that can do this is
   [apt package](https://github.com/rocker-org/devcontainer-features/tree/main/src/apt-packages).
3. The last step is connecting inside the container via `devcontainer exec`
   ([here](https://github.com/erichlf/devcontainer-cli.nvim/blob/main/bin/connect_to_devcontainer.sh)).

The main thing this plugin does is bringup your devcontainer and execute
commands via a convenient interface. It attempts to stay out of your way and
allows you to do things as you wish, but gives you the tools to do that easily.

**Inspiration:**

This plugin has been inspired by the work previously done by
[arnaupv](https://github.com/arnaupv/devcontainer-cli.nvim),
[esensar](https://github.com/esensar/nvim-dev-container) and by
[jamestthompson3](https://github.com/jamestthompson3/nvim-remote-containers).
The main difference between this version and arnaupv is that it tries to not
make assumptions about how you work.

## Dependencies

- NeoVim 0.9.0+
- [docker](https://docs.docker.com/get-docker/)
- [devcontainer-cli](https://github.com/devcontainers/cli#npm-install)
- [toggleterm](https://github.com/akinsho/toggleterm.nvim)

## 🔧 Installation

- [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "erichlf/devcontainer-cli.nvim",
  dependencies = { 'akinsho/toggleterm.nvim' },
  keys = {
    -- stylua: ignore
    {
      "<leader>Du",
      ":DevcontainerUp<CR>",
      desc = "Bring up the DevContainer",
    },
    {
      "<leader>Dc",
      ":DevcontainerConnect<CR>",
      desc = "Connect to DevContainer",
    },
    {
      "<leader>Dd",
      ":DevcontainerDown<CR>",
      desc = "Kill the current DevContainer",
    },
    {
      "<leader>De",
      ":DevcontainerExec direction='vertical' size='40'<CR>",
      desc = "Execute a command in DevContainer",
    },
    {
      "<leader>Db",
      ":DevcontainerExec cd build && make<CR>",
      desc = "Execute build command in DevContainer",
    },
    {
      "<leader>Dt",
      ":DevcontainerExec cmd='cd build && make test' direction='horizontal'<CR>",
      desc = "Execute test command in DevContainer",
    },
    {
      "<leader>DT",
      "<CMD>DevContainerToggle<CR>",
      desc = "Toggle the current DevContainer Terminal"
    },
  },
  init = function()
    local opts = {
      -- whather to verify that the final devcontainer should be run
      interactive = false,
      -- search for the devcontainer directory closest to the root in the
      -- directory tree
      toplevel = true,
      -- Remove existing container each time DevcontainerUp is executed
      -- If set to True [default_value] it can take extra time as you force to
      -- start from scratch
      remove_existing_container = true,
      -- By default, if no extra config is added, following nvim_dotfiles are
      -- installed: "https://github.com/erichlf/dotfiles"
      -- This is an example for configuring other dotfiles inside the docker container
      dotfiles_repository = "https://github.com/erichlf/dotfiles.git",
      dotfiles_branch = "devcontainer-cli", -- branch to clone from dotfiles_repository`
      dotfiles_targetPath = "~/dotfiles", -- location to install dotfiles
      -- script to run after dotfiles are cloned
      dotfiles_intallCommand = "install.sh",
      shell = "bash", -- shell to use when executing commands
      -- The particular binary to use for connecting to in the devcontainer
      -- Most likely this should remain nvim
      nvim_binary = "nvim",
      -- Set the logging level for console (notifications) and file logging.
      -- The available levels are trace, debug, info, warn, error, or fatal.
      -- Set the log level for file logging
      log_level = "debug",
      -- Set the log level for console logging
      console_level = "info",
    }
    require('devcontainer-cli').setup(opts)
  end,
}
```

The default_config can be found [here](./lua/devcontainer_cli/config/init.lua).

## How to use?

There are 3 main commands: `:DevcontainerUp`, `:DevcontainerExec`, and `:DevcontainerConnect`.

1. First, you should be in the main direcotry or subdirectory of your project
   container you `.devcontainer` directory. This file is used by the
   [Devcontainer CLI](https://github.com/devcontainers/cli). As a first
   approach you can copy-paste the
   [.devcontainer](.devcontainer/devcontainer.json) folder of the current
   project and adapt it for your repo. You can also find more information about
   the `devcontainer.json` file
   [here](https://code.visualstudio.com/docs/remote/devcontainerjson-reference).
2. Then open a **nvim** session and execute the first command:
   `DevcontainerUp`, which will create the image based on your
   `.devcontainer\devcontainer.json`. Once created it will initialize a
   container with the previously created image, and then clone your dotfiles,
   and finally run the specified setup script. The new devcontainer running can
   be easily checked with the following command: `docker ps -a`.
3. If the process above finishes successfully, you can choose to close the
   current **nvim** session and open a new session within the devcontainer via
   the command: `:DevcontainerConnect`. Alternatively, you could choose to
   continue working in your current session and run commands in the
   devcontainer via `DevcontainerExec`.

During execution using `DevcontainerUp` or `DevcontainerExec` it is possible
to toggle the terminal via `t` while in normal mode and then to bring it back
you can run `:DevContainerToggle`. Additionally you could bring it back through
`:TermSelect`.

During the execution of a Devcontainer process you can also type `q` or `<esc>`
to kill the process and exit the terminal window.

## Tests

Tests are executed automatically on each PR using Github Actions.

In case you want to run Github Actions locally, it is recommended to use
[act](https://github.com/nektos/act#installation). And then execute:

```bash
act -W .github/workflows/default.yml
```

Another option would be to connect to the devcontainer following the **How to
use?** section. Once connected to the devcontainer, execute:

```bash
make test
```

## FEATUREs (in order of priority)

1. [x] Capability to create and run a devcontainer using the [Devconatiner CLI](https://github.com/devcontainers/cli).
2. [x] Capability to attach in a running devcontainer.
3. [x] The floating window created during the devcontainer Up process
       (`:DevcontainerUp<cr>`) is closed when the process finishes successfully.
4. [x] [Give the possibility of defining custom dotfiles when setting up the devcontainer](https://github.com/erichlf/devcontainer-cli.nvim/issues/1)
5. [x] Add unit tests using plenary.busted lua module.
6. [x] Create a logger.
7. [x] Convert bash scripts in lua code.
