#!/bin/bash

# Smart Attendance System - Production Deployment Script for Ubuntu
# This script sets up the Smart Attendance System on a fresh Ubuntu server

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Function to update system packages
update_system() {
    print_status "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    print_success "System packages updated"
}

# Function to install Docker
install_docker() {
    print_status "Installing Docker..."
    
    # Remove old versions
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Install prerequisites
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    print_success "Docker installed successfully"
}

# Function to install Git
install_git() {
    print_status "Installing Git..."
    sudo apt install -y git
    print_success "Git installed successfully"
}

# Function to configure firewall
configure_firewall() {
    print_status "Configuring firewall..."
    
    # Install UFW if not present
    sudo apt install -y ufw
    
    # Configure firewall rules
    sudo ufw allow ssh
    sudo ufw allow 8080/tcp  # Web portal
    sudo ufw allow 5001/tcp  # Face detection service
    sudo ufw allow 3306/tcp  # MySQL (if needed externally)
    sudo ufw allow 6379/tcp  # Redis (if needed externally)
    
    # Enable firewall
    sudo ufw --force enable
    
    print_success "Firewall configured"
}

# Function to clone repository
clone_repository() {
    print_status "Cloning Smart Attendance repository..."
    
    if [ -d "Smart_Attendance" ]; then
        print_warning "Smart_Attendance directory already exists. Removing it..."
        rm -rf Smart_Attendance
    fi
    
    git clone https://github.com/zawnaing-2024/Smart_Attendance.git
    cd Smart_Attendance
    
    print_success "Repository cloned successfully"
}

# Function to start the application
start_application() {
    print_status "Starting Smart Attendance System..."
    
    # Start the application
    docker compose up -d
    
    # Wait for services to start
    print_status "Waiting for services to start..."
    sleep 30
    
    # Check if services are running
    if docker compose ps | grep -q "Up"; then
        print_success "Smart Attendance System started successfully!"
    else
        print_error "Some services failed to start. Check logs with: docker compose logs"
        exit 1
    fi
}

# Function to verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    # Check web service
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|403"; then
        print_success "Web service is responding"
    else
        print_warning "Web service is not responding"
    fi
    
    # Check face detection service
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:5001 | grep -q "200"; then
        print_success "Face detection service is responding"
    else
        print_warning "Face detection service is not responding"
    fi
    
    # Check database
    if docker compose exec db mysqladmin ping -h localhost -u attendance_user -pattendance_pass > /dev/null 2>&1; then
        print_success "Database is responding"
    else
        print_warning "Database is not responding"
    fi
}

# Function to show final information
show_final_info() {
    echo ""
    print_success "Smart Attendance System Installation Complete!"
    echo "=================================================="
    echo ""
    echo "Access URLs:"
    echo "  Main Portal: http://$(hostname -I | awk '{print $1}'):8080"
    echo "  Live View: http://$(hostname -I | awk '{print $1}'):5001"
    echo ""
    echo "Local Access:"
    echo "  Main Portal: http://localhost:8080"
    echo "  Live View: http://localhost:5001"
    echo ""
    echo "Management Commands:"
    echo "  View status: docker compose ps"
    echo "  View logs: docker compose logs"
    echo "  Restart: docker compose restart"
    echo "  Stop: docker compose down"
    echo "  Start: docker compose up -d"
    echo ""
    echo "Update Script:"
    echo "  Use ./update.sh for easy updates"
    echo ""
    print_warning "Important: You may need to log out and log back in for Docker group changes to take effect."
    print_warning "If you encounter permission issues, run: newgrp docker"
}

# Function to create systemd service (optional)
create_systemd_service() {
    print_status "Creating systemd service for auto-start..."
    
    sudo tee /etc/systemd/system/smart-attendance.service > /dev/null <<EOF
[Unit]
Description=Smart Attendance System
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$(pwd)
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable smart-attendance.service
    
    print_success "Systemd service created and enabled"
}

# Main installation function
main() {
    print_status "Starting Smart Attendance System installation on Ubuntu..."
    echo ""
    
    check_root
    update_system
    install_docker
    install_git
    configure_firewall
    clone_repository
    start_application
    verify_installation
    create_systemd_service
    show_final_info
    
    print_success "Installation completed successfully!"
}

# Run main function
main "$@"
