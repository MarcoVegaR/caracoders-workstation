#!/usr/bin/env bash
# Path additions for Caracoders workstation. No aliases are defined here.

if [ -d "$HOME/.config/composer/vendor/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.config/composer/vendor/bin:"*) ;;
    *) export PATH="$HOME/.config/composer/vendor/bin:$PATH" ;;
  esac
fi

export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"
fi

if [ -d "$HOME/.local/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
fi
