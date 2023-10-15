#!/bin/bash

# 1. Detect the OS
OS="$(uname)"

# Function for Linux Menu
linux_menu() {
    echo "Choose an action for Linux:"
    echo "1) Update package lists and upgrade"
    echo "2) Install essential packages"
    echo "3) Pull dotfiles from Github and apply changes"
    echo "4) Install oh-my-zsh"
    echo "5) Install zsh extensions and powerlevel10k"
    echo "6) Install OpenJDK"
    echo "7) Install Flutter"
    echo "8) Exit"
}

function update_packages() {
    echo -e "\e[33mUpdating package lists and updating...\e[0m"
    sudo apt update && sudo apt upgrade -y || { echo "Failed to update packages. Exiting."; exit 1; }
}

function install_essentials() {
    echo -e "\e[33mInstalling curl, wget, jq, git, vim, and zsh...\e[0m"
    sudo apt install -y curl wget jq git vim zsh || { echo "Failed to install required packages. Exiting."; exit 1; }
}

function setup_dotfiles() {
    set -e  # stop the script if any command returns a non-zero exit code

    # Pull dotfiles from Github and apply changes
    echo "Pulling dotfiles from Github..."

    # Variables
    REPO_URL="https://github.com/Sullivansome/dotfiles.git"
    DEST_DIR="$HOME/.dotfiles"

    # Check if git is installed
    if ! command -v git &> /dev/null; then
        echo "Error: git is not installed. Please install git and try again."
        return 1
    fi

    cd  # Move to the home directory

    if [ -d "$DEST_DIR" ]; then
        echo "Backing up dotfiles..."
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
    echo "Cloning the dotfiles repository..."
    mkdir -p "$DEST_DIR"
    git clone "$REPO_URL" "$DEST_DIR"

    # System links
    echo "Creating symbolic links..."
    [[ -L ~/.zshrc ]] && rm ~/.zshrc
    ln -s ~/.dotfiles/.zshrc ~/.zshrc

    [[ -L ~/.gitconfig ]] && rm ~/.gitconfig
    ln -s ~/.dotfiles/.gitconfig ~/.gitconfig

    [[ -L ~/.p10k.zsh ]] && rm ~/.p10k.zsh
    ln -s ~/.dotfiles/.p10k.zsh ~/.p10k.zsh

    echo "Dotfiles setup complete!"
}

install_oh_my_zsh() {
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

    # Install zsh-extensions: auto-suggestions, if not already present
    if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        echo "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || {
            echo "Error installing zsh-autosuggestions!"
            return 1
        }
    else
        echo "zsh-autosuggestions is already installed."
    fi

    # Install zsh-syntax-highlighting, if not already present
    if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
        echo "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || {
            echo "Error installing zsh-syntax-highlighting!"
            return 1
        }
    else
        echo "zsh-syntax-highlighting is already installed."
    fi

    # Install powerlevel10k theme, if not already present
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

function install_openjdk() {
    cd ~

    echo "Preparing for OpenJDK installation..."

    # Ensure download directory exists
    downloads_dir="$HOME/downloads"
    if [ ! -d "$downloads_dir" ]; then
        echo "Creating the Downloads folder..."
        mkdir "$downloads_dir"
        echo "Downloads folder created."
    else
        echo "The Downloads folder already exists."
    fi

    # Fetch latest OpenJDK version
    page_content=$(curl -s https://jdk.java.net/)
    latest_version=$(echo "$page_content" | grep -Eo 'Ready for use: <a href="\/[0-9]+' | grep -Eo '[0-9]+' | sort -nr | head -1)

    while true; do
        read -p "The latest JDK version ready for use is $latest_version. Is this version satisfying? (yes/no) " answer
        case $answer in
            [Yy]* ) 
                echo "Thank you for the confirmation."
                break;;
            [Nn]* ) 
                echo "Okay, please check the website for other versions."
                return;;
            * ) 
                echo "Invalid answer. Please enter yes or no.";;
        esac
    done

    # Extract OpenJDK download link for the latest version
    version_content=$(curl -s https://jdk.java.net/"$latest_version"/)
    download_link=$(echo "$version_content" | grep -Eo "https://download\.java\.net/java/GA/jdk$latest_version/[^\"_]+_linux-x64_bin\.tar\.gz" | head -1)

    # Download the JDK
    download_dest="$downloads_dir/openjdk$latest_version.tar.gz"
    wget "$download_link" -O "$download_dest"
    echo "Downloaded OpenJDK $latest_version to $download_dest."

    # Verify download
    if [ ! -f "$download_dest" ] || [ ! -s "$download_dest" ]; then
        echo "Error: Failed to download OpenJDK."
        return 1
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

    # Unzip OpenJDK
    tar -xzvf "$download_dest" -C "$dev_dir"
    echo "OpenJDK $latest_version unzipped to $dev_dir."

    # Determine extracted JDK directory
    jdk_folder=$(ls "$dev_dir" | grep -E "^jdk" | head -1)
    if [ -z "$jdk_folder" ]; then
        echo "Error: Couldn't determine the extracted JDK folder."
        return 1
    fi

    # Update the .zshrc file
    zshrc="$HOME/.zshrc"
    backup_dir="$HOME/.dotfiles_backup"
    backup_file="$backup_dir/$(basename "$zshrc").backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    cp "$zshrc" "$backup_file"
    echo ".zshrc backed up to: $backup_file"

    # Update .zshrc with JAVA_HOME and PATH, ensuring not to duplicate
    linux_section_start=$(grep -n 'elif \[\[ "$(uname)" == "Linux" \]\];' "$zshrc" | cut -d: -f1)
    next_section_start=$(awk -v start="$linux_section_start" 'NR > start && /^\[\[.*\]\];$/ {print NR; exit}' "$zshrc")
    next_section_start=${next_section_start:-$(wc -l < "$zshrc")}
    new_java_home="$dev_dir/$jdk_folder"

    if ! grep -q "export JAVA_HOME=" "$zshrc"; then
        sed -i "${linux_section_start},${next_section_start}a\\# Java sdk\nexport JAVA_HOME=$new_java_home\nexport PATH=\$JAVA_HOME/bin:\$PATH\n" "$zshrc"
    else
        sed -i "${linux_section_start},${next_section_start}s|export JAVA_HOME=.*|export JAVA_HOME=$new_java_home|" "$zshrc"
        sed -i "${linux_section_start},${next_section_start}s|export PATH=\$JAVA_HOME/bin:.*|export PATH=\$JAVA_HOME/bin:\$PATH|" "$zshrc"
    fi
    echo "Updated .zshrc with the new JAVA_HOME and PATH."
}

