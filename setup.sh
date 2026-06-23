#!/bin/bash

set -euo pipefail

# ==========================================
# COLOR DEFINITIONS
# ==========================================

BOLD="\e[1m"
DIM="\e[2m"
RESET="\e[0m"
ITALIC="\e[3m"

CYAN="\e[36m"
GREEN="\e[32m"
YELLOW="\e[33m"
MAGENTA="\e[35m"
RED="\e[31m"
BLUE="\e[34m"
WHITE="\e[97m"
GRAY="\e[90m"

# Symbols
ARROW="▸"
CHECK="✓"
SKIP="→"
WARN="!"
BULLET="•"
SPINNER_FRAMES=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")

# ==========================================
# PRINT FUNCTIONS
# ==========================================

print_welcome() {
    clear
    echo
    echo -e "${MAGENTA}${BOLD}"
    cat << "EOF"
         __      __        ___                                           ______              ____    ____    ______         __  __  ____    
/\ \  __/\ \      /\_ \                                         /\__  _\            /\  _`\ /\  _`\ /\__  _\       /\ \/\ \/\  _`\  
\ \ \/\ \ \ \    _\//\ \     ___    ___    ___ ___      __      \/_/\ \/   ___      \ \,\L\_\ \ \L\_\/_/\ \/       \ \ \ \ \ \ \L\ \
 \ \ \ \ \ \ \ /'__`\ \ \   /'___\ / __`\/' __` __`\  /'__`\       \ \ \  / __`\     \/_\__ \\ \  _\L  \ \ \  ______\ \ \ \ \ \ ,__/
  \ \ \_/ \_\ /\  __/\_\ \_/\ \__//\ \L\ /\ \/\ \/\ \/\  __/        \ \ \/\ \L\ \      /\ \L\ \ \ \L\ \ \ \ \/\______\ \ \_\ \ \ \/ 
   \ `\___x___\ \____/\____\ \____\ \____\ \_\ \_\ \_\ \____\        \ \_\ \____/      \ `\____\ \____/  \ \_\/______/\ \_____\ \_\ 
    '\/__//__/ \/____\/____/\/____/\/___/ \/_/\/_/\/_/\/____/         \/_/\/___/        \/_____/\/___/    \/_/         \/_____/\/_/ 
EOF
    echo -e "${RESET}"
    echo -e "        ${GRAY}$(date '+%Y-%m-%d %H:%M')${RESET}"
    echo
}

print_section() {
    local title="$1"
    local icon="${2:-$ARROW}"
    echo
    printf "  ${MAGENTA}${BOLD}${icon}  %s${RESET}\n" "$title"
    printf "  ${CYAN}%*s${RESET}\n" "50" '' | tr ' ' "─"
}

print_step() {
    local msg="$1"
    printf "    ${CYAN}${BULLET}${RESET} %s ... " "$msg"
}

print_success() {
    printf "${GREEN}${CHECK}${RESET}\n"
}

print_skip() {
    printf "${YELLOW}${SKIP}${RESET} ${GRAY}(already done)${RESET}\n"
}

print_warn() {
    printf "${YELLOW}${WARN}${RESET}\n"
}

print_error() {
    printf "${RED}✗${RESET}\n"
}

spinner_start() {
    local msg="$1"
    local pid="$2"
    local i=0
    printf "    ${CYAN}%s${RESET} %s " "${SPINNER_FRAMES[0]}" "$msg"
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i + 1) % ${#SPINNER_FRAMES[@]} ))
        printf "\r    ${CYAN}%s${RESET} %s " "${SPINNER_FRAMES[$i]}" "$msg"
        sleep 0.1
    done
    printf "\r"
}

run_with_spinner() {
    local msg="$1"
    shift
    (
        "$@" >/dev/null 2>&1
    ) &
    local pid=$!
    spinner_start "$msg" "$pid"
    wait $pid
    local status=$?
    if [ $status -eq 0 ]; then
        printf "    ${GREEN}${CHECK}${RESET} %s\n" "$msg"
    else
        printf "    ${RED}✗${RESET} %s ${RED}(failed)${RESET}\n" "$msg"
        return $status
    fi
}

