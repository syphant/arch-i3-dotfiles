#!/bin/bash
# filepath: install.sh

#######################################
# Arch Linux i3WM Post-Install Script #
#######################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}==>${NC} ${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}ERROR:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root or with sudo"
    exit 1
fi

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOME_DIR="$HOME"

#######################################
# Ask if Desktop or Laptop            #
#######################################

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Arch Linux i3WM Post-Install Setup  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Is this a desktop or a laptop?${NC}"
echo "  1) Desktop"
echo "  2) Laptop"
echo ""
read -p "Enter your choice (1 or 2): " SYSTEM_TYPE

case $SYSTEM_TYPE in
    1)
        IS_LAPTOP=false
        print_step "Configuring for Desktop system"
        ;;
    2)
        IS_LAPTOP=true
        print_step "Configuring for Laptop system"
        ;;
    *)
        print_error "Invalid choice. Please run the script again and select 1 or 2."
        exit 1
        ;;
esac

echo ""

#######################################
# Choose Picom Configuration          #
#######################################

echo -e "${YELLOW}Which picom configuration would you like to use?${NC}"
echo "  1) Normal (includes animations, transparency, etc)"
echo "  2) Alternative (lighter, no transparency or animations)"
echo ""
read -p "Enter your choice (1 or 2): " PICOM_CHOICE

case $PICOM_CHOICE in
    1)
        PICOM_CONFIG="picom.conf"
        print_step "Using normal picom configuration with animations and transparency"
        ;;
    2)
        PICOM_CONFIG="picom-alt.conf"
        print_step "Using alternative lightweight picom configuration"
        ;;
    *)
        print_error "Invalid choice. Please run the script again and select 1 or 2."
        exit 1
        ;;
esac

echo ""

#######################################
# Choose GPU Type                     #
#######################################

echo -e "${YELLOW}Which GPU do you have?${NC}"
echo "  1) Intel"
echo "  2) AMD"
echo "  3) NVIDIA"
echo ""
read -p "Enter your choice (1, 2, or 3): " GPU_CHOICE

case $GPU_CHOICE in
    1)
        GPU_TYPE="intel"
        GPU_PACKAGES=("mesa" "lib32-mesa" "vulkan-intel" "lib32-vulkan-intel" "intel-media-driver" "vulkan-icd-loader" "lib32-vulkan-icd-loader")
        print_step "Will install Intel GPU drivers"
        ;;
    2)
        GPU_TYPE="amd"
        GPU_PACKAGES=("mesa" "lib32-mesa" "vulkan-radeon" "lib32-vulkan-radeon" "libva-mesa-driver" "mesa-vdpau" "vulkan-icd-loader" "lib32-vulkan-icd-loader")
        print_step "Will install AMD GPU drivers"
        ;;
    3)
        GPU_TYPE="nvidia"
        echo ""
        echo -e "${YELLOW}Which NVIDIA driver version?${NC}"
        echo "  1) Legacy (nvidia) - For GTX 10 series or older"
        echo "  2) Open (nvidia-open) - For GTX 16 series / RTX 20 series or newer"
        echo ""
        read -p "Enter your choice (1 or 2): " NVIDIA_DRIVER_CHOICE
        
        case $NVIDIA_DRIVER_CHOICE in
            1)
                GPU_PACKAGES=("nvidia-dkms" "nvidia-utils" "lib32-nvidia-utils" "nvidia-settings" "vulkan-icd-loader" "lib32-vulkan-icd-loader")
                print_step "Will install NVIDIA proprietary drivers (legacy)"
                ;;
            2)
                GPU_PACKAGES=("nvidia-open-dkms" "nvidia-utils" "lib32-nvidia-utils" "nvidia-settings" "vulkan-icd-loader" "lib32-vulkan-icd-loader")
                print_step "Will install NVIDIA open kernel module drivers"
                ;;
            *)
                print_error "Invalid choice. Please run the script again and select 1 or 2."
                exit 1
                ;;
        esac
        ;;
    *)
        print_error "Invalid choice. Please run the script again and select 1, 2, or 3."
        exit 1
        ;;
