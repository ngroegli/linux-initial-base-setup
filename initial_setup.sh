#!/bin/bash

set -e  # Exit on error

# Global variables
GITHUB_USERNAME="ngroegli"
REPO_NAME="ansible-infrastructure"
GIT_DIR="$HOME/git"
REPO_URL="git@github.com:$GITHUB_USERNAME/$REPO_NAME.git"
DEST_DIR="$GIT_DIR/$REPO_NAME"

# Detect OS and package manager
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Unsupported OS"
    exit 1
fi

update_packages() {
    case "$OS" in
        ubuntu|debian|raspbian)
            sudo apt update -y && sudo apt upgrade -y
            ;;
        fedora|centos|rhel)
            sudo dnf update -y
            ;;
        arch|manjaro)
            sudo pacman -Syu --noconfirm
            ;;
        opensuse*)
            sudo zypper refresh && sudo zypper update -y
            ;;
        *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

install_package() {
    local package=$1
    case "$OS" in
        ubuntu|debian|raspbian)
            sudo apt install -y "$package"
            ;;
        fedora|centos|rhel)
            sudo dnf install -y "$package"
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm "$package"
            ;;
        opensuse*)
            sudo zypper install -y "$package"
            ;;
    esac
}

update_packages

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Install or update Git
if command_exists git; then
    echo "Git is already installed. Updating..."
else
    echo "Installing Git..."
    install_package git
fi

# Install or update GitHub CLI (gh)
if command_exists gh; then
    echo "GitHub CLI (gh) is already installed. Updating..."
else
    echo "Installing GitHub CLI (gh)..."
    install_package gh
fi

# Install or update Docker Engine
if command_exists docker; then
    echo "Docker is already installed. Updating..."
else
    echo "Installing Docker Engine..."
    case "$OS" in
        ubuntu|debian|raspbian)
            install_package apt-transport-https
            install_package ca-certificates
            install_package curl
            install_package gnupg-agent
            install_package software-properties-common
            curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo apt-key add -
            sudo add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/$OS $(lsb_release -cs) stable"
            sudo apt update -y
            install_package docker-ce docker-ce-cli containerd.io
            ;;
        fedora|centos|rhel)
            install_package dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io
            ;;
        arch|manjaro)
            install_package docker
            ;;
        opensuse*)
            sudo zypper addrepo https://download.opensuse.org/repositories/Virtualization:containers/openSUSE_Tumbleweed/Virtualization:containers.repo
            sudo zypper refresh
            install_package docker
            ;;
    esac
fi

# Authenticate with GitHub
if gh auth status &>/dev/null; then
    echo "Already authenticated with GitHub."
else
    echo "Authenticating with GitHub..."
    gh auth login
fi

# Create a 'git' directory if it doesn't exist
mkdir -p "$GIT_DIR"

# Clone a private repository
if [ -d "$DEST_DIR" ]; then
    echo "Repository already cloned in $DEST_DIR. Pulling latest changes..."
    cd "$DEST_DIR" && git pull
else
    echo "Cloning private repository..."
    git clone "$REPO_URL" "$DEST_DIR"
fi

echo "Setup complete. All tools are installed, authenticated, and the repository is cloned."

