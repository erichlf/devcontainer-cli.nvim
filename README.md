# Devcontainer CLI for Neovim

Run your project **inside a Dev Container** (via the [`devcontainer` CLI]) without leaving Neovim. This plugin brings convenient commands to **build**, **start**, **connect to**, and **exec** into your dev container, while keeping your usual Neovim setup.

> ✨ Goals: Stay out of your way, make no hard assumptions about your workflow, and give you sharp primitives to stitch into your own dotfiles, keymaps, and tasks.

![devcontainer-cli in action](doc/gifs/devcontainer-cli-description.gif)

---

## Table of Contents

- [Why](#why)
- [Requirements](#requirements)
- [Install](#install)
- [Quick start](#quick-start)
- [Commands](#commands)
- [Configuration](#configuration)
- [Keymap examples](#keymap-examples)
- [Dev Container template](#dev-container-template)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Credits](#credits)
- [License](#license)

---

## Why

**Situation.** You work on a containerized app and prefer Neovim.

**Problem.** Your team uses Dev Containers and you want LSP/DAP and your usual tools, but running the right `docker` / `devcontainer` incantations and wiring dotfiles each time is… a lot.

**Solution.** Use this plugin to delegate the heavy lifting to the **Dev Container CLI** and expose ergonomic Neovim commands to:

- spin up / tear down your container,
- connect a terminal to it, and
- run ad‑hoc commands (build, test, etc.).

---

## Requirements

- **Neovim** ≥ 0.9
- **Docker** (or compatible runtime) installed and running
- **Dev Container CLI** (`devcontainer`) available in `$PATH`
- **toggleterm.nvim** (for the integrated terminal UI)

> Tip: If you don’t want to use `toggleterm.nvim`, you can still call the commands; the terminal UI just won’t be as nice.

---

## Install

Using **lazy.nvim**:

```lua
{
  "erichlf/devcontainer-cli.nvim",
  dependencies = { "akinsho/toggleterm.nvim" },
  init = function()
    require("devcontainer-cli").setup({
      -- only the most useful options shown; see full config below
      interactive = false,
      toplevel = true,
      remove_existing_container = true,
      dotfiles_repository = "https://github.com/erichlf/dotfiles.git",
      dotfiles_branch = "devcontainer-cli",
      dotfiles_targetPath = "~/dotfiles",
      dotfiles_installCommand = "install.sh",
      shell = "bash",
      nvim_binary = "nvim",
      log_level = "debug",
      console_level = "info",
    })
  end,
}
```

> Also make sure the **Dev Container CLI** is installed (for example via `npm i -g @devcontainers/cli`).

---

## Quick start

1. **Ensure you have a Dev Container config** in your project: `.devcontainer/devcontainer.json` (or a top‑level `devcontainer.json`). A good way to start is to copy the example in [Dev Container template](#dev-container-template) and adapt it.
2. **Open Neovim** anywhere inside that project.
3. Run `:DevcontainerUp` to build + start the container, clone and apply your dotfiles, and run your setup script inside the container.
4. Then either:
   - `:DevcontainerConnect` to open a terminal **inside** the container and keep coding, or
   - `:DevcontainerExec <args…>` to run one‑off commands in the container from your current session (build, test, etc.).

**Pro tip:** While a Dev Container task is running, press `t` in normal mode to toggle the terminal window. Use `:DevContainerToggle` to bring it back later.

---

## Commands

- `:DevcontainerUp`
  - Build image (from your `devcontainer.json`) and start the container. Also performs optional dotfiles setup.
- `:DevcontainerConnect`
  - Open an interactive terminal attached to the container (handy for running `nvim` inside the container if you prefer that workflow).
- `:DevcontainerExec [cmd=<string>] [direction=<horizontal|vertical|float>] [size=<number>]`
  - Execute a command in the running container. If `cmd` is omitted, you’ll be prompted. Common patterns: build, test, codegen.
- `:DevcontainerDown`
  - Stop and remove the container (see `remove_existing_container` if you want to always start clean).
- `:DevContainerToggle`
  - Toggle the last devcontainer terminal window.

---

## Configuration

Call `require("devcontainer-cli").setup({ ... })` with any of the following options (defaults shown):

```lua
{
  -- Ask before running actions that change state (good for newcomers)
  interactive = false,

  -- Search upwards and use the nearest `.devcontainer/` folder
  toplevel = true,

  -- Start from scratch each `DevcontainerUp` (slower but clean)
  remove_existing_container = true,

  -- Dotfiles bootstrap executed *inside* the container
  dotfiles_repository = "https://github.com/erichlf/dotfiles.git",
  dotfiles_branch = "devcontainer-cli",
  dotfiles_targetPath = "~/dotfiles",
  dotfiles_installCommand = "install.sh",

  -- Shell used when executing commands
  shell = "bash",

  -- Binary invoked when connecting inside the container
  nvim_binary = "nvim",

  -- Logging
  log_level = "debug",   -- file logs
  console_level = "info", -- on‑screen notifications
}
```

> Looking for defaults in code? See `:h devcontainer-cli.nvim` (or the README source) for the authoritative list of options.

---

## Keymap examples

A few practical bindings you can drop into your config (shown with **lazy.nvim** `keys` style but plain `vim.keymap.set` works too):

```lua
{
  keys = {
    { "<leader>Du", ":DevcontainerUp<CR>", desc = "DevContainer: up" },
    { "<leader>Dc", ":DevcontainerConnect<CR>", desc = "DevContainer: connect" },
    { "<leader>Dd", ":DevcontainerDown<CR>", desc = "DevContainer: down" },
    { "<leader>De", ":DevcontainerExec direction='vertical' size='40'<CR>", desc = "DevContainer: exec (vsplit)" },
    { "<leader>Db", ":DevcontainerExec cmd='cd build && make'<CR>", desc = "DevContainer: build" },
    { "<leader>Dt", ":DevcontainerExec cmd='cd build && make test' direction='horizontal'<CR>", desc = "DevContainer: test" },
    { "<leader>DT", "<CMD>DevContainerToggle<CR>", desc = "DevContainer: toggle term" },
  },
}
```

---

## Dev Container template

Use this minimal `devcontainer.json` as a starting point:

```jsonc
// .devcontainer/devcontainer.json
{
  "name": "my-app-dev",
  // Use a base image with common dev tools
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",

  // Run your dotfiles or additional setup here too
  "postCreateCommand": "echo 'ready'",

  // Forward ports you care about
  "forwardPorts": [3000, 8080],

  // VS Code properties are ignored by Neovim, but harmless to keep
  "customizations": {
    "vscode": { "settings": {} }
  }
}
```

If you don’t have a `.devcontainer/` folder yet, create it and drop this file in.

---

## Troubleshooting

**`devcontainer: command not found`**
Install the Dev Container CLI and ensure it is in `$PATH`. For example: `npm i -g @devcontainers/cli`.

**`Cannot connect to the Docker daemon` / permission errors**
Make sure Docker Desktop / daemon is running. On Linux, your user may need to be in the `docker` group (re‑login after adding).

**I want faster start‑ups**
Set `remove_existing_container = false` to reuse the previous container and rely on image caching where possible.

**The terminal disappears after `:DevcontainerUp`**
That’s by design when the process finishes successfully. Re‑open it with `:DevContainerToggle` if you want to inspect the log.

**How do I toggle the terminal while a task runs?**
Press `t` in normal mode during a running task to hide the window; `:DevContainerToggle` brings it back.

---

## FAQ

**Do I have to run Neovim *inside* the container?**
No. You can either keep Neovim on the host and use `:DevcontainerExec`, or connect and run Neovim inside the container with `:DevcontainerConnect`—whichever matches your workflow.

**How is this different from other plugins?**
This plugin focuses on using the official Dev Container CLI and avoids imposing opinions. Similar projects include `esensar/nvim-dev-container` and `arnaupv/nvim-devcontainer-cli`; if you prefer a different model (e.g., host Neovim + remote LSP servers), compare approaches and pick what suits you.

**Where should I keep my dotfiles?**
Point `dotfiles_repository` to any repo. The plugin will clone that repo into the container and run your setup script (`dotfiles_installCommand`).

---

## Credits

Inspired by the work of @arnaupv, @esensar, and @jamestthompson3. Big thanks to the Dev Containers team for the CLI and spec.

---

## License

MIT — see [`LICENSE`](./LICENSE).

[`devcontainer` CLI]: https://github.com/devcontainers/cli