esac

echo ""

#######################################
# Verify NetworkManager               #
#######################################

print_step "Verifying NetworkManager setup..."

# Check if NetworkManager is active
if ! systemctl is-active --quiet NetworkManager; then
    print_error "NetworkManager is not running!"
    echo ""
    echo -e "${YELLOW}This script requires NetworkManager to be installed and running.${NC}"
    echo -e "${BLUE}Please:${NC}"
    echo "  1. Install NetworkManager: sudo pacman -S networkmanager"
    echo "  2. Enable it: sudo systemctl enable NetworkManager"
    echo "  3. Start it: sudo systemctl start NetworkManager"
    echo "  4. If using systemd-networkd, disable it first"
    echo ""
    exit 1
fi

# Check if systemd-networkd is active (conflict warning)
if systemctl is-active --quiet systemd-networkd; then
    print_warning "systemd-networkd is active and may conflict with NetworkManager!"
    echo ""
    echo -e "${YELLOW}It's recommended to disable systemd-networkd:${NC}"
    echo "  sudo systemctl stop systemd-networkd"
    echo "  sudo systemctl disable systemd-networkd"
    echo ""
fi

print_step "NetworkManager is active"

#######################################
# Copy dotfiles to home directory     #
#######################################

print_step "Copying dotfiles to home directory..."

