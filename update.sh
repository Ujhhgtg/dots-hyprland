#!/bin/bash
# This script updates the dotfiles by fetching the latest version from the Git repository

cd "$(dirname "$0")"

# GREEN="\033[0;32m"
# RED="\033[0;31m"
# BLUE="\033[0;34m"
# CYAN="\033[0;36m"
# YELLOW="\033[1;33m"
# MAGENTA="\033[0;35m"
# RESET="\033[0m"

git pull