install_flutter() {
    echo "Installing Flutter..."

    # Define directories
    local downloads_dir="$HOME/downloads"
    local dev_dir="$HOME/dev"
    local zshrc="$HOME/.zshrc"

    # Check if the directories exist, if not, create them
    mkdir -p "$downloads_dir" "$dev_dir"

    download_and_extract_flutter
    update_zshrc_for_flutter

    # Download and extract the latest Flutter release
    download_and_extract_flutter() {
        # Fetch the latest release details from Flutter's releases JSON
        local latest_release_data
        latest_release_data=$(curl -s "https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json")
        
        # Extract relevant release details
        local latest_release_hash
        latest_release_hash=$(echo "$latest_release_data" | jq -r '.current_release.stable')
        local archive_url
        archive_url=$(echo "$latest_release_data" | jq -r ".releases[] | select(.hash == \"$latest_release_hash\") .archive")
        
        # Download the Flutter archive
        echo "Downloading Flutter from $archive_url..."
        wget "$archive_url" -O "$downloads_dir/flutter.tar.xz"

        # Extract to desired location
        tar -xvf "$downloads_dir/flutter.tar.xz" -C "$dev_dir"
    }

    # Update the PATH in .zshrc to include Flutter's bin directory
    update_zshrc_for_flutter() {
        local linux_section_start
        linux_section_start=$(grep -n 'elif \[\[ "$(uname)" == "Linux" \]\];' ~/.zshrc | cut -d: -f1)
        local next_section_start
        next_section_start=$(awk -v start=$linux_section_start 'NR > start && /^\[\[.*\]\];$/ {print NR; exit}' "$zshrc")
        
        if [[ -z $next_section_start ]]; then
            next_section_start=$(wc -l < "$zshrc")
            next_section_start=$((next_section_start+1))
        fi

        if ! grep -q "$dev_dir/flutter/bin" "$zshrc"; then
            echo "Updating PATH in .zshrc..."
            sed -i "${linux_section_start}a\\# Flutter SDK\nexport PATH=\$PATH:$dev_dir/flutter/bin\n" "$zshrc"
        else
            echo "Flutter path already exists in .zshrc. Skipping update."
        fi
    }
}

# Function for macOS Menu (example, since the macOS part of your script is truncated)
macos_menu() {
    echo "Choose an action for macOS:"
    echo "1) Install Homebrew"
    # Add more macOS-specific actions here...
    echo "2) Exit"
}

# Main execution starts here
clear
if [ "$OS" == "Linux" ]; then
    linux_menu



    while true; do
        read -p "Enter choice [0-7]: " choice

        case $choice in
            1) update_packages ;;
            2) install_essentials ;;
            3) setup_dotfiles ;;
            4) install_oh_my_zsh ;;
            5) install_openjdk ;;
            6) install_flutter ;;
            0) echo "Goodbye!"; break ;;
            *) echo "Invalid choice. Please choose between 1-7." ;;
        esac

        echo ""
        echo "Choose next action:"
        echo "1) Update packages"
        echo "2) Install essential packages"
        echo "3) Setup dotfiles"
        echo "4) Install Oh My Zsh"
        echo "5) Install OpenJDK"
        echo "6) Install Flutter"
        echo "0) Exit"
    done

elif [ "$OS" == "Darwin" ]; then
    while true; do
        macos_menu
        read -p "Enter your choice: " choice
        case $choice in
            1) 
                # Install Homebrew
                # ... 
                ;;
            # ... Handle other macOS-specific options in a similar way
            2) 
                echo "Exiting..."
                break
                ;;
            *)
                echo "Invalid choice!"
                ;;
        esac
    done

else
    echo "OS not recognized!"
fi



echo "Choose an option to proceed:"
echo "1) Update packages"
echo "2) Install essential packages"
echo "3) Setup dotfiles"
echo "4) Install Oh My Zsh"
echo "5) Install OpenJDK"
echo "6) Install Flutter"
echo "7) Exit"

elif [ "$OS" == "Darwin" ]; then
    echo "Setting up macOS specific configurations..."

    # Installing Homebrew if not already installed
    which brew >/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Installing openjdk, flutter, and other macOS specific tools
    brew install openjdk
    brew install flutter

    # For SDKMAN
    curl -s "https://get.sdkman.io" | bash

else
    echo "Unknown OS! \n Installation abort!"
fi

# Set -x: This command will print every command the shell executes. This can be very useful for seeing exactly what your script is doing. Add set -x at the start of your script and set +x at the end to turn it off.