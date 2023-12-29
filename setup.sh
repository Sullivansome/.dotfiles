#!/bin/bash

# Store OS information
os="$(uname)"
distro=""

# Check and store Linux distribution information
if [[ "$os" == "Linux" ]] && [[ -f "/etc/os-release" ]]; then
    distro=$(awk -F= '$1=="ID" { print $2 }' /etc/os-release)
fi

# HEADER
header() {
    echo -e "###############################################################"
    echo -e "########## \e[93mWELCOME TO THE SYSTEM SETUP SCRIPT\e[0m #############"
    echo -e "###############################################################"
    echo
}

# FOOTER
footer() {
    echo
    echo -e "###############################################################"
    echo -e "#############\e[0m \e[93mTHANK YOU FOR USING THE SCRIPT\e[0m ##############"
    echo -e "###############################################################"
}

# SAMPLE SPINNER
spinner() {
    local pid=$!
    local delay=0.75
    local spinstr='|/-\\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function for Menu
menu() {
    header
    echo "Choose an action:"
    echo "1) Update package lists and upgrade. Install essential packages"
    echo "2) Pull dotfiles from Github and apply changes"
    echo "3) Install oh-my-zsh"
    echo "4) Customize oh-my-zsh"
    echo "5) Install SDKMAN"
    echo "0) Exit"
}

function check_or_install_homebrew() {
    # Ensure brew is installed
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is not installed. Installing now..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

function install_aur_helper() {
    echo "Installing AUR Helper..."

    # Check if yay is already installed
    if ! command -v yay &> /dev/null; then
        echo "Installing yay as the AUR helper..."
        sudo pacman -S --needed git base-devel
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si
        cd ..
        rm -rf yay
    else
        echo "yay is already installed."
    fi
}

# Function to update packages
function update_packages() {
    echo -e "\e[33mUpdating package lists and updating...\e[0m"

    if [[ "$os" == "Linux" ]]; then
        case $distro in
            "ubuntu"|"debian")
                sudo apt update || { echo "Failed to update packages. Exiting."; exit 1; }
                ;;
            "arch")
                sudo pacman -Syu || { echo "Failed to update packages. Exiting."; exit 1; }
                ;;
            *)
                echo -e "\e[31mUnsupported distribution detected. Exiting.\e[0m"
                exit 1
                ;;
        esac
    elif [[ "$os" == "Darwin" ]]; then
        check_or_install_homebrew
        brew update || { echo "Failed to update packages. Exiting."; exit 1; }
    else
        echo -e "\e[31mUnsupported OS detected. Exiting.\e[0m"
        exit 1
    fi
}

# Function to install essential packages
function install_essentials() {
    local linux_packages="curl wget jq git vim tree zsh zip unzip"
    local arch_packages="bat alacritty hyprland rofi waybar obsidian noto-fonts-cjk"
    local darwin_packages="curl wget jq git vim tree zsh zip unzip bat"

    if [[ "$os" == "Linux" ]]; then
        echo -e "\e[33mInstalling $linux_packages...\e[0m"
        check_or_install_homebrew
        case $distro in
            "ubuntu"|"debian")
                sudo apt install -y $linux_packages || { echo -e "\e[31mFailed to install required packages using apt. Exiting.\e[0m"; exit 1; }
                sudo apt install -y build-essential || { echo -e "\e[31mFailed to install build-essential package using apt. Exiting.\e[0m"; exit 1; }
                ;;
            "arch")
                sudo pacman -S --noconfirm $linux_packages || { echo -e "\e[31mFailed to install required packages using pacman. Exiting.\e[0m"; exit 1; }
                sudo pacman -S --noconfirm $arch_packages || { echo -e "\e[31mFailed to install required packages using pacman. Exiting.\e[0m"; exit 1; }
                sudo pacman -S --nonconfirm base-devel || { echo -e "\e[31mFailed to install base-devel package using pacman. Exiting.\e[0m"; exit 1; }
                install_aur_packages
                ;;
            *)
                echo -e "\e[31mUnsupported distribution detected. Exiting.\e[0m"
                exit 1
                ;;
        esac
    elif [[ "$os" == "Darwin" ]]; then
        echo -e "\e[33mInstalling $darwin_packages...\e[0m"
        for package in $darwin_packages; do
            brew install $package || { echo -e "\e[31mFailed to install $package. Exiting.\e[0m"; exit 1; }
        done
    else
        echo -e "\e[31mUnsupported OS detected. Exiting.\e[0m"
        exit 1
    fi

    echo -e "\e[32mInstallation complete!\e[0m"
}


