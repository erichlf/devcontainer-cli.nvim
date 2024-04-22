# Devcontainer CLI (Nvim Plugin)

Develop your next Repo in a Devcontainer using Nvim thanks to the 
[Devconatiner CLI](https://github.com/devcontainers/cli) and this plugin
![](doc/gifs/nvim_devcontainer_cli-description.gif)

As you can see in the GIF above,
[alacritty](https://github.com/alacritty/alacritty) is being used as a Terminal
Emulator. Any of the ones recommended [here](https://www.lazyvim.org/) would
work. For dotfiles setup I would recommend looking at the `devcontainer` branch
of [my dotfiles](https://github.com/erichlf/dotfiles). The `install.sh` script is
quite simple, but should be very informative.

---

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
   container together with a set of dependencies. To install any dependencies you need either the
   dotfiles setup script will need to do that or you can use devcontainer features to install them.
   A very nice devcontainer feature that can do this is 
   [apt package](https://github.com/rocker-org/devcontainer-features/tree/main/src/apt-packages).
3. The last step is connecting inside the container via `devcontainer exec`
   ([here](https://github.com/erichlf/nvim-devcontainer-cli/blob/main/bin/connect_to_devcontainer.sh)).

The main thing this plugin does is bringup your devcontainer and execute
commands via a convenient interface. It attempts to stay out of your way and
allows you to do things as you wish, but gives you the tools to do that easily.

**Inspiration:**

This plugin has been inspired by the work previously done by
[arnaupv](https://github.com/arnaupv/nvim-devcontainer-cli),
[esensar](https://github.com/esensar/nvim-dev-container) and by
[jamestthompson3](https://github.com/jamestthompson3/nvim-remote-containers).
The main difference between this version and arnaupv is that it tries to not
make assumptions about how you work.

# Dependencies

- [docker](https://docs.docker.com/get-docker/)
- [devcontainer-cli](https://github.com/devcontainers/cli#npm-install)

# 🔧 Installation

- [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "erichlf/nvim-devcontainer-cli",
  opts = {
    -- whather to verify that the final devcontainer should be run
    interactive = false,
    -- search for the devcontainer directory closest to the root in the directory tree
    toplevel = true,
    -- Remove existing container each time DevcontainerUp is executed
    -- If set to True [default_value] it can take extra time as you force to start from scratch
    remove_existing_container = true,
    -- By default, if no extra config is added, following nvim_dotfiles are
    -- installed: "https://github.com/LazyVim/starter"
    -- This is an example for configuring other dotfiles inside the docker container
    dotfiles_repository = "https://github.com/erichlf/dotfiles.git",
    dotfiles_branch = "main", -- branch to clone from dotfiles_repository`
    dotfiles_targetPath = "~/dotfiles", -- location to install dotfiles
    dotfiles_intallCommand = "install.sh", -- script to run after dotfiles are cloned
  },
  keys = {
    -- stylua: ignore
    {
      "<leader>Du",
      ":DevcontainerUp<cr>",
      desc = "Bring up the DevContainer",
    },
    {
      "<leader>Dc",
      ":DevcontainerConnect<cr>",
      desc = "Connect to DevContainer",
    },
    {
      "<leader>De",
      ":DevcontainerExec<cr>",
      desc = "Execute a command in DevContainer",
    },
    {
      "<leader>Db",
      ":DevcontainerExec cd build && make<cr>",
      desc = "Execute build command in DevContainer",
    },
    {
      "<leader>Dt",
      ":DevcontainerExec cd build && make test<cr>",
      desc = "Execute test command in DevContainer",
    },
  }
},
```

The default_config can be found [here](./lua/devcontainer_cli/config/init.lua).

# How to use?

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

# Tests

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

# FEATUREs (in order of priority)

1. [x] Capability to create and run a devcontainer using the [Devconatiner CLI](https://github.com/devcontainers/cli).
2. [x] Capability to attach in a running devcontainer.
3. [x] The floating window created during the devcontainer Up process (:DevcontainerUp<cr>) is closed when the process finishes successfully.
4. [x] [Give the possibility of defining custom dotfiles when setting up the devcontainer](https://github.com/erichlf/nvim-devcontainer-cli/issues/1)
5. [ ] Add unit tests using plenary.busted lua module.
6. [ ] The logs printed in the floating window when preparing the Devcontainer are saved and easy to access.
7. [ ] Convert bash scripts in lua code.
