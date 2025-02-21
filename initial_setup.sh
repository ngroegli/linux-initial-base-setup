#!/bin/bash

set -e  # Exit on error

# Global variables
GITHUB_USERNAME="ngroegli"
ANSIBLE_REPO_NAME="ansible-infrastructure"
GIT_DIR="$HOME/git"
REPO_URL="git@github.com:$GITHUB_USERNAME/$ANSIBLE_REPO_NAME.git"
DEST_DIR="$GIT_DIR/$ANSIBLE_REPO_NAME"

echo "Starting initial setup..."

# Update package lists
echo "Updating package lists..."
sudo apt update -y
sudo apt upgrade -y

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Install or update Git
if command_exists git; then
    echo "Git is already installed. Updating..."
    sudo apt upgrade -y git
else
    echo "Installing Git..."
    sudo apt install -y git
fi

# Install or update GitHub CLI (gh)
if command_exists gh; then
    echo "GitHub CLI (gh) is already installed. Updating..."
    sudo apt upgrade -y gh
else
    echo "Installing GitHub CLI (gh)..."
    type -p curl >/dev/null || sudo apt install -y curl
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update -y
    sudo apt install -y gh
fi

# Install or update Docker Desktop
if command_exists docker; then
    echo "Docker is already installed. Updating..."
    sudo apt upgrade -y docker-desktop
else
    echo "Installing Docker Desktop..."
    curl -fsSL https://desktop.docker.com/linux/main/amd64/docker-desktop-$(uname -m).deb -o docker-desktop.deb
    sudo apt install -y ./docker-desktop.deb
    rm docker-desktop.deb
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
