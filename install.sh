#!/usr/bin/env bash
set -Eeuo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
[[ $EUID -ne 0 ]] || { echo 'Run as a regular sudo-enabled user, not root.'; exit 1; }
[[ -t 0 && -t 1 ]] || { echo 'An interactive terminal is required.'; exit 1; }
command -v pacman >/dev/null || { echo 'This requires an already installed Arch Linux system.'; exit 1; }
if [[ ${1:-} == --demo ]]; then
  python -c 'from textual import work; from textual.widgets import SelectionList, RadioSet' 2>/dev/null || { echo 'Install UI dependencies: sudo pacman -Syu python python-textual'; exit 1; }
  exec python neon.py --demo
fi
if python -c 'from textual import work; from textual.widgets import SelectionList, RadioSet' 2>/dev/null; then
  sudo -v
  exec python neon.py "$@"
fi
printf '\n\033[1;36m◈  NEON WORKSTATION  /  UI BOOTSTRAP\033[0m\n'
printf 'This installs only python + python-textual for the terminal interface.\n'
printf 'A full Arch system upgrade is included to avoid a partial upgrade.\n'
read -r -p 'Bootstrap the UI using pacman -Syu? [y/N] ' answer
[[ ${answer,,} == y || ${answer,,} == yes ]] || exit 0
sudo pacman -Syu --needed python python-textual
sudo -v
exec python neon.py "$@"
