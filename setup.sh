#!/bin/bash

# HEADER
header() {
    # clear
    echo -e "###############################################################"
    echo -e "########## \e[93mWELCOME TO THE LINUX SETUP SCRIPT\e[0m #############"
    echo -e "###############################################################"
    echo
}

# FOOTER
footer() {
    echo
    echo -e "\e[44m###############################################################\e[0m"
    echo -e "\e[44m#############\e[0m \e[93mTHANK YOU FOR USING THE SCRIPT\e[0m \e[44m##############\e[0m"
    echo -e "\e[44m###############################################################\e[0m"
}

# SAMPLE SPINNER
# Usage: `long_running_command & spinner`
spinner() {
    local pid=$!
    local delay=0.75
    local spinstr='|/-\'
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
    echo "3) Install oh-my-zsh, zsh extensions and powerlevel10k"
    echo "4) Install OpenJDK"
    echo "5) Install Python"
    echo "6) Install Flutter"
    echo "7) Exit"
}

function update_packages() {
    echo -e "\e[33mUpdating package lists and updating...\e[0m"
    sudo apt update || { echo "Failed to update packages. Exiting."; exit 1; }
}

function install_essentials() {

    os="$(uname)"

    # Define the packages to install
    packages="curl wget jq git vim tree zsh"

    echo -e "\e[33mInstalling $packages...\e[0m"

    if [[ "$os" == "Linux" ]]; then
        # Check if apt is available
        if command -v apt > /dev/null; then
            update_packages
            sudo apt install -y $packages || { echo -e "\e[31mFailed to install required packages using apt. Exiting.\e[0m"; exit 1; }
        else
            echo -e "\e[31mAPT package manager not found. Are you sure you're using a Debian/Ubuntu-based distribution?\e[0m"
            exit 1;
        fi
    else
        echo -e "\e[31mUnsupported OS detected. This script is designed for Linux only.\e[0m"
        exit 1;
    fi

    echo -e "\e[32mInstallation complete!\e[0m"
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

backup_zshrc () {
    zshrc="$HOME/.zshrc"
    backup_dir="$HOME/.dotfiles_backup"
    backup_file="$backup_dir/$(basename "$zshrc").backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    cp "$zshrc" "$backup_file"
    echo ".zshrc backed up to: $backup_file"
}

check_or_install_homebrew() {
    # Ensure brew is installed
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is not installed. Installing now..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

function install_openjdk() {
    cd

    echo "Preparing for OpenJDK installation..."

    # Determine OS
    os=$(uname)

    if [[ "$os" == "Linux" ]]; then
        create_downloads_and_dev_dir

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

        # Unzip OpenJDK
        tar -xzvf "$download_dest" -C "$dev_dir"
        echo "OpenJDK $latest_version unzipped to $dev_dir."

        # Determine extracted JDK directory
        jdk_folder=$(ls "$dev_dir" | grep -E "^jdk" | head -1)
        if [ -z "$jdk_folder" ]; then
            echo "Error: Couldn't determine the extracted JDK folder."
            return 1
        fi

        # Set the new JAVA_HOME path for Linux
        new_java_home="$dev_dir/$jdk_folder"

        # Back up the .zshrc file   
        backup_zshrc

        # Check and update or add JAVA_HOME and PATH for Linux
        if grep -q 'JAVA_HOME=' "$zshrc" && grep -A5 'elif \[\[ "$(uname)" == "Linux" \]\]' "$zshrc" | grep -q 'JAVA_HOME='; then
            sed -i "s|export JAVA_HOME=.*|export JAVA_HOME=$new_java_home|" "$zshrc"
        else
            sed -i "/elif \[\[ \"\$(uname)\" == \"Linux\" \]\]; then/a\\
            # JAVA_HOME\\
            export JAVA_HOME=$new_java_home" "$zshrc"
        fi

        if grep -A5 'elif \[\[ "$(uname)" == "Linux" \]\]' "$zshrc" | grep -q 'PATH.*JAVA_HOME'; then
            sed -i "s|export PATH=.*JAVA_HOME.*|export PATH=\"\$JAVA_HOME/bin:\$PATH\"|" "$zshrc"
        else
            sed -i "/JAVA_HOME=$new_java_home/a\\
            export PATH=\"\$JAVA_HOME/bin:\$PATH\"" "$zshrc"
        fi



    elif [[ "$os" == "Darwin" ]]; then
        check_or_install_homebrew

        # Install OpenJDK using brew
        brew install openjdk
        new_java_home="/opt/homebrew/opt/openjdk"

        # Update .zshrc for macOS
        # Check and update or add JAVA_HOME and PATH for macOS
        if grep -q 'JAVA_HOME=' "$zshrc" && grep -A5 'if \[\[ "$(uname)" == "Darwin" \]\]' "$zshrc" | grep -q 'JAVA_HOME='; then
            sed -i '' "s|export JAVA_HOME=.*|export JAVA_HOME=$new_java_home|" "$zshrc"
        else
            sed -i '' "/if \[\[ \"\$(uname)\" == \"Darwin\" \]\]; then/a\\
            # JAVA_HOME\\
            export JAVA_HOME=$new_java_home" "$zshrc"
        fi

        if grep -A5 'if \[\[ "$(uname)" == "Darwin" \]\]' "$zshrc" | grep -q 'PATH.*JAVA_HOME'; then
            sed -i '' "s|export PATH=.*JAVA_HOME.*|export PATH=\"\$JAVA_HOME/bin:\$PATH\"|" "$zshrc"
        else
            sed -i '' "/JAVA_HOME=$new_java_home/a\\
            export PATH=\"\$JAVA_HOME/bin:\$PATH\"" "$zshrc"
        fi

    else
        echo -e "\e[31mUnsupported OS detected. This script is designed for Linux and macOS only.\e[0m"
        exit 1;
    fi

    echo "Updated .zshrc with the new JAVA_HOME and PATH."
    echo "$new_java_home"
}

install_flutter() {

    echo "Installing Flutter..."

    # Define directories
    local downloads_dir="$HOME/downloads"
    local dev_dir="$HOME/dev"
    local zshrc="$HOME/.zshrc"
    local os_name

    # Detect operating system
    if [[ "$(uname)" == "Darwin" ]]; then
        os_name="macos"
    elif [[ "$(uname)" == "Linux" ]]; then
        os_name="linux"
    else
        echo "Unsupported operating system."
        return 1
    fi

    # Check if the directories exist, if not, create them
    mkdir -p "$downloads_dir" "$dev_dir"

    download_and_extract_flutter $os_name
    update_zshrc_for_flutter $os_name

    # Download and extract the latest Flutter release
    download_and_extract_flutter() {
        local os=$1
        local base_url="https://storage.googleapis.com/flutter_infra_release/releases"
        
        local latest_release_data
        local archive_url

        # Determine host architecture
        local arch
        if [[ "$(uname -m)" == "arm64" ]]; then
            arch="arm64"
        else
            arch="x64"
        fi

        if [[ $os == "linux" ]]; then
            latest_release_data=$(curl -s "$base_url/releases_linux.json")
        elif [[ $os == "macos" ]]; then
            latest_release_data=$(curl -s "$base_url/releases_macos.json")
            # Fetch the stable release for the detected architecture
            local release_hash
            release_hash=$(echo "$latest_release_data" | jq -r ".current_release.stable")
            archive_url=$(echo "$latest_release_data" | jq -r ".releases[] | select(.hash == \"$release_hash\" and .dart_sdk_arch == \"$arch\") .archive")
        else
            echo "Unsupported operating system for downloading Flutter."
            return 1
        fi

        archive_url="$base_url/$archive_url"
        
        echo "Downloading Flutter from $archive_url..."

        if [[ $os == "linux" ]]; then
            wget "$archive_url" -O "$downloads_dir/flutter.tar.xz"
            tar -xvf "$downloads_dir/flutter.tar.xz" -C "$dev_dir"
        elif [[ $os == "macos" ]]; then
            curl -o "$downloads_dir/flutter.zip" "$archive_url"
            unzip "$downloads_dir/flutter.zip" -d "$dev_dir"
        fi
    }

    # Update the PATH in .zshrc to include Flutter's bin directory
    update_zshrc_for_flutter() {
        local os=$1

        local section_start
        local next_section_start
        local flutter_path="export PATH=\$PATH:$dev_dir/flutter/bin"

        if [[ $os == "linux" ]]; then
            section_start=$(grep -n 'elif \[\[ "$(uname)" == "Linux" \]\];' "$zshrc" | cut -d: -f1)
        elif [[ $os == "macos" ]]; then
            section_start=$(grep -n 'elif \[\[ "$(uname)" == "Darwin" \]\];' "$zshrc" | cut -d: -f1)
        fi

        next_section_start=$(awk -v start=$section_start 'NR > start && /^elif \[\[ / {print NR; exit}' "$zshrc")
        next_section_start=${next_section_start:-$(wc -l < "$zshrc")}

        if [[ -z $next_section_start ]]; then
            next_section_start=$(wc -l < "$zshrc")
            next_section_start=$((next_section_start+1))
        fi

        if grep -q "$dev_dir/flutter/bin" "$zshrc"; then
            echo "Updating Flutter path in .zshrc..."
            sed -i "/$dev_dir\/flutter\/bin/c\\$flutter_path" "$zshrc"
        else
            echo "Adding Flutter path to .zshrc..."
            sed -i "${section_start}a\\# Flutter SDK\n$flutter_path\n" "$zshrc"
        fi
}

}

install_python() {
    # Check if Python is already installed
    if command -v python3 &> /dev/null; then
        echo "Python is already installed."
        return 0
    fi

    # Determine OS
    local os="$(uname)"
    local latest_version
    local id=""

    # Check for Linux distribution
    if [ "$os" == "Linux" ] && [ -f "/etc/os-release" ]; then
        id=$(awk -F= '$1=="ID" {print $2}' /etc/os-release)
    fi

    case "$os" in
        Linux)
            case "$id" in
                "ubuntu"|"debian")
                    echo "Detected Ubuntu/Debian"
                    sudo apt update || { echo "Failed to update repositories."; exit 1; }
                    latest_version=$(apt-cache madison python3 | head -1 | awk '{print $3}')
                    ;;
                "fedora")
                    echo "Detected Fedora"
                    # Latest version can be fetched using dnf but might be complex.
                    # For now, just installing the latest without version choice for Fedora.
                    ;;
                *)
                    echo "Unsupported or unknown Linux distribution"
                    exit 1
                    ;;
            esac
            ;;
        Darwin)
            echo "Detected macOS"
            latest_version=$(brew info python --json | jq -r '.[0].versions.stable')
            ;;
        *)
            echo "Unsupported operating system"
            exit 1
            ;;
    esac

    # Prompt the user
    read -p "Which version of Python do you want to install? Press enter for the latest (default: $latest_version): " desired_version
    desired_version=${desired_version:-$latest_version}
    read -p "You chose Python version $desired_version. Proceed? (y/n): " confirmation
    if [[ "$confirmation" != "y" ]]; then
        echo "Installation aborted by the user."
        return 0
    fi

    # Install based on OS and distribution
    case "$os" in
        Linux)
            case "$id" in
                "ubuntu"|"debian")
                    sudo apt install -y python3="$desired_version" python3-pip || { echo "Failed to install Python."; exit 1; }
                    ;;
                "fedora")
                    sudo dnf install -y python3 python3-pip || { echo "Failed to install Python."; exit 1; }
                    ;;
            esac
            ;;
        Darwin)
            # In most cases, brew installs the latest version by default.
            brew install python || { echo "Failed to install Python."; exit 1; }
            ;;
    esac
}

# Main execution starts here
clear
menu

while true; do
    read -p "Enter choice [1-8]: " choice

    case $choice in
        1) 
            update_packages
            install_essentials 
            echo "Packages updated successfully. Essentails installed successfully"
            ;;
        2) 
            setup_dotfiles 
            echo "Dotfiles set up successfully."
            ;;
        3) 
            install_oh_my_zsh 
            echo "Oh My Zsh installed successfully. Extensions and themes installed successfully"
            ;;
        4) 
            install_openjdk 
            echo "OpenJDK installed successfully."
            ;;
        5) 
            install_python
            echo "Python installed successfully."
            ;;
        6)  install_flutter
            echo "Flutter installed successfully."
            ;;
        7)
            echo "Goodbye!"
            footer
            exit 0
            ;;
        *) 
            echo "Invalid choice. Please choose between 1-8." 
            ;;
    esac

    echo ""
    menu
done
