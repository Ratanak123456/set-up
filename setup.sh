#!/bin/bash

set -e

# ==========================================

# COLOR DEFINITIONS

# ==========================================

BOLD="\e[1m"
DIM="\e[2m"
RESET="\e[0m"

CYAN="\e[36m"
GREEN="\e[32m"
YELLOW="\e[33m"
MAGENTA="\e[35m"
RED="\e[31m"

ICON_START="➜"
ICON_SUCCESS="✔"
ICON_SKIP="➟"
ICON_ALERT="⚠"

print_step() {
echo -e "\n${CYAN}${ICON_START}${RESET} ${BOLD}$1${RESET}"
}

print_success() {
echo -e "${GREEN}${ICON_SUCCESS} $1${RESET}"
}

print_skip() {
echo -e "${YELLOW}${ICON_SKIP} $1${RESET}"
}

print_welcome() {
clear
echo -e "${MAGENTA}${BOLD}"
cat << "EOF"
█▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
█  ARCH AUTOMATED SETUP SCRIPT    █
█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█
EOF
echo -e "${RESET}"
echo
}

# ==========================================

# START

# ==========================================

print_welcome

print_step "Updating system"
sudo pacman -Syu --noconfirm
print_success "System updated"

# ==========================================

# OFFICIAL PACKAGES

# ==========================================

print_step "Installing official packages"

sudo pacman -S --needed --noconfirm 
git base-devel github-cli 
gcc gdb cmake ninja clang 
python python-pip 
nodejs npm 
maven gradle 
jdk21-openjdk 
rust cargo 
postgresql redis sqlite 
docker 
kitty neovim tmux 
btop fastfetch ripgrep fzf fd bat zoxide eza jq tree 
curl wget 
unzip p7zip 
flatpak 
firefox telegram-desktop discord 
vlc mpv obs-studio 
gwenview okular libreoffice-fresh 
nmap wireshark-qt 
waybar hyprpaper dunst 
wl-clipboard grim slurp 
xdg-desktop-portal-hyprland 
pipewire wireplumber 
thunar dolphin ark 
ttf-dejavu ttf-liberation noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono otf-font-awesome 
bluez bluez-utils blueman 
qemu-full virt-manager dnsmasq edk2-ovmf linux-headers 
android-tools ntfs-3g exfatprogs 
cups system-config-printer 
openssh networkmanager brightnessctl playerctl pavucontrol

print_success "Official packages installed"

# ==========================================

# SERVICES

# ==========================================

print_step "Enabling services"

sudo systemctl enable docker
sudo systemctl enable postgresql
sudo systemctl enable bluetooth
sudo systemctl enable cups
sudo systemctl enable libvirtd
sudo systemctl enable NetworkManager

sudo systemctl start NetworkManager

sudo usermod -aG docker "$USER"
sudo usermod -aG libvirt "$USER"

print_success "Services enabled"

# PostgreSQL init (safe check)

if [ ! -f /var/lib/postgres/data/PG_VERSION ]; then
print_step "Initializing PostgreSQL"
sudo -iu postgres initdb -D /var/lib/postgres/data
print_success "PostgreSQL initialized"
else
print_skip "PostgreSQL already initialized"
fi

# ==========================================

# YAY (AUR HELPER)

# ==========================================

print_step "Installing yay"

if ! command -v yay &>/dev/null; then
tmpdir=$(mktemp -d)
git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
(
cd "$tmpdir/yay"
makepkg -si --noconfirm
)
rm -rf "$tmpdir"
print_success "yay installed"
else
print_skip "yay already installed"
fi

# ==========================================

# AUR PACKAGES

# ==========================================

print_step "Installing AUR packages"

yay -S --needed --noconfirm 
visual-studio-code-bin 
google-chrome 
postman-bin 
docker-desktop 
jetbrains-toolbox 
burpsuite

print_success "AUR packages installed"

# ==========================================

# FLATPAK

# ==========================================

print_step "Setting up Flatpak"

if ! flatpak remotes | grep -q flathub; then
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

print_step "Installing Flatpak apps"

flatpak install -y flathub 
cc.arduino.IDE2 
com.portswigger.BurpSuite

print_success "Flatpak apps installed"

# ==========================================

# NODE TOOLS

# ==========================================

print_step "Configuring Node.js"

corepack enable
corepack prepare pnpm@latest --activate

print_success "pnpm enabled via Corepack"

# ==========================================

# DONE

# ==========================================

echo
echo -e "${GREEN}${BOLD}SETUP COMPLETE${RESET}"
echo -e "${YELLOW}Please reboot or log out for group changes to apply${RESET}"
