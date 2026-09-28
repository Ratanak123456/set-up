# NEON Workstation v6 — fully keyboard-operable

A developer-tools installer for an **existing Arch Linux installation**. Does not install Arch, Hyprland, Noctalia, drivers or dotfiles.

## Run

```bash
chmod +x install.sh
./install.sh --demo   # UI and simulated tasks only; no sudo
./install.sh          # actual software installation
```

The launcher installs `python python-textual` on request when they are missing (requires a full Arch upgrade for consistency). Launch in a real terminal. The full installation can upgrade your operating system; finish a verified backup first.

## Keyboard navigation (mouse never required)

| Screen | Key | Action |
|---|---|---|
| Welcome | Enter | Continue to package screen (when Continue is focused initially) |
| Welcome | D | Open simulated preview |
| Welcome | Q | Quit |
| All screens | Tab / Shift+Tab | Move to next / previous focusable control |
| Dashboard | F2 / Ctrl+1 | Focus package categories |
| Dashboard | F3 / Ctrl+2 | Focus Docker options |
| Dashboard | F4 / Ctrl+3 | Focus optional AUR packages |
| Dashboard | F5 / Ctrl+4 | Focus operation log |
| Selection lists | Up / Down | Move between entries |
| Selection lists | Space | Check/uncheck focused entry |
| Docker radio options | Up / Down | Switch choice; Space to select if necessary |
| Dashboard | F6 / Ctrl+S | Start actual installation (disabled in `--demo`) |
| Dashboard | F7 / Ctrl+P | Simulate installation, **no system changes** |
| Dashboard | F1 / Ctrl+H | Welcome (when no task running) |
| Anywhere | Ctrl+Q | Quit |
| Confirm dialogs | Y / N / Esc | Confirm / decline / cancel |
| Docker Desktop path dialog | Enter | Submit typed `.pkg.tar.zst` path without changing focus |

**Laptop Fn keys:** If your terminal intercepts F1–F7, use the Ctrl alternatives, or Tab through controls. A visible focused border highlights the current area.

Ctrl+S replaces Ctrl+I for installation because terminals commonly send Ctrl+I as Tab. If your terminal intercepts Ctrl+S for flow control, use F6 or Tab to the Install button.

The installer runs a full system upgrade before installing packages and logs to `~/.local/state/neon-workstation-v6/`. Docker Engine is installed but not automatically started, and your user is intentionally not granted Docker's root-equivalent group privileges. AUR packages are third-party; review them before allowing installation.

## Test before running on a fresh installation

1. `./install.sh --demo`
2. On welcome press Enter.
3. Press F2 (or Ctrl+1), move with arrows and toggle with Space.
4. Press F3 (or Ctrl+2), select one Docker option.
5. Press F4 (or Ctrl+3), select an optional AUR application.
6. Press F7 (or Ctrl+P) to view simulated progress.
7. Press F1 (or Ctrl+H) to return to Welcome.

Automated headless UI checks run without sudo or package installation:

```bash
python -m unittest discover -s tests -v
```

These cover startup, keyboard navigation, previews, confirmation cancellation, repeated start protection, demo restrictions, Docker command construction, upgrade failure handling, and saved error logs. They have passed on Textual 8.2.8; actual package installation and terminal-specific key handling still depend on your system.
