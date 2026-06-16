#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# ==========================================
# COLOR DEFINITIONS & UI COMPONENTS
# ==========================================
# Text Styles
BOLD="\e[1m"
DIM="\e[2m"
RESET="\e[0m"

# Foreground Colors
CYAN="\e[36m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
RED="\e[31m"

# UI Helpers
ICON_START="${CYAN}➜${RESET}"
ICON_SUCCESS="${GREEN}✔${RESET}"
ICON_SKIP="${YELLOW}➔${RESET}"
ICON_ALERT="${RED}➔${RESET}"
LINE="${DIM}──────────────────────────────────────────────────${RESET}"

print_step() {
    echo -e "\n${LINE}"
    echo -e "${ICON_START} ${BOLD}${CYAN}$1${RESET}"
    echo -e "${LINE}"
}

print_success() {
    echo -e "${ICON_SUCCESS} ${GREEN}$1${RESET}"
}

print_skip() {
    echo -e "${ICON_SKIP} ${DIM}$1${RESET}"
}

print_welcome() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
█▀▀▀▀▀▀▀▀▀▀▓   ▄▀▀▀▀▀▀▀▀▀█ █▀▀▀▀▀▀▀▀▀▀█ █▀▀▀▀█ ▓▀▀▀█ █▀▀▀▀▀▀▀▀▀▄
▀    ▄▄▄ ∙ ▒ █·    ▄▄▄▄▄▄█ █▄▄▄·    ▄▄▄█ ▀    ▓ ▒.  █ ▀    ▄▄  ∙ █
▓    ▓ ▀▀▀▀▀ ▓   . ▓▄▄▄▄▄▄    ▓   . ▓    ▓    ▓ ▒   ▓ ▓    ▓▄▌   ▓
░▄▄▄ ▀▀▀▀▀▀▒ ▒ ∙  ▄▄▄▄▄▄▒    ▒ ∙  ▒    ▒   · ▒ ▓   ▒ ▒   ·▄▄▄▄▄▀
▄▄▄▄▄  ▒  .░ ░    ░▄▄▄▄▄▄    ░    ░    ░    ░▄░·. ░ ░ .  ░       
▓    ▀▀▀▀∙  █ █    .    ·█    █    █    █    .       █ █    █      
░▄▄▄▄▄▄▄▄▄▄█ █▄▄▄▄▄▄▄▄▄▄█    █▄▄▄▄█    █▄▄▄▄▄▄▄▄▄▄█ █▄▄▄▄█      
EOF
    echo -e "${RESET}"
    echo -e "${MAGENTA}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET}"
    echo -e "${MAGENTA}┃${RESET} ${BOLD}${GREEN}Welcome to your Automated Arch Linux Environment Setup${RESET} ${MAGENTA}┃${RESET}"
    echo -e "${MAGENTA}┃${RESET} ${DIM}This script will configure packages, services, and tools.${RESET} ${MAGENTA}┃${RESET}"
    echo -e "${MAGENTA}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET}"
    echo -e ""
    sleep 1
}

# ==========================================
# SCRIPT EXECUTION
# ==========================================

# Show the new welcome banner
print_welcome

print_step "Updating System"
sudo pacman -Syu --noconfirm
print_success "System packages updated."

print_step "Installing Official Repository Packages"
sudo pacman -S --needed --noconfirm \
    git github-cli \
    base-devel gcc gdb cmake ninja clang \
    python python-pip \
    nodejs npm yarn \
    maven gradle \
    jdk21-openjdk \
    cargo \
    postgresql redis sqlite \
    docker \
    kitty neovim tmux \
    btop bpytop fastfetch ripgrep fzf fd bat zoxide eza jq tree \
    curl wget \
    unzip p7zip \
    flatpak \
    firefox telegram-desktop discord \
    vlc mpv \
    obs-studio \
    gwenview okular libreoffice-fresh \
    nmap wireshark-qt \
    waybar hyprpaper dunst \
    wl-clipboard grim slurp \
    xdg-desktop-portal-hyprland \
    pipewire wireplumber \
    thunar thunar-archive-plugin thunar-volman gvfs tumbler ffmpegthumbnailer file-roller \
    dolphin ark \
    ttf-dejavu ttf-liberation noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono otf-font-awesome \
    bluez bluez-utils blueman \
    qemu-full virt-manager dnsmasq edk2-ovmf linux-headers \
    android-tools ntfs-3g exfatprogs \
    cups system-config-printer 2> >(grep -v "is up to date -- skipping" >&2)
