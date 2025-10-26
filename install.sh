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
# 0. Ask if Desktop or Laptop         #
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
# 1. Copy dotfiles to home directory  #
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

#######################################
# 2. Install essential build tools    #
#######################################

print_step "Installing essential build tools..."

sudo pacman -S --needed --noconfirm git wget curl base-devel

print_step "Essential tools installed!"

#######################################
# 3. Install yay AUR helper           #
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
# 4. Install all dependencies         #
#######################################

print_step "Installing dependencies..."

# Base packages for all systems
OFFICIAL_PACKAGES=(
    zsh
    i3-wm
    polybar
    xss-lock
    ttf-jetbrains-mono-nerd
    nano-syntax-highlighting
    picom
    dmenu
    rofi
    feh
    maim
    brightnessctl
    kitty
    firefox
    lxqt-policykit
    networkmanager
    network-manager-applet
    wpa_supplicant
    thunar
    pipewire
    wireplumber
    pipewire-pulse
    papirus-icon-theme
    sassc
    gtk-engine-murrine
    gtk-engines
    gnome-themes-extra
    xdotool
    xclip
    bluez
    bluez-utils
    blueman
    reflector
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
# 5. Optimize mirror list             #
#######################################

print_step "Optimizing package mirror list with reflector..."

# Backup current mirrorlist
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

# Run reflector to get fastest mirrors
print_warning "This may take a few minutes..."
sudo reflector --latest 15 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

print_step "Mirror list optimized!"

#######################################
# 6. Switch from networkd to NM       #
#######################################

print_step "Configuring NetworkManager..."

# Check if systemd-networkd is active
if systemctl is-active --quiet systemd-networkd; then
    print_warning "systemd-networkd is currently active. Switching to NetworkManager..."
    
    # Stop and disable systemd-networkd and systemd-resolved
    sudo systemctl stop systemd-networkd
    sudo systemctl disable systemd-networkd
    
    if systemctl is-active --quiet systemd-resolved; then
        sudo systemctl stop systemd-resolved
        sudo systemctl disable systemd-resolved
    fi
    
    # Remove symlink if it exists and create new resolv.conf
    sudo rm -f /etc/resolv.conf
    
    # Create a basic resolv.conf that NetworkManager will manage
    sudo tee /etc/resolv.conf > /dev/null <<'EOF'
# Generated by NetworkManager
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
    
    print_step "Switched from systemd-networkd to NetworkManager"
else
    print_warning "systemd-networkd is not active, proceeding with NetworkManager setup..."
fi

# Enable and start NetworkManager
print_step "Enabling and starting NetworkManager..."
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

# Ensure wpa_supplicant is enabled (for WiFi)
sudo systemctl enable wpa_supplicant

print_step "NetworkManager configured and started!"

# Wait for network to come back up
print_warning "Waiting for network connection to stabilize..."
sleep 5

# Check if we have internet connectivity
if ping -c 1 1.1.1.1 &> /dev/null; then
    print_step "Network connection verified!"
else
    print_warning "No network connection detected. You may need to configure your network connection."
    echo ""
    echo -e "${YELLOW}Opening nmtui to configure network connection...${NC}"
    echo -e "${BLUE}Instructions:${NC}"
    echo "  1. Select 'Activate a connection' or 'Edit a connection'"
    echo "  2. Configure your WiFi or Ethernet connection"
    echo "  3. Exit nmtui when done (ESC key)"
    echo ""
    read -p "Press ENTER to launch nmtui..." 
    
    # Launch nmtui for user to configure network
    sudo nmtui
    
    # Wait a moment for connection to establish
    print_warning "Waiting for connection to establish..."
    sleep 5
    
    # Check connectivity again
    if ping -c 1 1.1.1.1 &> /dev/null; then
        print_step "Network connection verified!"
    else
        print_error "Still no network connection detected."
        echo ""
        echo -e "${YELLOW}You can try:${NC}"
        echo "  1. Run 'sudo nmtui' to configure network manually"
        echo "  2. Connect via ethernet cable"
        echo "  3. Run this script again after connecting"
        echo ""
        read -p "Do you want to try configuring network again? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo nmtui
            sleep 5
            if ping -c 1 1.1.1.1 &> /dev/null; then
                print_step "Network connection verified!"
            else
                print_error "Network connection failed. Please configure network and run script again."
                exit 1
            fi
        else
            print_error "Cannot continue without network connection. Exiting."
            exit 1
        fi
    fi
fi

#######################################
# 7. Create touchpad configuration    #
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
    Option "TappingButtonMap" "lmr"
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
# 8. Configure systemd-logind         #
#######################################

print_step "Configuring systemd-logind..."

# Backup original logind.conf
sudo cp /etc/systemd/logind.conf /etc/systemd/logind.conf.backup

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

#######################################
# 9. Configure Bluetooth              #
#######################################

print_step "Configuring Bluetooth..."

# Enable and start bluetooth service
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

# Enable bluetooth to auto-power on
sudo sed -i 's/#AutoEnable=false/AutoEnable=true/' /etc/bluetooth/main.conf 2>/dev/null || true

print_step "Bluetooth configured and enabled!"

#######################################
# 10. Configure power management      #
#######################################

if [ "$IS_LAPTOP" = true ]; then
    print_step "Configuring laptop power management..."

    # Enable and start TLP
    sudo systemctl enable tlp
    sudo systemctl start tlp

    # Enable TLP sleep hooks
    sudo systemctl enable tlp-sleep

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
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/powertop --auto-tune

[Install]
WantedBy=multi-user.target
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

# Graphics
RADEON_DPM_PERF_LEVEL_ON_AC=auto
RADEON_DPM_PERF_LEVEL_ON_BAT=low
RADEON_DPM_STATE_ON_AC=performance
RADEON_DPM_STATE_ON_BAT=battery
RADEON_POWER_PROFILE_ON_AC=default
RADEON_POWER_PROFILE_ON_BAT=low

# Disk Settings
DISK_DEVICES="nvme0n1 sda"
DISK_APM_LEVEL_ON_AC="254 254"
DISK_APM_LEVEL_ON_BAT="128 128"
DISK_IOSCHED="mq-deadline mq-deadline"

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

# Battery Care (for laptops with battery care support)
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80
START_CHARGE_THRESH_BAT1=75
STOP_CHARGE_THRESH_BAT1=80

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
# 11. Install GTK themes              #
#######################################

print_step "Installing Colloid GTK theme..."

cd /tmp
rm -rf Colloid-gtk-theme
git clone https://github.com/vinceliuice/Colloid-gtk-theme.git
cd Colloid-gtk-theme
./install.sh -t all -s compact -l --tweaks rimless black normal
cd "$SCRIPT_DIR"

print_step "Colloid GTK theme installed!"

#######################################
# 12. Install KDE/Kvantum themes      #
#######################################

print_step "Installing Colloid KDE/Kvantum theme..."

# Install kvantum first
yay -S --needed --noconfirm kvantum qt5ct qt6ct

cd /tmp
rm -rf Colloid-kde
git clone https://github.com/vinceliuice/Colloid-kde.git
cd Colloid-kde
./install.sh

# Install Kvantum themes
cd "$SCRIPT_DIR"

print_step "Colloid KDE/Kvantum theme installed!"

#######################################
# 13. Configure themes                #
#######################################

print_step "Configuring themes..."

# Create necessary directories
mkdir -p "$HOME_DIR/.config/gtk-3.0"
mkdir -p "$HOME_DIR/.config/gtk-4.0"
mkdir -p "$HOME_DIR/.config/qt5ct"
mkdir -p "$HOME_DIR/.config/qt6ct"
mkdir -p "$HOME_DIR/.config/Kvantum"

# Configure GTK3
tee "$HOME_DIR/.config/gtk-3.0/settings.ini" > /dev/null <<'EOF'
[Settings]
gtk-theme-name=Colloid-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Sans 10
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
cp "$HOME_DIR/.config/gtk-3.0/settings.ini" "$HOME_DIR/.config/gtk-4.0/settings.ini"

# Configure Qt5ct
tee "$HOME_DIR/.config/qt5ct/qt5ct.conf" > /dev/null <<'EOF'
[Appearance]
color_scheme_path=/usr/share/qt5ct/colors/darker.conf
custom_palette=false
icon_theme=Papirus-Dark
standard_dialogs=default
style=kvantum

[Fonts]
fixed=@Variant(\0\0\0@\0\0\0\x12\0M\0o\0n\0o\0s\0p\0\x61\0\x63\0\x65@$\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)
general=@Variant(\0\0\0@\0\0\0\x12\0S\0\x61\0n\0s\0 \0S\0\x65\0r\0i\0\x66@$\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)

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
color_scheme_path=/usr/share/qt6ct/colors/darker.conf
custom_palette=false
icon_theme=Papirus-Dark
standard_dialogs=default
style=kvantum

[Fonts]
fixed=@Variant(\0\0\0@\0\0\0\x12\0M\0o\0n\0o\0s\0p\0\x61\0\x63\0\x65@$\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)
general=@Variant(\0\0\0@\0\0\0\x12\0S\0\x61\0n\0s\0 \0S\0\x65\0r\0i\0\x66@$\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)

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
theme=ColloidDark
EOF

# Set environment variables
if ! grep -q "QT_QPA_PLATFORMTHEME" "$HOME_DIR/.profile" 2>/dev/null; then
    echo 'export QT_QPA_PLATFORMTHEME=qt5ct' >> "$HOME_DIR/.profile"
fi

if ! grep -q "QT_QPA_PLATFORMTHEME" "$HOME_DIR/.zprofile" 2>/dev/null; then
    echo 'export QT_QPA_PLATFORMTHEME=qt5ct' >> "$HOME_DIR/.zprofile"
fi

print_step "Themes configured successfully!"

#######################################
# 14. Create Screenshots directory    #
#######################################

print_step "Creating Screenshots directory..."
mkdir -p "$HOME_DIR/Screenshots"

#######################################
# 15. Create backgrounds directory    #
#######################################

print_step "Creating backgrounds directory..."
mkdir -p "$HOME_DIR/backgrounds"
print_warning "Don't forget to add wallpapers to ~/backgrounds/ directory"

#######################################
# 16. Set zsh as default shell        #
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
read -p "Would you like to reboot now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "Rebooting system..."
    sudo reboot
else
    print_step "Please reboot manually when ready"
fi
