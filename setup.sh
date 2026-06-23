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
BLACK="\e[30m"
CYAN="\e[36m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
RED="\e[31m"
WHITE="\e[97m"
ORANGE="\e[38;5;208m"
PINK="\e[38;5;205m"
TEAL="\e[38;5;6m"

# Background colors
BG_GREEN="\e[42m"
BG_RED="\e[41m"
BG_BLUE="\e[44m"
BG_MAGENTA="\e[45m"
BG_CYAN="\e[46m"
BG_DARK="\e[48;5;235m"
BG_BLACK="\e[40m"

# ==========================================
# ADVANCED UI COMPONENTS
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
ICON_STAR="★"
ICON_HEART="♥"
ICON_FIRE="🔥"
ICON_LIGHTNING="⚡"
ICON_CROWN="♔"
ICON_DIAMOND="♦"

# Spinner frames for loading animations
SPINNER_FRAMES=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")

# ==========================================
# CORE UI FUNCTIONS
# ==========================================

# Hide cursor
hide_cursor() {
    printf "\e[?25l"
}

# Show cursor
show_cursor() {
    printf "\e[?25h"
}

# Move cursor up N lines
cursor_up() {
    printf "\e[%dA" "$1"
}

# Move cursor down N lines
cursor_down() {
    printf "\e[%dB" "$1"
}

# Clear current line
clear_line() {
    printf "\r\e[K"
}

# Build a horizontal line with optional styling
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

# Print a gradient-style line
print_gradient_line() {
    local colors=("$CYAN" "$BLUE" "$MAGENTA" "$PINK" "$RED" "$ORANGE" "$YELLOW" "$GREEN" "$TEAL")
    local segment_width=$((LINE_WIDTH / 9))
    local remainder=$((LINE_WIDTH % 9))

    for i in "${!colors[@]}"; do
        printf "%b" "${colors[$i]}"
        local width=$segment_width
        [[ $i -eq 8 ]] && width=$((width + remainder))
        printf '%*s' "$width" '' | tr ' ' "━"
    done
    printf "%b\n" "$RESET"
}

# Print a step header with clear visual hierarchy
print_step() {
    echo
    print_gradient_line
    echo -e "${CYAN}${ICON_START}${RESET} ${BOLD}${WHITE}$1${RESET}"
    print_gradient_line
}

# Print a major section header with enhanced styling
print_header() {
    echo
    print_gradient_line
    echo -e "${MAGENTA}${ICON_ROCKET}${RESET} ${BOLD}${MAGENTA}$1${RESET} ${MAGENTA}${ICON_ROCKET}${RESET}"
    print_gradient_line
}

# Print success message with checkmark
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

# Print a task in progress with spinner
print_progress() {
    echo -ne "  ${CYAN}${ICON_GEAR}${RESET} ${CYAN}$1...${RESET}"
}

# Complete a progress task with animation
print_done() {
    echo -e "\r  ${GREEN}${ICON_CHECK}${RESET} ${GREEN}$1${RESET}        "
}

# Print a package being installed
print_package() {
    echo -e "  ${BLUE}${ICON_PACKAGE}${RESET} Installing ${BOLD}${WHITE}$1${RESET}"
}

