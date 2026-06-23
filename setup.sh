#!/bin/bash

set -e

# ==========================================
# CONFIGURATION
# ==========================================

# Get terminal width dynamically
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
LINE_WIDTH=$((TERM_WIDTH > 80 ? 80 : TERM_WIDTH))

# ==========================================
# COLOR DEFINITIONS & STYLES
# ==========================================

# Text styles
BOLD="\e[1m"
DIM="\e[2m"
ITALIC="\e[3m"
UNDERLINE="\e[4m"
RESET="\e[0m"

# Foreground colors
CYAN="\e[36m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
RED="\e[31m"
WHITE="\e[97m"

# Background colors
BG_GREEN="\e[42m"
BG_RED="\e[41m"
BG_BLUE="\e[44m"
BG_MAGENTA="\e[45m"

# ==========================================
# UI COMPONENTS
# ==========================================

# Icons (using Nerd Font or standard Unicode)
ICON_START="➜"
ICON_SUCCESS="✔"
ICON_SKIP="➟"
ICON_ALERT="⚠"
ICON_ERROR="✖"
ICON_INFO="ℹ"
ICON_GEAR="⚙"
ICON_PACKAGE="📦"
ICON_ROCKET="🚀"
ICON_CHECK="✓"
ICON_ARROW="→"
ICON_BULLET="•"

# Build a horizontal line
build_line() {
    local char="${1:-─}"
    local color="${2:-$DIM}"
    printf "%b" "$color"
    printf '%*s' "$LINE_WIDTH" '' | tr ' ' "$char"
    printf "%b\n" "$RESET"
}

# Print a horizontal separator
print_separator() {
    build_line "─"
}

# Print a double-line separator (for major sections)
print_double_separator() {
    build_line "═"
}

# Print a step header with clear visual hierarchy
print_step() {
    echo
    print_separator
    echo -e "${CYAN}${ICON_START}${RESET} ${BOLD}${WHITE}$1${RESET}"
    print_separator
}

# Print a major section header
print_header() {
    echo
    print_double_separator
    echo -e "${MAGENTA}${ICON_ROCKET}${RESET} ${BOLD}${MAGENTA}$1${RESET}"
    print_double_separator
}

# Print success message
print_success() {
    echo -e "  ${GREEN}${ICON_SUCCESS}${RESET} ${GREEN}$1${RESET}"
}

# Print skip message
print_skip() {
    echo -e "  ${YELLOW}${ICON_SKIP}${RESET} ${DIM}$1${RESET}"
}

# Print info message
print_info() {
    echo -e "  ${BLUE}${ICON_INFO}${RESET} ${BLUE}$1${RESET}"
}

# Print warning message
print_warning() {
    echo -e "  ${YELLOW}${ICON_ALERT}${RESET} ${YELLOW}$1${RESET}"
}

# Print error message
print_error() {
    echo -e "  ${RED}${ICON_ERROR}${RESET} ${BOLD}${RED}$1${RESET}"
}

# Print a task in progress
print_progress() {
    echo -ne "  ${CYAN}${ICON_GEAR}${RESET} ${CYAN}$1...${RESET}"
}

# Complete a progress task
print_done() {
    echo -e "\r  ${GREEN}${ICON_CHECK}${RESET} ${GREEN}$1${RESET}        "
}

# Print a package being installed
print_package() {
    echo -e "  ${BLUE}${ICON_PACKAGE}${RESET} Installing ${BOLD}${WHITE}$1${RESET}"
}

