#!/bin/bash

# Script to setup command line on new Linux machines
# It installs git, zsh and oh-my-zsh

# Update package lists and upgrade
sudo apt update && sudo apt upgrade -y

# Install git
sudo apt install -y git

# Install zsh
sudo apt install -y zsh

# Change the default shell to zsh
chsh -s $(which zsh)

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Setup completed! Restart your terminal or log in again to start using zsh with oh-my-zsh."

# Install zsh extensions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Pull dotfiles from Github
git clone https://github.com/Sullivansome/dotfiles.git ~/.dotfiles

# Symbol links
cd 
rm .zshrc
ln -s ~/.dotfiles/.zshrc ~/.zshrc
rm .gitconfig
ln -s ~/.dotfiles/.gitconfig ~/.gitconfig

# Relaod zsh
exec zsh