# ==========================================
# START
# ==========================================

print_welcome

# System update
print_section "SYSTEM MAINTENANCE" "🔄"
print_step "Updating system"
if run_with_spinner "Synchronizing and upgrading" sudo pacman -Syu --noconfirm; then
    print_success
else
    print_error
    exit 1
fi

# ==========================================
# OFFICIAL PACKAGES
# ==========================================

print_section "CORE PACKAGES" "📦"

declare -A PKG_GROUPS=(
    ["Build Tools"]="git base-devel github-cli gcc gdb cmake ninja clang"
    ["Languages"]="python python-pip nodejs npm maven gradle jdk21-openjdk rust cargo"
    ["Databases"]="postgresql redis sqlite"
    ["System"]="docker kitty neovim tmux btop fastfetch ripgrep fzf fd bat zoxide eza jq tree curl wget unzip p7zip flatpak"
    ["Desktop"]="firefox telegram-desktop discord vlc mpv obs-studio gwenview okular libreoffice-fresh"
    ["Network"]="nmap wireshark-qt openssh networkmanager"
    ["Wayland/Hyprland"]="waybar hyprpaper dunst wl-clipboard grim slurp xdg-desktop-portal-hyprland"
    ["Audio"]="pipewire wireplumber pavucontrol playerctl"
    ["Filesystem"]="thunar dolphin ark"
    ["Fonts"]="ttf-dejavu ttf-liberation noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono otf-font-awesome"
    ["Bluetooth"]="bluez bluez-utils blueman brightnessctl"
    ["Virtualization"]="qemu-full virt-manager dnsmasq edk2-ovmf linux-headers"
    ["Hardware"]="android-tools ntfs-3g exfatprogs"
    ["Printing"]="cups system-config-printer"
)