# Function to install specific AUR packages
function install_aur_packages() {
    install_aur_helper
    local aur_packages="google-chrome visual-studio-code-bin spotify xmind"
    # Install packages from the AUR
    echo -e "\e[33mInstalling $aur_packages...\e[0m"
    for package in $aur_packages; do
        yay -S --noconfirm $package || { echo -e "\e[31mFailed to install $package. Exiting.\e[0m"; exit 1; }
    done
}

function setup_dotfiles() {
    set -e  # stop the script if any command returns a non-zero exit code

    # Pull dotfiles from Github and apply changes
    echo -e "\e[33mPulling dotfiles from Github...\e[0m"

    # Variables
    REPO_URL="https://github.com/Sullivansome/.dotfiles.git"
    DEST_DIR="$HOME/.dotfiles"

    # Prompt user for repo URL
    echo -n "Enter your .dotfiles repo URL, REMEMBER TO COPY THE SETUP.SH TO YOUR REPO[default: $REPO_URL]: "
    read user_input

    # If user_input is not empty, update REPO_URL
    if [[ ! -z "$user_input" ]]; then
        REPO_URL="$user_input"
    fi

    echo "Using repository: $REPO_URL"

    # Check if git is installed
    if ! command -v git &> /dev/null; then
        echo "\e[31mError: git is not installed. Please install git and try again.\e[0m"
        return 1
    fi

    cd  # Move to the home directory

    if [ -d "$DEST_DIR" ]; then
        echo -e "\e[33mBacking up dotfiles...\e[0m"
        backup_dir="$HOME/.dotfiles_backup"
        # Ensure the backup directory exists
        mkdir -p "$backup_dir"

        # Backup .zshrc
        if [ -f ~/.zshrc ]; then
            backup_file="$backup_dir/.zshrc.backup_$(date +%Y%m%d_%H%M%S)"
            mv ~/.zshrc $backup_file
            echo "Backed up existing .zshrc to $backup_file"
        fi
        # Backup and .gitconfig
        if [ -f ~/.gitconfig ]; then
            backup_file="$backup_dir/.gitconfig.backup_$(date +%Y%m%d_%H%M%S)"
            mv ~/.gitconfig $backup_file
            echo "Backed up existing .gitconfig to $backup_file"
        fi
        rm -rf "$DEST_DIR"
    fi

    # Clone the repo
    echo -e "\e[33mCloning the dotfiles repository...\e[0m"
    mkdir -p "$DEST_DIR"
    git clone "$REPO_URL" "$DEST_DIR"

    # System links
    echo "Creating symbolic links..."

    [[ -L ~/.zshrc ]] && rm ~/.zshrc
    if [[ "$os" == "Linux" ]]; then
        ln -s ~/.dotfiles/.zshrclinux ~/.zshrc
    elif [[ "$os" == "Darwin" ]]; then
        ln -s ~/.dotfiles/.zshrcdarwin ~/.zshrc
    fi

    [[ -L ~/.gitconfig ]] && rm ~/.gitconfig
    ln -s ~/.dotfiles/.gitconfig ~/.gitconfig

    [[ -L ~/.p10k.zsh ]] && rm ~/.p10k.zsh
    ln -s ~/.dotfiles/.p10k.zsh ~/.p10k.zsh

    local hypr_dir="$HOME/.config/hypr"
    mkdir -p "$hypr_dir"

    local alacritty_dir="$HOME/.config/alacritty"
    mkdir -p "$alacritty_dir"

    local rofi_dir="$HOME/.config/rofi"
    mkdir -p "$rofi_dir"

    local waybar_dir="$HOME/.config/waybar"
    mkdir -p "$waybar_dir"

    [[ -L ~/.config/hypr/hyprland.conf ]] && rm ~/.config/hypr/hyprland.conf
    ln -s ~/.dotfiles/.config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf

    [[ -L ~/.config/hypr/hyprpapaer.conf ]] && rm ~/.config/hypr/hyprpapaer.conf
    ln -s ~/.dotfiles/.config/hypr/hyprpapaer.conf ~/.config/hypr/hyprpapaer.conf

    [[ -L ~/.config/alacritty/alacritty.yml ]] && rm ~/.config/alacritty/alacritty.yml
    ln -s ~/.dotfiles/.config/alacritty/alacritty.yml ~/.config/alacritty/alacritty.yml

    [[ -L ~/.config/rofi/config.rasi ]] && rm ~/.config/rofi/config.rasi
    ln -s ~/.dotfiles/.config/rofi/config.rasi ~/.config/rofi/config.rasi

    [[ -L ~/.config/waybar/config.jsonc ]] && rm ~/.config/waybar/config.jsonc
    ln -s ~/.dotfiles/.config/waybar/config ~/.config/waybar/config.jsonc

    [[ -L ~/.config/waybar/style.css ]] && rm ~/.config/waybar/style.css
    ln -s ~/.dotfiles/.config/waybar/style.css ~/.config/waybar/style.css

    echo "Dotfiles setup complete!"
    cd 
}

