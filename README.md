# Initial Setup Script

## Purpose
This script automates the installation and setup of essential tools for deployment, including:

- **Docker Engine** for containerized development
- **Git** for version control
- **GitHub CLI (gh)** for interacting with GitHub
- **Authentication with GitHub** to access private repositories
- **Cloning a private repository** into a dedicated `git` folder

By running this script, you ensure that all necessary dependencies are installed and updated, allowing you to start working with your repository immediately.

## Repository Reference
The script clones the following repository:

- **GitHub Repository:** `git@github.com:ngroegli/ansible-infrastructure.git`

## Supported Operating Systems
This script supports the following Linux distributions:

- Ubuntu
- Debian
- Raspberry Pi OS
- Fedora
- CentOS
- RHEL
- Arch Linux
- Manjaro
- openSUSE

## Installation
To download, make the script executable, and run it, use the following command:

```bash
wget https://raw.githubusercontent.com/ngroegli/linux-initial-base-setup/main/initial_setup.sh -O initial_setup.sh && chmod +x initial_setup.sh && sudo ./initial_setup.sh
```

Ensure you have the necessary permissions to run the script and authenticate with GitHub when prompted.

## Notes
- The script will check for existing installations and update them if necessary.
- If GitHub authentication is required, you will be prompted to log in.
- The repository will be cloned into `~/git/ansible-infrastructure`.

## Troubleshooting
If you encounter any issues, check the script output for error messages and ensure you have an active internet connection.

For more details, visit the official documentation for:
- [Docker Engine](https://docs.docker.com/engine/install/)
- [GitHub CLI](https://cli.github.com/)
- [Git](https://git-scm.com/doc)
- [Private Github Repository for Ansible](https://github.com/ngroegli/ansible-infrastructure)