# Copy all files and directories except README.md and install.sh
shopt -s dotglob  # Include hidden files
for item in "$SCRIPT_DIR"/*; do
    basename_item=$(basename "$item")
    
    # Skip README.md, install.sh, and .git directory
    if [[ "$basename_item" == "README.md" ]] || \
       [[ "$basename_item" == "install.sh" ]] || \
       [[ "$basename_item" == ".git" ]] || \
       [[ "$basename_item" == ".gitignore" ]]; then
        continue
    fi
    
    # Backup existing files/directories
    if [ -e "$HOME_DIR/$basename_item" ]; then
        print_warning "Backing up existing $basename_item to ${basename_item}.backup"
        mv "$HOME_DIR/$basename_item" "$HOME_DIR/${basename_item}.backup"
    fi
    
    # Copy the item
    cp -r "$item" "$HOME_DIR/"
    echo "  Copied: $basename_item"
done

print_step "Dotfiles copied successfully!"

# Handle picom configuration choice
if [ "$PICOM_CONFIG" = "picom-alt.conf" ]; then
    print_step "Applying alternative picom configuration..."
    
    PICOM_DIR="$HOME_DIR/.config/picom"
    
    # Backup the normal picom.conf
    if [ -f "$PICOM_DIR/picom.conf" ]; then
        mv "$PICOM_DIR/picom.conf" "$PICOM_DIR/picom.conf.backup"
        echo "  Backed up normal picom.conf to picom.conf.backup"
    fi
    
    # Copy picom-alt.conf as picom.conf
    if [ -f "$PICOM_DIR/picom-alt.conf" ]; then
        cp "$PICOM_DIR/picom-alt.conf" "$PICOM_DIR/picom.conf"
        echo "  Applied alternative picom configuration"
    else
        print_error "picom-alt.conf not found in $PICOM_DIR"
    fi
else
    print_step "Using normal picom configuration (no changes needed)"
fi

# Enable auto-suspend for laptops
if [ "$IS_LAPTOP" = true ]; then
    print_step "Enabling auto-suspend after 5 minutes of inactivity (laptop mode)..."
    
    I3_CONFIG="$HOME_DIR/.config/i3/config"
    
    if [ -f "$I3_CONFIG" ]; then
        # Uncomment the xautolock line
        sed -i 's/^# exec_always --no-startup-id killall xautolock; xautolock -time 5 -locker "systemctl suspend" -detectsleep$/exec_always --no-startup-id killall xautolock; xautolock -time 5 -locker "systemctl suspend" -detectsleep/' "$I3_CONFIG"
        echo "  Auto-suspend enabled in i3 config"
    else
        print_warning "i3 config not found at $I3_CONFIG"
    fi
else
    print_step "Skipping auto-suspend setup (desktop mode)"
fi

#######################################
# Make scripts executable             #
#######################################

print_step "Making scripts executable..."

# Make i3 scripts executable
I3_SCRIPTS_DIR="$HOME_DIR/.config/i3/scripts"

if [ -d "$I3_SCRIPTS_DIR" ]; then
    chmod +x "$I3_SCRIPTS_DIR"/*
    echo "  Made all scripts in $I3_SCRIPTS_DIR executable"
else
    print_warning "i3 scripts directory not found: $I3_SCRIPTS_DIR"
fi

# Make local bin scripts executable
LOCAL_BIN_DIR="$HOME_DIR/.local/bin"

if [ -d "$LOCAL_BIN_DIR" ]; then
    chmod +x "$LOCAL_BIN_DIR"/*
    echo "  Made all scripts in $LOCAL_BIN_DIR executable"
else
    print_warning "Local bin directory not found: $LOCAL_BIN_DIR"
fi

#######################################
# Configure sudo for wheel group      #
#######################################

print_step "Configuring passwordless sudo for wheel group..."

# Check if the NOPASSWD line is already uncommented
if sudo grep -q "^%wheel ALL=(ALL:ALL) NOPASSWD: ALL" /etc/sudoers; then
    echo "  Passwordless sudo already enabled for wheel group"
else
    echo "  Enabling passwordless sudo for wheel group..."
    # Use EDITOR=tee with visudo for safe editing
    echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo -f /etc/sudoers.d/10-wheel-nopasswd
    echo "  Passwordless sudo enabled"
fi

# Clean up any other files in sudoers.d that might conflict
if [ -n "$(sudo ls -A /etc/sudoers.d/ 2>/dev/null | grep -v '^10-wheel-nopasswd$')" ]; then
    echo "  Cleaning up conflicting sudoers.d files..."
    sudo find /etc/sudoers.d/ -type f ! -name '10-wheel-nopasswd' -delete
    echo "  Conflicting files removed"
else
    echo "  No conflicting sudoers.d files found"
fi

#######################################
# Install essential build tools       #
#######################################

print_step "Installing essential build tools..."

sudo pacman -S --needed --noconfirm git wget curl base-devel

print_step "Essential tools installed!"

#######################################
# Optimize mirror list                #
#######################################

print_step "Optimizing package mirror list with reflector..."

# Backup current mirrorlist
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

# Run reflector to get fastest mirrors
print_warning "This may take a few minutes..."
sudo reflector --latest 15 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

print_step "Mirror list optimized!"

#######################################
# Install yay AUR helper              #
#######################################

print_step "Installing yay AUR helper..."

if command -v yay &> /dev/null; then
    print_warning "yay is already installed, skipping..."
else
    # Clone and build yay
    cd /tmp
    rm -rf yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd "$SCRIPT_DIR"
    
    print_step "yay installed successfully!"
fi

#######################################
# Enable multilib repository          #
#######################################

print_step "Enabling multilib repository..."

# Check if multilib is already enabled
if grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo "  multilib repository is already enabled"
else
    # Backup pacman.conf
    sudo cp /etc/pacman.conf /etc/pacman.conf.backup
    
    # Uncomment [multilib] and Include line
    sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ {
        s/^#\[multilib\]/[multilib]/
        s/^#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/
    }' /etc/pacman.conf
    
    echo "  multilib repository enabled"
    
    # Update package database
    sudo pacman -Sy
    echo "  Package database updated"
fi

#######################################
# Install all dependencies            #
#######################################

print_step "Installing dependencies..."

# Base packages for all systems
OFFICIAL_PACKAGES=(
    zsh
    dkms
    xorg-server
    xorg-xinit
    xorg-xinput
    i3-wm
    polybar
    xss-lock
    ttf-jetbrains-mono-nerd
    inter-font
    nano-syntax-highlighting
    picom
    dmenu
    rofi
    feh
    maim
    xclip
    brightnessctl
    kitty
    firefox
    flatpak
    xdg-desktop-portal
    btop
    lxqt-policykit
    networkmanager
    network-manager-applet
    wpa_supplicant
    thunar
    pipewire
    wireplumber
    pipewire-pulse
    ffmpeg
    mkvtoolnix-cli
    papirus-icon-theme
    nwg-look
    sassc
    gtk-engine-murrine
    gtk-engines
    gnome-themes-extra
    xdotool
    bluez
    bluez-utils
    blueman
    reflector
    dunst
    fastfetch
    wine-staging
    wine-mono
    winetricks
    steam
)

# Add laptop-specific packages
if [ "$IS_LAPTOP" = true ]; then
    OFFICIAL_PACKAGES+=(
        tlp
        tlp-rdw
        powertop
        thermald
    )
fi

# Add GPU-specific packages
OFFICIAL_PACKAGES+=("${GPU_PACKAGES[@]}")

# Detect and add appropriate kernel headers
print_step "Detecting kernel version..."
KERNEL_VERSION=$(uname -r)

if [[ "$KERNEL_VERSION" == *"-lts"* ]]; then
    KERNEL_HEADERS="linux-lts-headers"
    echo "  Detected linux-lts kernel"
elif [[ "$KERNEL_VERSION" == *"-zen"* ]]; then
    KERNEL_HEADERS="linux-zen-headers"
    echo "  Detected linux-zen kernel"
elif [[ "$KERNEL_VERSION" == *"-hardened"* ]]; then
    KERNEL_HEADERS="linux-hardened-headers"
    echo "  Detected linux-hardened kernel"
else
    KERNEL_HEADERS="linux-headers"
    echo "  Detected standard linux kernel"
fi

OFFICIAL_PACKAGES+=("$KERNEL_HEADERS")
echo "  Will install: $KERNEL_HEADERS"

AUR_PACKAGES=(
    ttf-gohu-nerd
    ttf-0xproto-nerd
    i3lock-color
    visual-studio-code-bin
    xautolock
)

# Install official packages
print_step "Installing packages from official repositories..."
sudo pacman -S --needed --noconfirm "${OFFICIAL_PACKAGES[@]}"

# Install AUR packages
print_step "Installing AUR packages..."
yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"

print_step "All dependencies installed successfully!"

#######################################
# Create touchpad configuration       #
#######################################

if [ "$IS_LAPTOP" = true ]; then
    print_step "Creating touchpad configuration..."

    sudo mkdir -p /etc/X11/xorg.conf.d

    sudo tee /etc/X11/xorg.conf.d/30-touchpad.conf > /dev/null <<'EOF'
Section "InputClass"
    Identifier "touchpad"
    Driver "libinput"
    MatchIsTouchpad "on"
    Option "Tapping" "on"
    Option "TappingButtonMap" "lrm"
    Option "NaturalScrolling" "false"
    Option "AccelProfile" "adaptive"
    Option "AccelSpeed" "0"
EndSection
EOF

    print_step "Touchpad configuration created!"
else
    print_step "Skipping touchpad configuration (Desktop system)"
fi

#######################################
# Configure systemd-logind            #
#######################################

print_step "Configuring systemd-logind..."

# Check if power management settings are already configured
if ! grep -q "Power management settings added by install script" /etc/systemd/logind.conf; then
    # Backup original logind.conf if not already backed up
    if [ ! -f /etc/systemd/logind.conf.backup ]; then
        sudo cp /etc/systemd/logind.conf /etc/systemd/logind.conf.backup
    fi
    
    # Add power management settings
    sudo tee -a /etc/systemd/logind.conf > /dev/null <<'EOF'

# Power management settings added by install script
HandlePowerKey=suspend
HandlePowerKeyLongPress=poweroff
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=suspend
HandleLidSwitchDocked=suspend
EOF
    
    print_step "systemd-logind configured!"
else
    print_step "systemd-logind already configured, skipping..."
fi

#######################################
# Configure Bluetooth                 #
#######################################

print_step "Configuring Bluetooth..."

# Enable and start bluetooth service
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

# Enable bluetooth to auto-power on
sudo sed -i 's/#AutoEnable=false/AutoEnable=true/' /etc/bluetooth/main.conf 2>/dev/null || true

print_step "Bluetooth configured and enabled!"

#######################################
# Configure power management          #
#######################################

if [ "$IS_LAPTOP" = true ]; then
    print_step "Configuring laptop power management..."

    # Enable and start TLP
    sudo systemctl enable tlp
    sudo systemctl start tlp

    # Enable NetworkManager-dispatcher for tlp-rdw (Radio Device Wizard)
    sudo systemctl enable NetworkManager-dispatcher.service

    # Mask systemd-rfkill services (conflicts with TLP)
    sudo systemctl mask systemd-rfkill.service
    sudo systemctl mask systemd-rfkill.socket

    # Enable thermald for CPU thermal management
    sudo systemctl enable thermald
    sudo systemctl start thermald

    # Create powertop auto-tune service
    sudo tee /etc/systemd/system/powertop.service > /dev/null <<'EOF'
[Unit]
Description=Powertop tunings

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/powertop --auto-tune

[Install]
WantedBy=multi-user.target sleep.target
EOF

    # Enable powertop auto-tune
    sudo systemctl enable powertop

    print_step "Power management configured!"

    # Configure TLP for better battery life
    print_step "Optimizing TLP configuration..."

    sudo tee /etc/tlp.d/00-custom.conf > /dev/null <<'EOF'
# Custom TLP Configuration for Laptop

# CPU Performance/Power Management
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power
CPU_MIN_PERF_ON_AC=0
CPU_MAX_PERF_ON_AC=100
CPU_MIN_PERF_ON_BAT=0
CPU_MAX_PERF_ON_BAT=50
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0

# Platform Power Management
PLATFORM_PROFILE_ON_AC=performance
PLATFORM_PROFILE_ON_BAT=low-power

# Graphics (safe for Intel/AMD/NVIDIA - will be ignored if not applicable)
RADEON_DPM_PERF_LEVEL_ON_AC=auto
RADEON_DPM_PERF_LEVEL_ON_BAT=low
RADEON_DPM_STATE_ON_AC=performance
RADEON_DPM_STATE_ON_BAT=battery

# Disk Settings (will auto-detect available disks)
DISK_APM_LEVEL_ON_AC="254 254"
DISK_APM_LEVEL_ON_BAT="128 128"

# PCI Express Power Management
PCIE_ASPM_ON_AC=default
PCIE_ASPM_ON_BAT=powersupersave

# Runtime Power Management
RUNTIME_PM_ON_AC=on
RUNTIME_PM_ON_BAT=auto

# USB Power Management
USB_AUTOSUSPEND=1
USB_BLACKLIST_BTUSB=0
USB_BLACKLIST_PHONE=0
USB_BLACKLIST_PRINTER=1
USB_BLACKLIST_WWAN=0

# Battery Care (only works on ThinkPad, Dell, Asus with battery care support)
# Uncomment and adjust if your laptop supports battery charge thresholds
#START_CHARGE_THRESH_BAT0=75
#STOP_CHARGE_THRESH_BAT0=80

# Wi-Fi Power Saving
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# Sound Power Saving
SOUND_POWER_SAVE_ON_AC=0
SOUND_POWER_SAVE_ON_BAT=1
SOUND_POWER_SAVE_CONTROLLER=Y

# Disable Wake-on-LAN
WOL_DISABLE=Y

# Restore radio device state on startup
RESTORE_DEVICE_STATE_ON_STARTUP=0
EOF

    print_step "TLP configuration optimized for battery life!"
else
    print_step "Skipping power management configuration (Desktop system)"
fi

#######################################
# Install Proton-GE                   #
#######################################

print_step "Installing latest Proton-GE..."

# Create compatibilitytools.d directory
mkdir -p "$HOME_DIR/.steam/steam/compatibilitytools.d"

# Get the latest Proton-GE release URL
print_warning "Fetching latest Proton-GE release information..."
PROTON_GE_URL=$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep "browser_download_url.*tar.gz" | cut -d '"' -f 4)
PROTON_GE_FILE=$(basename "$PROTON_GE_URL")

if [ -z "$PROTON_GE_URL" ]; then
    print_error "Failed to fetch Proton-GE download URL"
else
    echo "  Latest version: $PROTON_GE_FILE"
    
    # Download Proton-GE
    cd /tmp
    print_warning "Downloading Proton-GE (this may take a few minutes)..."
    wget -q --show-progress "$PROTON_GE_URL"
    
    # Extract to compatibilitytools.d
    print_step "Extracting Proton-GE..."
    tar -xf "$PROTON_GE_FILE" -C "$HOME_DIR/.steam/steam/compatibilitytools.d/"
    
    # Clean up
    rm "$PROTON_GE_FILE"
    cd "$SCRIPT_DIR"
    
    print_step "Proton-GE installed successfully!"
    echo "  You can select it in Steam under Settings > Compatibility"
fi

#######################################
# Install Dracula GTK Theme           #
#######################################

print_step "Installing Dracula GTK theme..."

# Create themes directory
mkdir -p "$HOME_DIR/.themes"

# Clone and install Dracula theme
cd /tmp
rm -rf gtk
git clone https://github.com/dracula/gtk.git

if [ ! -d "gtk" ]; then
    print_error "Failed to clone Dracula GTK theme repository"
    cd "$SCRIPT_DIR"
else
    cp -r gtk "$HOME_DIR/.themes/Dracula"
    print_step "Dracula GTK theme installed!"
    
    #######################################
    # Install Dracula Qt/Kvantum Theme    #
    #######################################
    
    print_step "Installing Dracula Qt/Kvantum theme..."
    
    # Install kvantum and qt configuration tools
    yay -S --needed --noconfirm kvantum kvantum-qt5 qt5ct qt6ct
    
    # Create Kvantum themes directory
    mkdir -p "$HOME_DIR/.config/Kvantum"
    
    # Copy Kvantum theme from the cloned gtk repo
    if [ -d "gtk/kde/kvantum/Dracula" ]; then
        cp -r gtk/kde/kvantum/Dracula "$HOME_DIR/.config/Kvantum/"
        print_step "Dracula Kvantum theme installed!"
    else
        print_error "Dracula Kvantum theme not found in repository"
    fi
    
    # Clean up
    cd "$SCRIPT_DIR"
    rm -rf /tmp/gtk
fi

#######################################
# Install Dracula Icons               #
#######################################

print_step "Installing Dracula icon theme..."

# Create icons directory
mkdir -p "$HOME_DIR/.local/share/icons"

# Clone and install Dracula icons
cd /tmp
rm -rf dracula-icons
git clone https://github.com/m4thewz/dracula-icons.git

if [ ! -d "dracula-icons/Dracula" ]; then
    print_error "Failed to clone Dracula icons repository"
else
    cp -r dracula-icons/Dracula "$HOME_DIR/.local/share/icons/"
    print_step "Dracula icon theme installed!"
fi

cd "$SCRIPT_DIR"
rm -rf /tmp/dracula-icons

#######################################
# Configure GTK Theme                 #
#######################################

print_step "Configuring GTK theme..."

# Create necessary directories
mkdir -p "$HOME_DIR/.config/gtk-3.0"
mkdir -p "$HOME_DIR/.config/gtk-4.0"

# Configure GTK3
tee "$HOME_DIR/.config/gtk-3.0/settings.ini" > /dev/null <<'EOF'
[Settings]
gtk-theme-name=Dracula
gtk-icon-theme-name=Dracula
gtk-font-name=0xProto Nerd Font Propo 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
EOF

# Configure GTK4
tee "$HOME_DIR/.config/gtk-4.0/settings.ini" > /dev/null <<'EOF'
[Settings]
gtk-theme-name=Dracula
gtk-icon-theme-name=Dracula
gtk-font-name=0xProto Nerd Font Propo 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
EOF

print_step "GTK theme configured!"

#######################################
# Configure Qt Theme                  #
#######################################

print_step "Configuring Qt theme..."

# Create necessary directories
mkdir -p "$HOME_DIR/.config/qt5ct"
mkdir -p "$HOME_DIR/.config/qt6ct"

# Configure Qt5ct
tee "$HOME_DIR/.config/qt5ct/qt5ct.conf" > /dev/null <<'EOF'
[Appearance]
color_scheme_path=
custom_palette=false
icon_theme=Dracula
standard_dialogs=default
style=kvantum-dark

[Fonts]
fixed="0xProto Nerd Font Propo,10,-1,5,50,0,0,0,0,0"
general="0xProto Nerd Font Propo,10,-1,5,50,0,0,0,0,0"

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3

[SettingsWindow]
geometry=@ByteArray()
EOF

# Configure Qt6ct
tee "$HOME_DIR/.config/qt6ct/qt6ct.conf" > /dev/null <<'EOF'
[Appearance]
color_scheme_path=
custom_palette=false
icon_theme=Dracula
standard_dialogs=default
style=kvantum-dark

[Fonts]
fixed="0xProto Nerd Font Propo,10,-1,5,50,0,0,0,0,0"
general="0xProto Nerd Font Propo,10,-1,5,50,0,0,0,0,0"

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3

[SettingsWindow]
geometry=@ByteArray()
EOF

# Configure Kvantum theme
tee "$HOME_DIR/.config/Kvantum/kvantum.kvconfig" > /dev/null <<'EOF'
[General]
theme=Dracula
EOF

# Set environment variables for Qt theme
if ! grep -q "QT_QPA_PLATFORMTHEME" "$HOME_DIR/.profile" 2>/dev/null; then
    echo 'export QT_QPA_PLATFORMTHEME=qt5ct' >> "$HOME_DIR/.profile"
fi

if ! grep -q "QT_QPA_PLATFORMTHEME" "$HOME_DIR/.zprofile" 2>/dev/null; then
    echo 'export QT_QPA_PLATFORMTHEME=qt5ct' >> "$HOME_DIR/.zprofile"
fi

print_step "Qt theme configured!"

#######################################
# Create Screenshots directory        #
#######################################

print_step "Creating Screenshots directory..."
mkdir -p "$HOME_DIR/Screenshots"

#######################################
# Set zsh as default shell            #
#######################################

print_step "Setting zsh as default shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
    print_step "Default shell changed to zsh"
else
    print_warning "zsh is already the default shell"
fi

#######################################
# INSTALLATION COMPLETE               #
#######################################

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Installation completed successfully!  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review the copied configuration files in your home directory"
echo "2. Add wallpapers to ~/backgrounds/ directory"
echo "3. Reboot your system to apply all changes"
echo ""
echo -e "${BLUE}Installed features:${NC}"
echo "✓ NetworkManager for network management"
echo "✓ Bluetooth support (blueman applet)"
echo "✓ ${GPU_TYPE^^} GPU drivers installed"

if [ "$IS_LAPTOP" = true ]; then
    echo "✓ TLP for battery optimization"
    echo "✓ Thermald for CPU thermal management"
    echo "✓ Powertop auto-tuning on boot"
    echo "✓ Touchpad tap-to-click configuration"
fi

echo "✓ Optimized mirror list with reflector"
echo ""

if [ "$IS_LAPTOP" = true ]; then
    echo -e "${BLUE}Power Management Tips:${NC}"
    echo "- Check TLP status: 'sudo tlp-stat -s'"
    echo "- Check power consumption: 'sudo powertop'"
    echo ""
fi

# Ask to reboot
read -p "Would you like to reboot now? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    print_step "Please reboot manually when ready"
else
    print_step "Rebooting system..."
    sudo reboot
fi