function install_oh_my_zsh() {
    # Check if oh-my-zsh is already installed
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        # Install oh-my-zsh
        echo "Installing oh-my-zsh..."
        sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" || {
            echo "Error installing oh-my-zsh!"
            return 1
        }
    else
        echo "oh-my-zsh is already installed."
    fi
}

# Function to install oh-my-zsh and its customizations
function install_oh_my_zsh_customizations() {
    install_zsh_extensions
    install_powerlevel10k
}

# Function to install zsh-extensions and powerlevel10k
function install_zsh_extensions() {
    # Install zsh-extensions: auto-suggestions
    if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        echo "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || {
            echo "Error installing zsh-autosuggestions!"
            return 1
        }
    else
        echo "zsh-autosuggestions is already installed."
    fi

    # Install zsh-syntax-highlighting
    if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
        echo "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || {
            echo "Error installing zsh-syntax-highlighting!"
            return 1
        }
    else
        echo "zsh-syntax-highlighting is already installed."
    fi
}

# Function to install powerlevel10k theme
function install_powerlevel10k() {
    if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
        echo "Installing powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k || {
            echo "Error installing powerlevel10k!"
            return 1
        }
    else
        echo "powerlevel10k is already installed."
    fi
}

function create_downloads_and_dev_dir() {
    # Ensure download directory exists
    downloads_dir="$HOME/downloads"
    if [ ! -d "$downloads_dir" ]; then
        echo "Creating the Downloads folder..."
        mkdir "$downloads_dir"
        echo "Downloads folder created."
    else
        echo "The Downloads folder already exists."
    fi

    # Ensure 'dev' directory exists
    dev_dir="$HOME/dev"
    if [ ! -d "$dev_dir" ]; then
        echo "Creating the 'dev' directory..."
        mkdir "$dev_dir"
        echo "'dev' directory created."
    else
        echo "The 'dev' directory already exists."
    fi
}

function backup_zshrc () {
    zshrc="$HOME/.zshrc"
    backup_dir="$HOME/.dotfiles_backup"
    backup_file="$backup_dir/$(basename "$zshrc").backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    cp "$zshrc" "$backup_file"
    echo ".zshrc backed up to: $backup_file"
}

function install_sdkman() {
    # Check if SDKMAN is already installed
    if [ -d "$HOME/.sdkman" ]; then
        echo "SDKMAN is already installed."
        return 0
    fi

    # Install SDKMAN
    echo "Installing SDKMAN..."
    curl -s "https://get.sdkman.io" | bash

    # Append SDKMAN initialization to .zshrc if not already present
    if ! grep -qc 'sdkman-init.sh' "$HOME/.zshrc"; then
        echo 'Adding SDKMAN initialization to .zshrc'
        echo -e '\n# Load SDKMAN' >> "$HOME/.zshrc"
        echo '[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"' >> "$HOME/.zshrc"
    fi

    # Update current shell session with SDKMAN
    # source "$HOME/.sdkman/bin/sdkman-init.sh"
    
    echo "SDKMAN installation complete."
}

# Main execution
clear
menu

while true; do
    read -p "Enter choice [1-5]: " choice

    case $choice in
        1) 
            update_packages
            install_essentials 
            echo "Packages updated successfully. Essentials installed successfully."
            ;;
        2) 
            setup_dotfiles 
            echo "Dotfiles set up successfully."
            ;;
        3) 
            install_oh_my_zsh 
            echo "Oh My Zsh installed successfully. Extensions and themes installed successfully."
            ;;
        4)
            install_oh_my_zsh_customizations
            echo "Oh My Zsh installed successfully. Extensions and themes installed successfully."
            ;;
        5) 
            install_sdkman
            echo "SDKMAN installed successfully."
            ;;
        0)
            echo "Goodbye!"
            footer
            exit 0
            ;;
        *) 
            echo "Invalid choice. Please choose between 1-5." 
            ;;
    esac

    echo ""
    menu
done
