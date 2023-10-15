#!/bin/bash

# OS-specific configurations
OS="$(uname)"

if [ "$OS" == "Linux" ]; then
    echo "Setting up Linux specific configurations..."

    # Script to setup command line on new Linux machines
    # It installs git, zsh and oh-my-zsh

    # Update package lists and upgrade
    echo "1. Updating package lists and updating..."
    sudo apt update && sudo apt upgrade -y

    # Install git
    echo "2. Installing git..."
    sudo apt install -y git

    # Install zsh
    echo "3. Installing zsh..."
    sudo apt install -y zsh

    # Change the default shell to zsh
    echo "4. Changing the default shell to zsh..."
    chsh -s $(which zsh)

    # Install oh-my-zsh
    echo "5. Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    # Install zsh extensions
    echo "6. Installing zsh-extentions: auto-suggestions, syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

    # Pull dotfiles from Github and apply changes
    echo "7. Pulling dotfiles from Github..."
    git clone https://github.com/Sullivansome/dotfiles.git ~/.dotfiles

    echo "8. Backing up and linking dotfiles..."
    cd
    [ -f .zshrc ] && mv .zshrc .zshrc.backup
    ln -s ~/.dotfiles/.zshrc ~/.zshrc
    [ -f .gitconfig ] && mv .gitconfig .gitconfig.backup
    ln -s ~/.dotfiles/.gitconfig ~/.gitconfig

    echo "9. Installing openjdk..."

    # Creat download folder in the home directory if not exist
    cd 
    downloads_dir="$HOME/downloads"
    if [ ! -d "$downloads_dir" ]; then
        echo "Creating the Downloads folder..."
        mkdir "$downloads"
        echo "Downloads folder created."
    else
        echo "The Downloads folder already exists."
    fi

    # Retrive the latest openjdk 
    # Fetch the main OpenJDK page content
    page_content=$(curl -s https://jdk.java.net/)

    # Extract the highest JDK version that's ready for use (ignoring early access)
    latest_version=$(echo "$content" | grep -Eo 'Ready for use: JDK [0-9]+' | grep -Eo '[0-9]+' | sort -nr | head -1)

    # Fetch the version-specific page content (assuming the content structure you've provided)
    version_content=$(curl -s https://jdk.java.net/$latest_version/)

    # Extract the OpenJDK download link for the latest version (based on our earlier regex)
    download_link=$(echo "$version_content" | grep -Eo "https://download.java.net/java/GA/jdk$latest_version/[a-z0-9]+/[0-9]+/GPL/openjdk-$latest_version"_linux-x64_bin.tar.gz | head -1)

    echo "Latest production-ready version is JDK $latest_version"
    echo "Download link is: $download_link"

    # To download:

    wget $download_link


    echo "Setup completed! Restart your terminal or log in again to start using zsh with oh-my-zsh."
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