print_success "Official packages successfully installed."

print_step "Enabling System Services"

# Docker
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
print_success "Docker enabled and user added to docker group."

# PostgreSQL
if [ ! -f /var/lib/postgres/data/PG_VERSION ]; then
    echo -e "${DIM}Initializing PostgreSQL database...${RESET}"
    sudo mkdir -p /var/lib/postgres/data
    sudo chown postgres:postgres /var/lib/postgres/data
    sudo -iu postgres initdb --locale=en_US.UTF-8 -D /var/lib/postgres/data
    print_success "PostgreSQL initialized."
else
    print_skip "PostgreSQL database already initialized. Skipping."
fi
sudo systemctl enable --now postgresql

# Bluetooth
sudo systemctl enable --now bluetooth
print_success "Bluetooth service enabled."

# Printing
sudo systemctl enable --now cups
print_success "CUPS Printing service enabled."

# Virtualization
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt "$USER"
print_success "Libvirtd enabled and user added to libvirt group."

print_step "Installing AUR Helper (yay)"
if ! command -v yay &>/dev/null; then
    echo -e "${DIM}yay not found. Fetching and compiling...${RESET}"
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (
        cd "$tmpdir/yay"
        makepkg -si --noconfirm
    )
    rm -rf "$tmpdir"
    print_success "yay installed successfully."
else
    print_skip "yay is already installed. Skipping build."
fi

print_step "Installing AUR Packages"
yay -S --needed --noconfirm \
    visual-studio-code-bin \
    google-chrome \
    brave-bin \
    postman-bin \
    pnpm-bin \
    burpsuite 2> >(grep -v "is up to date -- skipping" >&2)
print_success "AUR packages successfully installed."

print_step "Setting up Flatpak & Applications"
if ! flatpak remotes | grep -q "flathub"; then
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    print_success "Flathub repository added."
else
    print_skip "Flathub remote already configured. Skipping."
fi

if ! flatpak list --app | grep -q "cc.arduino.IDE2"; then
    echo -e "${DIM}Downloading Arduino IDE via Flatpak...${RESET}"
    flatpak install -y flathub cc.arduino.IDE2
    print_success "Arduino IDE 2 installed."
else
    print_skip "Arduino IDE 2 is already installed via Flatpak. Skipping."
fi

print_step "Configuring Language Environments"
sudo corepack enable
print_success "Node tools (Corepack) enabled."

echo -e "\n${BOLD}${MAGENTA}Current Java Versions:${RESET}"
archlinux-java status

# ==========================================
# FINAL ATTENTION BANNER
# ==========================================
echo -e "\n"
echo -e "${MAGENTA}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET}"
echo -e "${MAGENTA}┃${RESET}  ${BOLD}${GREEN}🎉 SETUP COMPLETE!${RESET}                                    ${MAGENTA}┃${RESET}"
echo -e "${MAGENTA}┃${RESET}                                                        ${MAGENTA}┃${RESET}"
echo -e "${MAGENTA}┃${RESET}  ${YELLOW}${BOLD}⚠️  ATTENTION REQUIRED:${RESET}                              ${MAGENTA}┃${RESET}"
echo -e "${MAGENTA}┃${RESET}  Please ${BOLD}${RED}LOG OUT${RESET} and ${BOLD}${RED}LOG BACK IN${RESET} for changes to take   ${MAGENTA}┃${RESET}"
echo -e "${MAGENTA}┃${RESET}  effect regarding Docker & Libvirt user groups.       ${MAGENTA}┃${RESET}"
echo -e "${MAGENTA}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET}"
echo -e "\n"