total_groups=${#PKG_GROUPS[@]}
current=0

for group in "${!PKG_GROUPS[@]}"; do
    current=$((current + 1))
    printf "\n    ${CYAN}${BOLD}%s${RESET} ${GRAY}(%d/%d)${RESET}\n" "$group" "$current" "$total_groups"
    
    read -ra pkgs <<< "${PKG_GROUPS[$group]}"
    
    for pkg in "${pkgs[@]}"; do
        printf "      ${GRAY}Installing ${WHITE}%s${GRAY}...${RESET}" "$pkg"
        if pacman -Q "$pkg" &>/dev/null; then
            printf "\r      ${YELLOW}${SKIP}${RESET} ${WHITE}%s${GRAY} already installed${RESET}\n" "$pkg"
        else
            if sudo pacman -S --needed --noconfirm "$pkg" >/dev/null 2>&1; then
                printf "\r      ${GREEN}${CHECK}${RESET} ${WHITE}%s${RESET}\n" "$pkg"
            else
                printf "\r      ${RED}✗${RESET} ${WHITE}%s ${RED}failed${RESET}\n" "$pkg"
            fi
        fi
    done
done

# ==========================================
# SERVICES
# ==========================================

print_section "SYSTEM SERVICES" "⚙️"

declare -a SERVICES=(
    "docker:Container runtime"
    "postgresql:Database server"
    "bluetooth:Wireless connectivity"
    "cups:Printing system"
    "libvirtd:Virtualization daemon"
    "NetworkManager:Network connectivity"
)

for svc in "${SERVICES[@]}"; do
    IFS=':' read -r name desc <<< "$svc"
    print_step "Enabling $desc ($name)"
    if sudo systemctl enable --now "$name" >/dev/null 2>&1; then
        print_success
    else
        print_warn
    fi
done

# User groups
print_step "Adding user to docker and libvirt groups"
sudo usermod -aG docker,libvirt "$USER"
print_success

# PostgreSQL init
echo
print_step "Checking PostgreSQL initialization"
if [ ! -f /var/lib/postgres/data/PG_VERSION ]; then
    echo
    if run_with_spinner "Initializing PostgreSQL cluster" sudo -iu postgres initdb -D /var/lib/postgres/data; then
        :
    else
        print_error
    fi
else
    print_skip
fi

# ==========================================
# YAY (AUR HELPER)
# ==========================================

print_section "AUR SETUP" "🔧"

if ! command -v yay &>/dev/null; then
    print_step "Building yay from AUR"
    tmpdir=$(mktemp -d)
    if git clone --depth=1 https://aur.archlinux.org/yay.git "$tmpdir/yay" >/dev/null 2>&1; then
        (
            cd "$tmpdir/yay"
            makepkg -si --noconfirm >/dev/null 2>&1
        )
        rm -rf "$tmpdir"
        print_success
    else
        print_error
    fi
else
    print_skip
fi

# ==========================================
# AUR PACKAGES
# ==========================================

print_section "AUR PACKAGES" "🎁"

declare -a AUR_PKGS=(
    "visual-studio-code-bin:VS Code"
    "google-chrome:Chrome browser"
    "postman-bin:API testing"
    "docker-desktop:Container GUI"
    "jetbrains-toolbox:IDE manager"
    "burpsuite:Security testing"
)

for pkg in "${AUR_PKGS[@]}"; do
    IFS=':' read -r name desc <<< "$pkg"
    printf "    ${GRAY}Installing ${WHITE}%s${GRAY} (${desc})...${RESET}" "$name"
    if yay -S --needed --noconfirm "$name" >/dev/null 2>&1; then
        printf "\r    ${GREEN}${CHECK}${RESET} ${WHITE}%s${RESET}\n" "$name"
    else
        printf "\r    ${YELLOW}${WARN}${RESET} ${WHITE}%s ${GRAY}(skipped or failed)${RESET}\n" "$name"
    fi
done

# ==========================================
# FLATPAK
# ==========================================

print_section "FLATPAK APPLICATIONS" "📲"

print_step "Configuring Flathub repository"
if ! flatpak remotes | grep -q flathub; then
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1
    print_success
else
    print_skip
fi

declare -a FLATPAK_APPS=(
    "cc.arduino.IDE2:Arduino IDE 2"
    "com.portswigger.BurpSuite:Burp Suite"
)

for app in "${FLATPAK_APPS[@]}"; do
    IFS=':' read -r id desc <<< "$app"
    printf "    ${GRAY}Installing ${WHITE}%s${GRAY}...${RESET}" "$desc"
    if flatpak install -y flathub "$id" >/dev/null 2>&1; then
        printf "\r    ${GREEN}${CHECK}${RESET} ${WHITE}%s${RESET}\n" "$desc"
    else
        printf "\r    ${YELLOW}${WARN}${RESET} ${WHITE}%s ${GRAY}(skipped)${RESET}\n" "$desc"
    fi
done

# ==========================================
# NODE TOOLS
# ==========================================

print_section "NODE.JS ECOSYSTEM" "⬢"

print_step "Enabling Corepack"
corepack enable >/dev/null 2>&1
print_success

print_step "Preparing pnpm"
corepack prepare pnpm@latest --activate >/dev/null 2>&1
print_success

# ==========================================
# DONE
# ==========================================

echo
echo -e "${MAGENTA}${BOLD}"
cat << "EOF"
        █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
        █      ✨  SETUP COMPLETE  ✨      █
        █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█
EOF
echo -e "${RESET}"
echo -e "        ${YELLOW}Please reboot or log out${RESET}"
echo -e "        ${GRAY}for group changes to apply${RESET}"
echo
echo -e "  ${GRAY}Quick reference:${RESET}"
echo -e "    ${CYAN}pacman -Qqe${RESET} ${GRAY}(official packages)${RESET}"
echo -e "    ${CYAN}yay -Qqe${RESET} ${GRAY}(AUR packages)${RESET}"
echo -e "    ${CYAN}flatpak list${RESET} ${GRAY}(Flatpak apps)${RESET}"
echo
