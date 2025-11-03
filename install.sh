#!/bin/bash

##############################################
# Dotfiles Installation Script for Arch Linux
# This script installs required packages using pacman
# and copies dotfiles to appropriate locations
##############################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if package is installed
package_installed() {
    pacman -Qi "$1" >/dev/null 2>&1
}

# Function to install package with pacman
install_package() {
    local package="$1"
    if package_installed "$package"; then
        print_status "$package is already installed"
    else
        print_status "Installing $package..."
        if sudo pacman -S --noconfirm "$package"; then
            print_status "$package installed successfully"
        else
            print_error "Failed to install $package"
            return 1
        fi
    fi
}

# Check if pacman is available (should always be on Arch)
check_pacman() {
    if ! command_exists pacman; then
        print_error "pacman is not available. This script is designed for Arch Linux."
        exit 1
    fi
    print_status "pacman is available"
}

# Install yay AUR helper if not present
install_yay() {
    if command_exists yay; then
        print_status "yay is already installed"
        return 0
    fi
    
    print_status "Installing yay AUR helper..."
    
    # Check if git and base-devel are installed
    if ! package_installed git; then
        print_status "Installing git..."
        sudo pacman -S --noconfirm git
    fi
    
    if ! package_installed base-devel; then
        print_status "Installing base-devel..."
        sudo pacman -S --noconfirm base-devel
    fi
    
    # Clone and build yay
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    print_status "Cloning yay repository..."
    if git clone https://aur.archlinux.org/yay.git; then
        cd yay
        print_status "Building and installing yay..."
        if makepkg -si --noconfirm; then
            print_status "yay installed successfully"
            cd "$OLDPWD"
            rm -rf "$temp_dir"
            return 0
        else
            print_error "Failed to build yay"
            cd "$OLDPWD"
            rm -rf "$temp_dir"
            return 1
        fi
    else
        print_error "Failed to clone yay repository"
        cd "$OLDPWD"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Function to install AUR package with yay
install_aur_package() {
    local package="$1"
    if package_installed "$package"; then
        print_status "$package is already installed"
    else
        print_status "Installing AUR package: $package..."
        if yay -S --noconfirm "$package"; then
            print_status "$package installed successfully"
        else
            print_error "Failed to install AUR package: $package"
            return 1
        fi
    fi
}

# Install required packages
install_packages() {
    print_header "Installing Required Packages"
    
    # Core packages
    local packages=(
        "i3-wm"              # Window manager
        "dunst"              # Notification daemon
        "kitty"              # Terminal emulator
        "redshift"           # Blue light filter
        "rofi"               # Application launcher
        "feh"                # Wallpaper setter
        "picom"              # Compositor (commonly used with i3)
        "neovim"             # Text editor
        "git"                # Version control
        "firefox"            # Web browser
        "nemo"               # File manager
        "pulseaudio"         # Sound server (provides pactl)
        "pavucontrol"        # PulseAudio volume control
        "playerctl"          # Media player controller
        "xorg-xset"          # X server settings
        "xss-lock"           # Screen lock manager
        "network-manager-applet"  # Network manager applet (nm-applet)
        "ttf-font-awesome"   # Font awesome icons
        "noto-fonts"         # Noto fonts
        "noto-fonts-emoji"   # Emoji support
        "ttf-liberation"     # Liberation fonts
        "ttf-dejavu"         # DejaVu fonts
    )
    
    # AUR packages
    local aur_packages=(
        "polybar"            # Status bar
        "betterlockscreen"   # Lockscreen with effects
        "ttf-iosevka-nerd"   # Iosevka Nerd Font
    )
    
    # Install core packages with pacman
    print_status "Installing packages from official repositories..."
    for package in "${packages[@]}"; do
        install_package "$package"
    done
    
    # Install yay AUR helper
    print_header "Installing AUR Helper"
    if ! install_yay; then
        print_error "Failed to install yay. Skipping AUR packages."
        print_warning "You can install AUR packages manually later:"
        for package in "${aur_packages[@]}"; do
            echo "  yay -S $package"
        done
    else
        # Install AUR packages
        print_status "Installing AUR packages..."
        for package in "${aur_packages[@]}"; do
            install_aur_package "$package"
        done
    fi
    
    print_status "Package installation completed"
}

# Create necessary directories
create_directories() {
    print_header "Creating Necessary Directories"
    
    local directories=(
        "$HOME/.config"
        "$HOME/.config/i3"
        "$HOME/.config/polybar"
        "$HOME/.config/polybar/scripts"
        "$HOME/.config/polybar/scripts/rofi"
        "$HOME/.config/rofi"
        "$HOME/.config/dunst"
        "$HOME/.config/kitty"
        "$HOME/.config/nvim"
        "$HOME/.config/redshift"
        "$HOME/Pictures/wallpapers"
        "$HOME/.local/share/fonts"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_status "Created directory: $dir"
        else
            print_status "Directory already exists: $dir"
        fi
    done
}

# Copy dotfiles to appropriate locations
copy_dotfiles() {
    print_header "Copying Dotfiles"
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Function to copy files with backup
    copy_with_backup() {
        local src="$1"
        local dest="$2"
        
        if [ -e "$dest" ]; then
            print_warning "Backing up existing $dest to $dest.backup"
            mv "$dest" "$dest.backup"
        fi
        
        if cp -r "$src" "$dest"; then
            print_status "Copied $(basename "$src") to $dest"
        else
            print_error "Failed to copy $(basename "$src") to $dest"
            return 1
        fi
    }
    
    # Copy i3 config
    if [ -f "$script_dir/i3/config" ]; then
        copy_with_backup "$script_dir/i3/config" "$HOME/.config/i3/config"
    fi
    
    # Copy polybar configs
    if [ -d "$script_dir/polybar" ]; then
        for file in "$script_dir/polybar"/*.ini "$script_dir/polybar"/*.sh; do
            if [ -f "$file" ]; then
                copy_with_backup "$file" "$HOME/.config/polybar/$(basename "$file")"
            fi
        done
        
        # Copy polybar scripts
        if [ -d "$script_dir/polybar/scripts" ]; then
            cp -r "$script_dir/polybar/scripts"/* "$HOME/.config/polybar/scripts/"
            print_status "Copied polybar scripts"
            
            # Make shell scripts executable
            find "$HOME/.config/polybar/scripts" -name "*.sh" -exec chmod +x {} \;
            print_status "Made polybar scripts executable"
            
            # Copy rofi themes to main rofi config
            if [ -d "$script_dir/polybar/scripts/rofi" ]; then
                cp "$script_dir/polybar/scripts/rofi"/*.rasi "$HOME/.config/rofi/" 2>/dev/null || true
                print_status "Copied rofi themes to ~/.config/rofi/"
            fi
        fi
    fi
    
    # Copy dunst config
    if [ -f "$script_dir/dunst/dunstrc" ]; then
        copy_with_backup "$script_dir/dunst/dunstrc" "$HOME/.config/dunst/dunstrc"
    fi
    
    # Copy terminator config
    if [ -f "$script_dir/terminator/config" ]; then
        copy_with_backup "$script_dir/terminator/config" "$HOME/.config/terminator/config"
    fi
    
    # Copy kitty config
    if [ -f "$script_dir/kitty/kitty.conf" ]; then
        copy_with_backup "$script_dir/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    fi
    
    # Copy nvim config
    if [ -d "$script_dir/nvim" ]; then
        # Remove existing nvim config if it exists (for clean install)
        if [ -d "$HOME/.config/nvim" ] && [ "$(ls -A $HOME/.config/nvim)" ]; then
            print_warning "Backing up existing nvim config to ~/.config/nvim.backup"
            mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup"
            mkdir -p "$HOME/.config/nvim"
        fi
        
        # Copy all nvim config files
        cp -r "$script_dir/nvim"/* "$HOME/.config/nvim/"
        print_status "Copied nvim configuration"
    fi
    
    # Copy redshift config
    if [ -f "$script_dir/redshift/redshift.conf" ]; then
        copy_with_backup "$script_dir/redshift/redshift.conf" "$HOME/.config/redshift/redshift.conf"
    fi
    
    # Copy wallpapers
    if [ -d "$script_dir/wallpapers" ]; then
        for wallpaper in "$script_dir/wallpapers"/*; do
            if [ -f "$wallpaper" ]; then
                copy_with_backup "$wallpaper" "$HOME/Pictures/wallpapers/$(basename "$wallpaper")"
            fi
        done
    fi
    
    # Copy fonts
    if [ -d "$script_dir/fonts" ]; then
        for font in "$script_dir/fonts"/*; do
            if [ -f "$font" ]; then
                copy_with_backup "$font" "$HOME/.local/share/fonts/$(basename "$font")"
            fi
        done
        
        # Refresh font cache
        if command_exists fc-cache; then
            print_status "Refreshing font cache..."
            fc-cache -fv
        fi
    fi
}

# Set up services
setup_services() {
    print_header "Setting Up Services"
    
    # Enable user services if systemd is available
    if command_exists systemctl; then
        # Enable redshift if installed
        if package_installed redshift; then
            print_status "Enabling redshift service..."
            systemctl --user enable redshift
            systemctl --user start redshift
        fi
    fi
    
    print_status "Service setup completed"
}

# Final setup and recommendations
final_setup() {
    print_header "Final Setup"
    
    print_status "Installation completed successfully!"
    print_warning "Log out and log back in to use i3 window manager"
}

# Main execution
main() {
    print_header "Dotfiles Installation Script"
    
    # Ask for confirmation
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled"
        exit 0
    fi
    
    # Update system first
    print_status "Updating system packages..."
    sudo pacman -Syu --noconfirm
    
    # Check prerequisites
    check_pacman
    
    # Run installation steps
    install_packages
    create_directories
    copy_dotfiles
    setup_services
    final_setup
}

# Run main function
main "$@"