# Print a centered message in a box
print_boxed() {
    local text="$1"
    local color="${2:-$MAGENTA}"
    local padding=4
    local text_len=${#text}
    local box_width=$((text_len + padding * 2))
    
    printf "%b┏%*s┓%b\n" "$color" "$box_width" '' | tr ' ' '━'
    printf "%b┃%*s%b%s%b%*s%b┃%b\n" "$color" "$padding" '' "$BOLD$WHITE" "$text" "$RESET" "$padding" '' "$color"
    printf "%b┗%*s┛%b\n" "$color" "$box_width" '' | tr ' ' '━'
}

# Print a confirmation prompt
confirm_step() {
    local prompt="${1:-Continue?}"
    echo -ne "\n${YELLOW}${ICON_ARROW}${RESET} ${BOLD}$prompt${RESET} [Y/n] "
    read -r response
    [[ "$response" =~ ^[Nn]$ ]] && return 1
    return 0
}

# Print a completion banner
print_banner() {
    echo
    print_double_separator
    echo -e "${BOLD}${GREEN}  $1${RESET}"
    print_double_separator
    echo
}

# ==========================================
# WELCOME SCREEN
# ==========================================

print_welcome() {
    clear
    
    # ASCII Art with gradient-like effect
    echo -e "${CYAN}"
    cat << "EOF"
    ___         __        ____           __                __         
   /   | __  __/ /_____  / __/___  _____/ /_____ ______   / /__  _____
  / /| |/ / / / __/ __ \/ /_/ __ \/ ___/ __/ __ `/ ___/  / / _ \/ ___/
 / ___ / /_/ / /_/ /_/ / __/ /_/ / /  / /_/ /_/ / /     / /  __/ /    
/_/  |_\__,_/\__/\____/_/  \____/_/   \__/\__,_/_/     /_/\___/_/     
EOF
    echo -e "${RESET}"
    
    # Subtitle box
    print_boxed "Automated Arch Linux Environment Setup" "$MAGENTA"
    
    echo
    echo -e "  ${DIM}This script will configure:${RESET}"
    echo -e "    ${CYAN}${ICON_BULLET}${RESET} System packages & updates"
    echo -e "    ${CYAN}${ICON_BULLET}${RESET} Development tools & environments"
    echo -e "    ${CYAN}${ICON_BULLET}${RESET} Desktop applications & fonts"
    echo -e "    ${CYAN}${ICON_BULLET}${RESET} System services & virtualization"
    echo
    echo -e "  ${DIM}Estimated time: 15-30 minutes depending on connection speed${RESET}"
    echo
    
    sleep 1
}

# ==========================================
# SCRIPT EXECUTION
# ==========================================

print_welcome

# Optional: Confirm before starting
# confirm_step "Begin installation?" || exit 0

print_header "System Preparation"

print_step "Updating System"
print_progress "Updating package database"
sudo pacman -Syu --noconfirm >/dev/null 2>&1
print_done "System packages updated"

print_header "Package Installation"

print_step "Installing Official Repository Packages"

# Define package groups for better organization
DEV_TOOLS="git github-cli base-devel gcc gdb cmake ninja clang"
PYTHON_STACK="python python-pip"
JS_STACK="nodejs npm"
JAVA_STACK="maven gradle jdk21-openjdk"
RUST_STACK="rust cargo"
DATABASES="postgresql redis sqlite"
CONTAINERS="docker"
TERMINAL="kitty neovim tmux"
SYSTEM_UTILS="btop fastfetch ripgrep fzf fd bat zoxide eza jq tree"
NETWORK="curl wget"
ARCHIVE="unzip p7zip"
FLATPAK="flatpak"
BROWSERS="firefox telegram-desktop discord"
MEDIA="vlc mpv obs-studio"
OFFICE="gwenview okular libreoffice-fresh"
SECURITY="nmap wireshark-qt"
HYPRLAND="waybar hyprpaper dunst wl-clipboard grim slurp xdg-desktop-portal-hyprland"
AUDIO="pipewire wireplumber"
FILE_MANAGER="thunar thunar-archive-plugin thunar-volman gvfs tumbler ffmpegthumbnailer file-roller dolphin ark"
FONTS="ttf-dejavu ttf-liberation noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono otf-font-awesome"
BLUETOOTH="bluez bluez-utils blueman"
VIRT="qemu-full virt-manager dnsmasq edk2-ovmf linux-headers"
STORAGE="android-tools ntfs-3g exfatprogs"
PRINTING="cups system-config-printer"

# Install all packages
print_info "Installing development tools..."
print_info "Installing system utilities..."
print_info "Installing desktop environment..."
print_info "Installing applications..."

sudo pacman -S --needed --noconfirm \
    $DEV_TOOLS \
    $PYTHON_STACK \
    $JS_STACK \
    $JAVA_STACK \
    $RUST_STACK \
    $DATABASES \
    $CONTAINERS \
    $TERMINAL \
    $SYSTEM_UTILS \
    $NETWORK \
    $ARCHIVE \
    $FLATPAK \
    $BROWSERS \
    $MEDIA \
    $OFFICE \
    $SECURITY \
    $HYPRLAND \
    $AUDIO \
    $FILE_MANAGER \
    $FONTS \
    $BLUETOOTH \
    $VIRT \
    $STORAGE \
    $PRINTING

print_success "All official packages installed successfully"

print_header "System Services Configuration"

print_step "Enabling System Services"

print_progress "Configuring Docker"
sudo systemctl enable docker >/dev/null 2>&1
sudo usermod -aG docker "$USER"
print_done "Docker enabled and user added to docker group"

if [ ! -f /var/lib/postgres/data/PG_VERSION ]; then
    print_progress "Initializing PostgreSQL database"
    sudo mkdir -p /var/lib/postgres/data
    sudo chown postgres:postgres /var/lib/postgres/data
    sudo -iu postgres initdb --locale=en_US.UTF-8 -D /var/lib/postgres/data >/dev/null 2>&1
    print_done "PostgreSQL initialized"
else
    print_skip "PostgreSQL database already initialized"
fi

print_progress "Enabling PostgreSQL service"
sudo systemctl enable postgresql >/dev/null 2>&1
print_done "PostgreSQL service enabled"

print_progress "Enabling Bluetooth service"
sudo systemctl enable bluetooth >/dev/null 2>&1
print_done "Bluetooth service enabled"

print_progress "Enabling CUPS printing service"
sudo systemctl enable cups >/dev/null 2>&1
print_done "CUPS Printing service enabled"

print_progress "Configuring Libvirt virtualization"
sudo systemctl enable libvirtd >/dev/null 2>&1
sudo usermod -aG libvirt "$USER"
print_done "Libvirt enabled and user added to libvirt group"

print_header "Flatpak Configuration"

print_step "Setting up Flatpak"

if ! flatpak remotes | grep -q flathub; then
    print_progress "Adding Flathub repository"
    sudo flatpak remote-add --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1
    print_done "Flathub repository added"
else
    print_skip "Flathub already configured"
fi

print_step "Installing Flatpak Applications"

print_package "Arduino IDE 2"
print_package "Postman"
print_package "Burp Suite"

flatpak install -y flathub \
    cc.arduino.IDE2 \
    com.getpostman.Postman \
    com.portswigger.BurpSuite >/dev/null 2>&1

print_success "Flatpak applications installed"

print_header "Development Environment"

print_step "Configuring Node.js Package Managers"

print_progress "Enabling Corepack"
sudo corepack enable >/dev/null 2>&1
print_done "Corepack enabled"

print_progress "Activating pnpm"
corepack prepare pnpm@latest --activate >/dev/null 2>&1
print_done "pnpm activated"

print_step "Java Environment"

print_info "Current Java status:"
archlinux-java status

# ==========================================
# COMPLETION
# ==========================================

echo
print_banner "🎉 SETUP COMPLETE!"

echo -e "${BOLD}${YELLOW}  ⚠️  ATTENTION REQUIRED:${RESET}"
echo
echo -e "  Please ${BOLD}${RED}LOG OUT${RESET} and ${BOLD}${RED}LOG BACK IN${RESET} for group changes to take effect."
echo -e "  The following permissions require re-login:"
echo
echo -e "    ${RED}${ICON_BULLET}${RESET} Docker group membership"
echo -e "    ${RED}${ICON_BULLET}${RESET} Libvirt group membership"
echo
echo -e "  ${DIM}Run 'groups' after re-login to verify.${RESET}"
echo