# Print a centered message in an enhanced box
print_boxed() {
    local text="$1"
    local color="${2:-$MAGENTA}"
    local icon="${3:-$ICON_STAR}"
    local padding=6
    local text_len=${#text}
    local box_width=$((text_len + padding * 2))

    # Top border with corners
    printf "%b╭%*s╮%b\n" "$color" "$box_width" '' | tr ' ' '─'

    # Content line with icon
    printf "%b│%*s%b%s%b%*s%b│%b\n"         "$color" "$((padding - 2))" ''         "$BOLD$WHITE" "$icon $text $icon" "$RESET"         "$((padding - 2))" '' "$color"

    # Bottom border
    printf "%b╰%*s╯%b\n" "$color" "$box_width" '' | tr ' ' '─'
}

# Print a confirmation prompt
confirm_step() {
    local prompt="${1:-Continue?}"
    echo -ne "\n${YELLOW}${ICON_ARROW}${RESET} ${BOLD}$prompt${RESET} [${GREEN}Y${RESET}/${RED}n${RESET}] "
    read -r response
    [[ "$response" =~ ^[Nn]$ ]] && return 1
    return 0
}

# Print a completion banner
print_banner() {
    echo
    print_gradient_line
    echo -e "${BOLD}${GREEN}  $1${RESET}"
    print_gradient_line
    echo
}

# ==========================================
# ANIMATION FUNCTIONS
# ==========================================

# Typewriter effect for text
typewrite() {
    local text="$1"
    local color="${2:-$RESET}"
    local delay="${3:-0.02}"

    printf "%b" "$color"
    for ((i=0; i<${#text}; i++)); do
        printf "%s" "${text:$i:1}"
        sleep "$delay"
    done
    printf "%b\n" "$RESET"
}

# Animated spinner for long-running tasks
spinner() {
    local pid=$1
    local message="$2"
    local color="${3:-$CYAN}"

    hide_cursor
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        local frame="${SPINNER_FRAMES[$i]}"
        printf "\r  %b%s%b %s..." "$color" "$frame" "$RESET" "$message"
        i=$(((i + 1) % 10))
        sleep 0.1
    done
    clear_line
    show_cursor
}

# Progress bar animation
progress_bar() {
    local current=$1
    local total=$2
    local width=40
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))

    printf "\r  ["
    printf "%b%*s%b" "$GREEN" "$filled" '' | tr ' ' '█'
    printf "%b%*s%b" "$DIM" "$empty" '' | tr ' ' '░'
    printf "] %3d%%" "$percentage"
}

# Fade in effect for ASCII art
fade_in_ascii() {
    local lines=("$@")
    local colors=("$DIM" "$DIM" "$CYAN" "$CYAN" "$WHITE" "$WHITE" "$BOLD$WHITE" "$BOLD$WHITE")

    for ((i=0; i<${#lines[@]}; i++)); do
        printf "%b%s%b\n" "${colors[$i]:-$WHITE}" "${lines[$i]}" "$RESET"
        sleep 0.08
    done
}

# Pulse animation for important text
pulse_text() {
    local text="$1"
    local color="${2:-$MAGENTA}"
    local cycles="${3:-3}"

    for ((c=0; c<cycles; c++)); do
        for intensity in "$DIM" "$color" "$BOLD$color"; do
            printf "\r%b%s%b" "$intensity" "$text" "$RESET"
            sleep 0.15
        done
    done
    echo
}

# ==========================================
# WELCOME SCREEN
# ==========================================

print_welcome() {
    clear

    # Your requested ASCII Art with enhanced styling
    echo -e "${CYAN}"
    cat << "EOF"
█▀▀▀▀▀▀▀▀▀▀▓ ▄▀▀▀▀▀▀▀▀▀█ █▀▀▀▀▀▀▀▀▀▀█ █▀▀▀▀█ ▓▀▀▀█ █▀▀▀▀▀▀▀▀▀▄
▀ ▄▄▄ ∙ ▒ █· ▄▄▄▄▄▄█ █▄▄▄· ▄▄▄█ ▀ ▓ ▒. █ ▀ ▄▄ ∙ █
▓ ▓ ▀▀▀▀▀ ▓ . ▓▄▄▄▄▄▄ ▓ . ▓ ▓ ▓ ▒ ▓ ▓ ▓▄▌ ▓
░▄▄▄ ▀▀▀▀▀▀▒ ▒ ∙ ▄▄▄▄▄▄▒ ▒ ∙ ▒ ▒ · ▒ ▓ ▒ ▒ ·▄▄▄▄▄▀
▄▄▄▄▄ ▒ .░ ░ ░▄▄▄▄▄▄ ░ ░ ░ ░▄░·. ░ ░ . ░
▓ ▀▀▀▀∙ █ █ . ·█ █ █ █ . █ █ █
░▄▄▄▄▄▄▄▄▄▄█ █▄▄▄▄▄▄▄▄▄▄█ █▄▄▄▄█ █▄▄▄▄▄▄▄▄▄▄█ █▄▄▄▄█
EOF
    echo -e "${RESET}"

    # Animated separator
    print_gradient_line

    # Subtitle with typewriter effect
    typewrite "  Automated Arch Linux Environment Setup" "$MAGENTA" 0.01

    # Enhanced info box
    echo
    print_boxed "System Configuration Ready" "$CYAN" "$ICON_ROCKET"

    echo
    echo -e "  ${DIM}This script will configure:${RESET}"
    echo
    echo -e "    ${CYAN}${ICON_BULLET}${RESET} ${BOLD}System packages & updates${RESET}       ${DIM}— core system maintenance${RESET}"
    echo -e "    ${GREEN}${ICON_BULLET}${RESET} ${BOLD}Development tools & environments${RESET} ${DIM}— dev stacks & build tools${RESET}"
    echo -e "    ${MAGENTA}${ICON_BULLET}${RESET} ${BOLD}Desktop applications & fonts${RESET}     ${DIM}— GUI apps & typography${RESET}"
    echo -e "    ${YELLOW}${ICON_BULLET}${RESET} ${BOLD}System services & virtualization${RESET} ${DIM}— daemons & VMs${RESET}"
    echo

    # Time estimate with icon
    echo -e "  ${ORANGE}${ICON_LIGHTNING}${RESET} ${DIM}Estimated time: ${BOLD}15-30 minutes${RESET}${DIM} depending on connection speed${RESET}"
    echo

    # Animated ready indicator
    pulse_text "  ${ICON_CROWN}  Ready to begin installation  ${ICON_CROWN}" "$GREEN" 2
    echo

    sleep 0.5
}

# ==========================================
# ENHANCED PROGRESS TRACKING
# ==========================================

# Track installation progress with visual feedback
track_installation() {
    local current=$1
    local total=$2
    local package="$3"

    clear_line
    printf "  ${CYAN}%s${RESET} ${DIM}[%d/%d]${RESET} Installing ${BOLD}${WHITE}%s${RESET}"         "$ICON_GEAR" "$current" "$total" "$package"
}

# Print a completion checklist
print_checklist() {
    local items=("$@")
    echo
    for item in "${items[@]}"; do
        echo -e "  ${GREEN}${ICON_CHECK}${RESET} ${WHITE}${item}${RESET}"
        sleep 0.1
    done
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
sudo pacman -Syu --noconfirm >/dev/null 2>&1 &
spinner $! "Updating package database" "$CYAN"
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

# Install all packages with progress tracking
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
sudo systemctl enable docker >/dev/null 2>&1 &
spinner $! "Configuring Docker" "$BLUE"
sudo usermod -aG docker "$USER"
print_done "Docker enabled and user added to docker group"

if [ ! -f /var/lib/postgres/data/PG_VERSION ]; then
    print_progress "Initializing PostgreSQL database"
    sudo mkdir -p /var/lib/postgres/data
    sudo chown postgres:postgres /var/lib/postgres/data
    sudo -iu postgres initdb --locale=en_US.UTF-8 -D /var/lib/postgres/data >/dev/null 2>&1 &
    spinner $! "Initializing PostgreSQL" "$MAGENTA"
    print_done "PostgreSQL initialized"
else
    print_skip "PostgreSQL database already initialized"
fi

print_progress "Enabling PostgreSQL service"
sudo systemctl enable postgresql >/dev/null 2>&1 &
spinner $! "Enabling PostgreSQL" "$MAGENTA"
print_done "PostgreSQL service enabled"

print_progress "Enabling Bluetooth service"
sudo systemctl enable bluetooth >/dev/null 2>&1 &
spinner $! "Enabling Bluetooth" "$BLUE"
print_done "Bluetooth service enabled"

print_progress "Enabling CUPS printing service"
sudo systemctl enable cups >/dev/null 2>&1 &
spinner $! "Enabling CUPS" "$YELLOW"
print_done "CUPS Printing service enabled"

print_progress "Configuring Libvirt virtualization"
sudo systemctl enable libvirtd >/dev/null 2>&1 &
spinner $! "Configuring Libvirt" "$CYAN"
sudo usermod -aG libvirt "$USER"
print_done "Libvirt enabled and user added to libvirt group"

print_header "Flatpak Configuration"

print_step "Setting up Flatpak"

if ! flatpak remotes | grep -q flathub; then
    print_progress "Adding Flathub repository"
    sudo flatpak remote-add --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 &
    spinner $! "Adding Flathub" "$GREEN"
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
    com.portswigger.BurpSuite >/dev/null 2>&1 &
spinner $! "Installing Flatpak apps" "$PINK"

print_success "Flatpak applications installed"

print_header "Development Environment"

print_step "Configuring Node.js Package Managers"

print_progress "Enabling Corepack"
sudo corepack enable >/dev/null 2>&1 &
spinner $! "Enabling Corepack" "$GREEN"
print_done "Corepack enabled"

print_progress "Activating pnpm"
corepack prepare pnpm@latest --activate >/dev/null 2>&1 &
spinner $! "Activating pnpm" "$GREEN"
print_done "pnpm activated"

print_step "Java Environment"

print_info "Current Java status:"
archlinux-java status

# ==========================================
# COMPLETION
# ==========================================

echo
print_banner "${ICON_FIRE} SETUP COMPLETE! ${ICON_FIRE}"

# Summary checklist
echo -e "${BOLD}${WHITE}  Installation Summary:${RESET}"
print_checklist \
    "System packages updated" \
    "Development tools installed" \
    "Desktop environment configured" \
    "System services enabled" \
    "Flatpak applications installed" \
    "Node.js environment ready"

echo
echo -e "${BOLD}${YELLOW}  ${ICON_ALERT} ATTENTION REQUIRED:${RESET}"
echo
echo -e "  Please ${BOLD}${RED}LOG OUT${RESET} and ${BOLD}${RED}LOG BACK IN${RESET} for group changes to take effect."
echo -e "  The following permissions require re-login:"
echo
echo -e "    ${RED}${ICON_BULLET}${RESET} Docker group membership"
echo -e "    ${RED}${ICON_BULLET}${RESET} Libvirt group membership"
echo
echo -e "  ${DIM}Run 'groups' after re-login to verify.${RESET}"
echo

# Final animated message
pulse_text "  ${ICON_HEART}  Thank you for using Arch Setup  ${ICON_HEART}" "$MAGENTA" 2
