#!/bin/bash

# Fix Docker permission issues on cloud VM
# This script fixes the "permission denied" error when accessing Docker daemon

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}==========================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}==========================================${NC}"
}

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

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

print_header "Docker Permission Fix for Cloud VM"
echo "This script will fix Docker permission issues"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
    exit 1
fi

# Step 1: Check Docker status
print_step "1. Checking Docker status..."
if ! systemctl is-active --quiet docker; then
    print_status "Docker is not running, starting it..."
    sudo systemctl start docker
    sudo systemctl enable docker
else
    print_success "Docker is running!"
fi

# Step 2: Add user to docker group
print_step "2. Adding user to docker group..."
if ! groups $USER | grep -q docker; then
    print_status "Adding user $USER to docker group..."
    sudo usermod -aG docker $USER
    print_success "User added to docker group!"
else
    print_success "User is already in docker group!"
fi

# Step 3: Fix Docker socket permissions
print_step "3. Fixing Docker socket permissions..."
sudo chmod 666 /var/run/docker.sock 2>/dev/null || true
print_success "Docker socket permissions fixed!"

# Step 4: Restart Docker service
print_step "4. Restarting Docker service..."
sudo systemctl restart docker
print_success "Docker service restarted!"

# Step 5: Wait for Docker to be ready
print_step "5. Waiting for Docker to be ready..."
sleep 5

# Step 6: Test Docker access
print_step "6. Testing Docker access..."
if docker ps > /dev/null 2>&1; then
    print_success "Docker access is working!"
else
    print_warning "Docker access still not working. You may need to log out and log back in."
    print_status "Alternatively, try running: newgrp docker"
    print_status "Or restart your session completely."
fi

# Step 7: Show current user groups
print_step "7. Current user groups:"
groups $USER

# Step 8: Show Docker info
print_step "8. Docker information:"
docker --version
docker compose version

# Step 9: Test Docker Compose
print_step "9. Testing Docker Compose..."
if docker compose version > /dev/null 2>&1; then
    print_success "Docker Compose is working!"
else
    print_warning "Docker Compose not working. Installing..."
    sudo apt update
    sudo apt install -y docker-compose-plugin
fi

print_header "Docker Permission Fix Complete!"
echo ""
echo "If Docker is still not working:"
echo "1. Log out and log back in"
echo "2. Or run: newgrp docker"
echo "3. Or restart your session completely"
echo ""
echo "Then you can continue with the installation:"
echo "./complete-cloud-setup.sh"
echo ""
print_success "Docker permission fix completed!"
