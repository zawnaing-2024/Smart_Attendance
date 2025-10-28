#!/bin/bash

# Quick fix for Docker permission issues
# Run this script to fix the "permission denied" error

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Fixing Docker permission issues..."

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
    exit 1
fi

# Fix Docker permissions
print_status "Adding user to docker group..."
sudo usermod -aG docker $USER

print_status "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

print_status "Fixing Docker socket permissions..."
sudo chmod 666 /var/run/docker.sock 2>/dev/null || true

print_status "Restarting Docker service..."
sudo systemctl restart docker

print_status "Waiting for Docker to be ready..."
sleep 5

# Test Docker access
print_status "Testing Docker access..."
if docker ps > /dev/null 2>&1; then
    print_success "Docker permissions fixed!"
    print_success "You can now continue with the installation!"
    echo ""
    echo "Run this command to continue:"
    echo "./complete-cloud-setup.sh"
else
    print_warning "Docker permissions still not working."
    print_status "You need to log out and log back in, or run: newgrp docker"
    print_status "Then run this script again."
    exit 1
fi
