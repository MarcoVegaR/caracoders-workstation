#!/usr/bin/env bash
# Caracoders workstation shell integration. No custom aliases in v1.

CARACODERS_WORKSTATION_HOME="$HOME/.config/caracoders-workstation"

if [ -f "$CARACODERS_WORKSTATION_HOME/bash/path.sh" ]; then
  . "$CARACODERS_WORKSTATION_HOME/bash/path.sh"
fi

# Starship is installed and configured by the repo, but this file does not auto-enable
# the prompt from this shared dotfile because Starship activation requires executing
# generated shell initialization code. Enable manually only after review.
