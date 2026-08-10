#!/bin/bash

set -e  # Exit on error

# Use the invoking user's context when the script is launched with sudo.
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    TARGET_USER="$SUDO_USER"
    TARGET_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
else
    TARGET_USER="$USER"
    TARGET_HOME="$HOME"
fi

# Global variables
GITHUB_USERNAME="ngroegli"
REPO_NAME="ansible-infrastructure"
GIT_DIR="$TARGET_HOME/Git"
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
    local packages=("$@")
    case "$OS" in
        ubuntu|debian|raspbian)
            sudo apt install -y "${packages[@]}"
            ;;
        fedora|centos|rhel)
            sudo dnf install -y "${packages[@]}"
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm "${packages[@]}"
            ;;
        opensuse*)
            sudo zypper install -y "${packages[@]}"
            ;;
    esac
}

configure_docker_repo() {
    case "$OS" in
        ubuntu|debian|raspbian)
            echo "Configuring Docker repository..."

            local docker_repo_distro
            if [ "$OS" = "ubuntu" ]; then
                docker_repo_distro="ubuntu"
            else
                docker_repo_distro="debian"
            fi

            # Docker's repository setup requires these packages first.
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl

            sudo install -m 0755 -d /etc/apt/keyrings

            # Install Docker's official GPG key.
            sudo curl -fsSL \
                "https://download.docker.com/linux/${docker_repo_distro}/gpg" \
                -o /etc/apt/keyrings/docker.asc

            sudo chmod a+r /etc/apt/keyrings/docker.asc

            # Use distro codename and architecture in the standard Docker repo entry.
            local codename
            codename="${VERSION_CODENAME}"
            if [ -z "$codename" ] && command -v lsb_release >/dev/null 2>&1; then
                codename="$(lsb_release -cs)"
            fi

            if [ -z "$codename" ]; then
                echo "Unable to determine distro codename for Docker repository."
                exit 1
            fi

            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${docker_repo_distro} ${codename} stable
EOF
            ;;

        fedora|centos|rhel)
            sudo dnf install -y dnf-plugins-core
            sudo dnf config-manager \
                --add-repo \
                https://download.docker.com/linux/fedora/docker-ce.repo
            ;;

        arch|manjaro)
            # Docker is available directly from the Arch repositories.
            ;;

        opensuse*)
            sudo zypper addrepo \
                https://download.opensuse.org/repositories/Virtualization:containers/openSUSE_Tumbleweed/Virtualization:containers.repo
            sudo zypper refresh
            ;;

        *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

update_packages

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

run_as_target_user() {
    if [ "$(id -un)" = "$TARGET_USER" ]; then
        "$@"
    else
        sudo -u "$TARGET_USER" -H "$@"
    fi
}

# Ensure base network tooling exists before any URL-based setup.
if ! command_exists curl; then
    echo "Installing curl..."
    install_package curl
fi

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
            install_package apt-transport-https ca-certificates curl gnupg lsb-release
            configure_docker_repo
            sudo apt update -y
            install_package docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
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
if run_as_target_user gh auth status &>/dev/null; then
    echo "Already authenticated with GitHub."
else
    echo "Authenticating with GitHub..."
    run_as_target_user gh auth login
fi

# Create a 'git' directory if it doesn't exist
mkdir -p "$GIT_DIR"

# Clone a private repository
if [ -d "$DEST_DIR" ]; then
    echo "Repository already cloned in $DEST_DIR. Pulling latest changes..."
    run_as_target_user bash -lc "cd '$DEST_DIR' && git pull"
else
    echo "Cloning private repository..."
    run_as_target_user gh repo clone "$GITHUB_USERNAME/$REPO_NAME" "$DEST_DIR"
fi

echo "Setup complete. All tools are installed, authenticated, and the repository is cloned."
