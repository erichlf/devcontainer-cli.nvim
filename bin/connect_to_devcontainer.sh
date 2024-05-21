#!/bin/bash

set -e
# The following code creates a new terminal (using gnome-terminal) and it
# connects to the container using the devcontainer built in command.
# TODO: Add a check to see if the container is running.
# TODO: Give the possibility of using multiple terminals, not only gnome-terminal
# TODO: Give the possibility of opening a new tmux page instead of opening a new container

if [ -n "$TMUX" ]; then
  tmux_open="tmux split-window -h -t \"$TMUX_PANE\" "
else
  tmux_open=""
fi

# Execute the command for opening the devcontainer in the following terminal:
if [ -x "$(command -v alacritty)" ]; then
	# ALACRITTY TERMINAL EMULATOR
	REPOSTORY_NAME=$(basename "$(pwd)")
	TERMINAL_TITLE="Devcontainer [${REPOSTORY_NAME}]"
	command="alacritty --working-directory . --title "${TERMINAL_TITLE}" -e ${tmux_open}$@ &"
elif [ -x "$(command -v gnome-terminal)" ]; then
	# GNOME TERMINAL
	command="gnome-terminal -- ${tmux_open}$@"
elif [ "$(uname)" == "Darwin" ] && [ -x "$(command -v iTerm)" ]; then
	# MAC ITERM2 TERMINAL EMULATOR
	command="open -a iTerm.app ${tmux_open}$@"
elif [ "$(uname)" == "Darwin" ] && [ -x "$(command -v Terminal)" ]; then
	# MAC TERMINAL
	command="open -a Terminal.app ${tmux_open}$@"
else
	# TERMINAL NO DEFINED
	echo "ERROR: No compatible emulators found!"
  exit 1
fi

eval "${command}"
