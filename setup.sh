#!/bin/bash

# OS-specific configurations
OS="$(uname)"

if [ "$OS" == "Linux" ]; then

    echo -e "\e[34mSetting up Linux specific configurations...\e[0m"

    # Confirmation from user
    read -p "This script will install various packages and set up your Linux environment. Do you wish to continue? (yes/no): " confirm
    case $confirm in
        [Yy]* ) echo "Starting the setup...";;
        [Nn]* ) echo "Exiting setup."; exit 1;;
        * ) echo "Invalid choice. Exiting setup."; exit 1;;
    esac

    counter=1

    # Update package lists and upgrade
    echo -e "\e[33m$counter. Updating package lists and updating...\e[0m"
    sudo apt update && sudo apt upgrade -y || { echo "Failed to update packages. Exiting."; exit 1; }
    ((counter++))

    # Install essential packages
    echo -e "\e[33m$counter. Installing curl, wget, jq, git, vim, and zsh...\e[0m"
    sudo apt install -y curl wget jq git vim zsh || { echo "Failed to install required packages. Exiting."; exit 1; }
    ((counter++))

    # Install oh-my-zsh
    echo "$counter. Installing oh-my-zsh..."
    sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
    ((counter++))

    # Install power-level-10k
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.zsh_themes
    ln -s ~/.dotfiles/.p10k.zsh ~/.p10k.zsh

    # Install zsh extensions
    echo "$counter. Installing zsh-extensions: auto-suggestions, syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    ((counter++))

    # Pull dotfiles from Github and apply changes
    echo "$counter. Pulling dotfiles from Github..."
    # Variables
    REPO_URL="https://github.com/Sullivansome/dotfiles.git"
    DEST_DIR="$HOME/.dotfiles"

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
    git clone "$REPO_URL" "$DEST_DIR"

    # System links
    ln -s ~/.dotfiles/.zshrc ~/.zshrc
    ln -s ~/.dotfiles/.gitconfig ~/.gitconfig
    ((counter++))

    # Prompt before installing openjdk
    skip_openJDK_install=0
    while true; do
        read -p "Would you like to install OpenJDK? (yes/no): " confirm_jdk
        case $confirm_jdk in
            [Yy]* ) break;;
            [Nn]* ) echo "Skipping OpenJDK installation."; skip_openJDK_install=1; break;;
            * ) echo "Invalid choice. Please answer with yes or no.";;
        esac
    done

    if [ $skip_openJDK_install -eq 0 ]; then 
        # ... [Continue with operations like installing openjdk]
        echo "$counter. Installing openjdk..."

        # Creat download folder in the home directory if not exist
        cd 
        downloads_dir="$HOME/downloads"
        if [ ! -d "$downloads_dir" ]; then
            echo "Creating the Downloads folder..."
            mkdir "$downloads_dir"
            echo "Downloads folder created."
        else
            echo "The Downloads folder already exists."
        fi

        # Fetch and prompt for openjdk installation
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
                    break;;
                * ) 
                    echo "Invalid answer. Please enter yes or no.";;
            esac
        done

        # Fetch the version-specific page content (assuming the content structure you've provided)
        version_content=$(curl -s https://jdk.java.net/$latest_version/)

        # Extract the OpenJDK download link for the latest version (based on our earlier regex)
        download_link=$(echo "$version_content" | grep -Eo "https://download\.java\.net/java/GA/jdk$latest_version/[^\"_]+_linux-x64_bin\.tar\.gz" | head -1)

        echo "Download link is: $download_link"

        # Download the JDK into the Downloads folder
        download_dest="$downloads_dir/openjdk$latest_version.tar.gz"
        wget "$download_link" -O "$download_dest"
        echo "Downloaded OpenJDK $latest_version to $download_dest."

        if [ ! -f "$HOME/downloads/openjdk21.tar.gz" ] || [ ! -s "$HOME/downloads/openjdk21.tar.gz" ]; then
        echo "Error: Failed to download OpenJDK."
        exit 1
        fi

        # Check for the 'dev' directory in the home directory and create if it doesn't exist
        dev_dir="$HOME/dev"
        if [ ! -d "$dev_dir" ]; then
            echo "Creating the 'dev' directory in the home directory..."
            mkdir "$dev_dir"
            echo "'dev' directory created."
        else
            echo "The 'dev' directory already exists in the home directory."
        fi

        # Unzip the downloaded file into the 'dev' directory
        tar -xzvf "$download_dest" -C "$dev_dir"
        echo "OpenJDK $latest_version unzipped to $dev_dir."

        # You can optionally remove the downloaded tar.gz file after extraction if you want
        # rm "$download_dest"

        # Determine the extracted folder name (assuming the structure is consistent and it begins with 'jdk')
        jdk_folder=$(ls "$dev_dir" | grep -E "^jdk" | head -1)
        if [ -z "$jdk_folder" ]; then
            echo "Error: Couldn't determine the extracted JDK folder."
            exit 1
        fi

        # Update the .zshrc file
        zshrc="$HOME/.zshrc"

        # Backup the .zshrc file
        backup_dir="$HOME/.dotfiles_backup"
        backup_file="$backup_dir/$(basename $zshrc).backup_$(date +%Y%m%d_%H%M%S)"
        # Ensure the backup directory exists
        mkdir -p "$backup_dir"
        cp "$zshrc" "$backup_file"
        echo ".zshrc backed up to: $backup_file"

        # Check if JAVA_HOME export exists. If not, add it.
        if ! grep -q "export JAVA_HOME=" "$zshrc"; then
            echo "# Java sdk" >> "$zshrc"
            echo "export JAVA_HOME=$dev_dir/$jdk_folder" >> "$zshrc"
            echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> "$zshrc"
        else
            # Print the exact paths for debugging
            new_java_home="$dev_dir/$jdk_folder"
            echo "Setting JAVA_HOME to: $new_java_home"
            echo "Setting PATH to: $new_java_home/bin:$PATH"

            # Replace existing JAVA_HOME and PATH assignments
            sed -i "s|export JAVA_HOME=.*|export JAVA_HOME=$new_java_home|" "$zshrc"
            sed -i "s|export PATH=\$JAVA_HOME/bin:.*|export PATH=\$JAVA_HOME/bin:\$PATH|" "$zshrc"
        fi
        ((counter++))
        echo "Updated .zshrc with the new JAVA_HOME and PATH."
    fi
    # Prompt before installing flutter
    # Initialize skip_flutter_install flag
    skip_flutter_install=0
    while true; do
        read -p "Would you like to install Flutter? (yes/no): " confirm_flutter
        case $confirm_flutter in
            [Yy]* ) break;;
            [Nn]* ) echo "Skipping Flutter installation."; skip_flutter_install=1; break;;
            * ) echo "Invalid choice. Please answer with yes or no.";;
        esac
    done

    # ... [Continue with operations like installing flutter]
    if [ $skip_flutter_install -eq 0 ]; then
        # Install Flutter
        echo "$counter. Installing Flutter..."

        # Define directories
        downloads_dir="$HOME/downloads"
        dev_dir="$HOME/dev"
        zshrc="$HOME/.zshrc"

        # Check if the directories exist, if not, create them
        [ -d "$downloads_dir" ] || mkdir "$downloads_dir"
        [ -d "$dev_dir" ] || mkdir "$dev_dir"

        # Fetch the latest release details from Flutter's releases JSON
        LATEST_RELEASE_JSON_DATA=$(curl -s "https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json")
        LATEST_RELEASE_HASH=$(echo "$LATEST_RELEASE_JSON_DATA" | jq -r '.current_release.stable')
        LATEST_RELEASE_DETAILS=$(echo "$LATEST_RELEASE_JSON_DATA" | jq -r ".releases[] | select(.hash == \"$LATEST_RELEASE_HASH\")")

        # Extract the archive URL from the details
        FLUTTER_ARCHIVE_URL=$(echo "$LATEST_RELEASE_DETAILS" | jq -r '.archive')
        echo "$FLUTTER_ARCHIVE_URL"

        # Download the Flutter archive
        wget "$FLUTTER_ARCHIVE_URL" -O "$downloads_dir/flutter.tar.xz"

        # Extract to desired location
        tar -xvf "$downloads_dir/flutter.tar.xz" -C "$dev_dir"

        # Back up
        backup_dir="$HOME/.dotfiles_backup"
        backup_file="$backup_dir/$(basename $zshrc).backup_$(date +%Y%m%d_%H%M%S)"
        # Ensure the backup directory exists
        mkdir -p "$backup_dir"
        # Update the PATH in .zshrc if it doesn't already contain the Flutter bin directory
        if ! grep -q "$dev_dir/flutter/bin" "$zshrc"; then
            echo "Updating PATH in .zshrc..."
            echo "# Flutter SDK" >> "$zshrc"
            echo "export PATH=\$PATH:$dev_dir/flutter/bin" >> "$zshrc"
        else
            echo "Flutter path already exists in .zshrc. Skipping update."
        fi
    fi

    # Completion message
    echo -e "\e[32mSetup completed! Restart your terminal or log in again to start using zsh with oh-my-zsh.\e[0m"
    source "~/.zshrc"
    exec zsh

    # Change default shell to zsh
    echo -e "\e[33m$counter. Changing the default shell to zsh...\e[0m"
    chsh -s $(which zsh)
    ((counter++))

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

