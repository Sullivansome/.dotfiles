#!/bin/bash

# OS-specific configurations
OS="$(uname)"

if [ "$OS" == "Linux" ]; then
    echo "Setting up Linux specific configurations..."

    # Get confirmation from the user before starting
    read -p "This script will install various packages and set up your Linux environment. Do you wish to continue? (yes/no): " confirm
    case $confirm in
        [Yy]* ) echo "Starting the setup...";;
        [Nn]* ) echo "Exiting setup."; exit 1;;
        * ) echo "Invalid choice. Exiting setup."; exit 1;;
    esac

    counter=1

    # Update package lists and upgrade
    echo "$counter. Updating package lists and updating..."
    sudo apt update && sudo apt upgrade -y
    ((counter++))

    # Install packages: curl, wget, jq, git, zsh
    echo "$counter. Installing curl, wget, jq, git, and zsh..."
    sudo apt install -y curl wget jq git zsh
    ((counter++))

    # Change the default shell to zsh
    echo "$counter. Changing the default shell to zsh..."
    chsh -s $(which zsh)
    ((counter++))

    # Install oh-my-zsh
    echo "$counter. Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ((counter++))

    # Install zsh extensions
    echo "$counter. Installing zsh-extensions: auto-suggestions, syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    ((counter++))

    # Pull dotfiles from Github and apply changes
    echo "$counter. Pulling dotfiles from Github..."
    git clone https://github.com/Sullivansome/dotfiles.git ~/.dotfiles
    ((counter++))

    echo "$counter. Backing up and linking dotfiles..."
    # Backup and link .zshrc
    [ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.backup
    ln -s ~/.dotfiles/.zshrc ~/.zshrc
    # Backup and link .gitconfig
    [ -f ~/.gitconfig ] && mv ~/.gitconfig ~/.gitconfig.backup
    ln -s ~/.dotfiles/.gitconfig ~/.gitconfig
    ((counter++))

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

    # Retrive the latest openjdk 
    # Fetch the main OpenJDK page content
    page_content=$(curl -s https://jdk.java.net/)

    # Extract the highest JDK version that's ready for use (ignoring early access)
    latest_version=$(echo "$page_content" | grep -Eo 'Ready for use: <a href="\/[0-9]+' | grep -Eo '[0-9]+' | sort -nr | head -1)
    echo "The latest version ready for use is: JDK $latest_version"

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
    download_link=$(echo "$version_content" | grep -Eo "https://download\.java\.net/java/GA/jdk$latest_version/[^\"_]+_linux-x64_bin\.tar\.gz")

    echo "Download link is: $download_link"

    # Download the JDK into the Downloads folder
    download_dest="$downloads_dir/openjdk$latest_version.tar.gz"
    wget "$download_link" -O "$download_dest"
    echo "Downloaded OpenJDK $latest_version to $download_dest."

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
    backup_file="$zshrc.backup_$(date +%Y%m%d_%H%M%S)"
    cp "$zshrc" "$backup_file"
    echo ".zshrc backed up to: $backup_file"

    # Check if JAVA_HOME export exists. If not, add it.
    if ! grep -q "export JAVA_HOME=" "$zshrc"; then
        echo "# Java sdk" >> "$zshrc"
        echo "export JAVA_HOME=$dev_dir/$jdk_folder" >> "$zshrc"
        echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> "$zshrc"
    else
        # Replace existing JAVA_HOME and PATH assignments
        sed -i "s|export JAVA_HOME=.*|export JAVA_HOME=$dev_dir/$jdk_folder|" "$zshrc"
        sed -i "s|export PATH=\$JAVA_HOME/bin:.*|export PATH=\$JAVA_HOME/bin:\$PATH|" "$zshrc"
    fi
    ((counter++))
    echo "Updated .zshrc with the new JAVA_HOME and PATH."

    # Install Flutter
    echo "$counter. Installing Flutter..."
    # Define directories
    downloads_dir="$HOME/downloads"
    dev_dir="$HOME/dev"

    # Fetch the latest release details from Flutter's releases JSON
    LATEST_RELEASE_JSON=$(curl -s "https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json" | jq -r '.current_release.stable')
    LATEST_RELEASE_DETAILS=$(curl -s "https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json" | jq -r ".releases[] | select(.hash == \"$LATEST_RELEASE_JSON\")")

    # Extract the archive URL from the details
    FLUTTER_ARCHIVE_URL=$(echo "$LATEST_RELEASE_DETAILS" | jq -r '.archive')
    echo "$FLUTTER_ARCHIVE_URL"
    # Check if ~/downloads exists, if not, create it
    [ -d "$HOME/downloads" ] || mkdir "$HOME/downloads"

    # Download the Flutter archive
    wget "$FLUTTER_ARCHIVE_URL" -O "$HOME/downloads/flutter.tar.xz"

    # Extract to desired location
    [ -d "$HOME/dev" ] || mkdir "$HOME/dev"
    tar -xvf "$HOME/downloads/flutter.tar.xz" -C "$HOME/dev"

    # Update the PATH in .zshrc if it doesn't already contain the Flutter bin directory
    zshrc="$HOME/.zshrc"
    if ! grep -q "$dev_dir/flutter/bin" "$zshrc"; then
        echo "Updating PATH in .zshrc..."
        echo "# Flutter SDK" >> "$zshrc"
        echo "export PATH=\$PATH:$dev_dir/flutter/bin" >> "$zshrc"
    else
        echo "Flutter path already exists in .zshrc. Skipping update."
    fi

    # Source the .zshrc file
    # echo "Sourcing .zshrc to reflect changes..."
    # source "$zshrc"
    # echo ".zshrc has been sourced."

    # Check Flutter installation
    # flutter doctor




    echo "Setup completed! Restart your terminal or log in again to start using zsh with oh-my-zsh."
    # Source the .zshrc file
    source "~/.zshrc"
    echo ".zshrc has been sourced."
    # Relaod zsh
    exec zsh

    

    # You might want to install OpenJDK or any other necessary packages specific for Linux here
    # e.g., sudo apt install openjdk-XX-jdk

    # Considering pipx related comment in .zshrc, you may want to install pipx and its related tools
    # e.g., pip install pipx

    # For Flutter, download and setup Flutter SDK for Linux.

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
