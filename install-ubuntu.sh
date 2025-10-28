#!/bin/bash

# Smart Attendance Management System - Ubuntu Installation Script
# This script automates the installation process on Ubuntu systems

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Function to check Ubuntu version
check_ubuntu_version() {
    if ! command_exists lsb_release; then
        sudo apt update
        sudo apt install -y lsb-release
    fi
    
    local version=$(lsb_release -rs)
    local major_version=$(echo $version | cut -d. -f1)
    
    if [[ $major_version -lt 20 ]]; then
        print_warning "This script is designed for Ubuntu 20.04+. You're running Ubuntu $version"
        read -p "Do you want to continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to install Docker
install_docker() {
    print_status "Installing Docker and Docker Compose..."
    
    # Update system packages
    print_status "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    
    # Install required packages
    print_status "Installing required packages..."
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common
    
    # Add Docker's official GPG key
    print_status "Adding Docker's official GPG key..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    print_status "Adding Docker repository..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    print_status "Installing Docker..."
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Add user to docker group
    print_status "Adding user to docker group..."
    sudo usermod -aG docker $USER
    
    # Enable Docker to start on boot
    print_status "Enabling Docker to start on boot..."
    sudo systemctl enable docker
    sudo systemctl start docker
    
    # Verify installation
    print_status "Verifying Docker installation..."
    if command_exists docker; then
        docker --version
        print_success "Docker installed successfully!"
    else
        print_error "Docker installation failed!"
        exit 1
    fi
    
    if command_exists docker; then
        docker compose version
        print_success "Docker Compose installed successfully!"
    else
        print_error "Docker Compose installation failed!"
        exit 1
    fi
}

# Function to install Git
install_git() {
    if command_exists git; then
        print_success "Git is already installed: $(git --version)"
    else
        print_status "Installing Git..."
        sudo apt install -y git
        print_success "Git installed successfully!"
    fi
}

# Function to clone repository
clone_repository() {
    local repo_url="https://github.com/zawnaing-2024/Smart_Attendance.git"
    local project_dir="Smart_Attendance"
    
    if [[ -d "$project_dir" ]]; then
        print_warning "Directory $project_dir already exists."
        read -p "Do you want to remove it and clone fresh? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$project_dir"
            print_status "Removed existing directory."
        else
            print_status "Using existing directory."
            return
        fi
    fi
    
    print_status "Cloning repository..."
    git clone "$repo_url" "$project_dir"
    cd "$project_dir"
    
    # Make scripts executable
    print_status "Making scripts executable..."
    chmod +x setup_local.sh update.sh update_faces.sh deploy-ubuntu.sh
    
    print_success "Repository cloned successfully!"
}

# Function to configure environment
configure_environment() {
    print_status "Configuring environment..."
    
    if [[ -f ".env" ]]; then
        print_warning "Environment file .env already exists."
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Using existing .env file."
            return
        fi
    fi
    
    if [[ -f "env.example" ]]; then
        cp env.example .env
        print_success "Environment file created from template."
    else
        print_warning "env.example not found. Creating basic .env file..."
        cat > .env << EOF
# Database Configuration
DB_HOST=db
DB_USER=attendance_user
DB_PASS=attendance_pass
DB_NAME=smart_attendance

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379

# Application Configuration
APP_ENV=production
APP_DEBUG=false
EOF
        print_success "Basic .env file created."
    fi
}

# Function to build and start services
start_services() {
    print_status "Building and starting Docker services..."
    
    # Build and start all services
    docker compose up -d --build
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 10
    
    # Check service status
    print_status "Checking service status..."
    docker compose ps
    
    print_success "All services started successfully!"
}

# Function to display access information
display_access_info() {
    print_success "Installation completed successfully!"
    echo
    echo "=========================================="
    echo "🎉 Smart Attendance System is now running!"
    echo "=========================================="
    echo
    echo "Access URLs:"
    echo "• Main Portal: http://localhost:8080"
    echo "• Admin Portal: http://localhost:8080/login.php?user_type=admin"
    echo "• Teacher Portal: http://localhost:8080/login.php?user_type=teacher"
    echo "• Live View: http://localhost:8080/admin/live_view.php"
    echo "• Python Service: http://localhost:5001"
    echo
    echo "Default Login Credentials:"
    echo "• Admin: username: admin, password: password"
    echo "• Teacher: Create accounts through admin portal"
    echo
    echo "Useful Commands:"
    echo "• View logs: docker compose logs -f"
    echo "• Restart services: docker compose restart"
    echo "• Stop services: docker compose down"
    echo "• Update system: git pull && docker compose up -d --build"
    echo
    echo "For more information, see README.md"
}

# Function to check system requirements
check_system_requirements() {
    print_status "Checking system requirements..."
    
    # Check available memory
    local total_mem=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    if [[ $total_mem -lt 4000 ]]; then
        print_warning "System has less than 4GB RAM. Performance may be affected."
    else
        print_success "System memory: ${total_mem}MB"
    fi
    
    # Check available disk space
    local available_space=$(df -BG . | awk 'NR==2{print $4}' | sed 's/G//')
    if [[ $available_space -lt 20 ]]; then
        print_warning "Less than 20GB disk space available. Consider freeing up space."
    else
        print_success "Available disk space: ${available_space}GB"
    fi
    
    # Check CPU cores
    local cpu_cores=$(nproc)
    if [[ $cpu_cores -lt 2 ]]; then
        print_warning "System has less than 2 CPU cores. Performance may be affected."
    else
        print_success "CPU cores: $cpu_cores"
    fi
}

# Main installation function
main() {
    echo "=========================================="
    echo "Smart Attendance Management System"
    echo "Ubuntu Installation Script"
    echo "=========================================="
    echo
    
    # Pre-installation checks
    check_root
    check_ubuntu_version
    check_system_requirements
    
    echo
    print_status "Starting installation process..."
    echo
    
    # Installation steps
    install_git
    install_docker
    
    echo
    print_warning "You need to log out and log back in for Docker group changes to take effect."
    print_warning "After logging back in, run this script again to continue."
    echo
    
    read -p "Have you logged out and back in? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Please log out and log back in, then run this script again."
        exit 0
    fi
    
    # Verify Docker is working
    if ! docker ps >/dev/null 2>&1; then
        print_error "Docker is not working properly. Please check your installation."
        exit 1
    fi
    
    clone_repository
    configure_environment
    start_services
    display_access_info
}

# Run main function
main "$@"
