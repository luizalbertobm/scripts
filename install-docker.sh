#!/bin/bash

# Define a function to output status messages
echo_status() {
    echo "==> $1"
}

# Stopping Docker if it's running
echo_status "Stopping Docker service..."
sudo systemctl stop docker

# Uninstall Docker packages
echo_status "Uninstalling existing Docker packages..."
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io

# Remove Docker's dependencies
echo_status "Removing Docker's dependencies..."
sudo apt-get autoremove -y --purge

# Install required packages
echo_status "Installing required packages..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Download and install Docker
echo_status "Downloading and installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ./get-docker.sh

# Add current user to the Docker group
echo_status "Adding the current user to the Docker group..."
sudo usermod -aG docker $USER

# Start Docker service
echo_status "Starting Docker service..."
sudo service docker start

# Enable Docker to start on boot
echo_status "Enabling Docker to start on boot..."
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

# Test Docker installation
echo_status "Testing Docker installation..."
docker run hello-world

# Install Docker Compose
echo_status "Installing Docker Compose..."
DOCKER_COMPOSE_VERSION="2.23.3"
curl -SL "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo snap install docker

# Check installed versions
echo_status "Checking installed versions..."
echo "Docker version: $(docker --version)"
echo "Docker Compose version: $(docker-compose --version)"

echo_status "Docker and Docker Compose installed successfully."
echo "Please log out and log back in for the changes to take full effect."
