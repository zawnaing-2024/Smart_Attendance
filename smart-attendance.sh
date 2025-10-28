#!/bin/bash

# Smart Attendance Management System - Unified Deployment Script
# Handles installation, updates, and all deployment operations

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/zawnaing-2024/Smart_Attendance.git"
PROJECT_DIR="Smart_Attendance"
BACKUP_DIR="backups"

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

# Function to show usage
show_usage() {
    echo "Smart Attendance Management System - Unified Deployment Script"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  install     - Fresh installation (Ubuntu/Docker setup)"
    echo "  update      - Update existing installation"
    echo "  start       - Start all services"
    echo "  stop        - Stop all services"
    echo "  restart     - Restart all services"
    echo "  status      - Show service status"
    echo "  logs        - Show service logs"
    echo "  backup      - Backup database"
    echo "  restore     - Restore database from backup"
    echo "  fix-docker  - Fix Docker permission issues"
    echo "  fix-build   - Fix Docker build issues"
    echo "  clean       - Clean up containers and images"
    echo "  help        - Show this help message"
    echo
    echo "Examples:"
    echo "  $0 install    # Fresh installation"
    echo "  $0 update     # Update system"
    echo "  $0 restart    # Restart services"
    echo "  $0 logs       # View logs"
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

# Function to clone or update repository
setup_repository() {
    if [[ -d "$PROJECT_DIR" ]]; then
        print_status "Updating existing repository..."
        cd "$PROJECT_DIR"
        
        # Fix git ownership issues
        print_status "Fixing git ownership..."
        git config --global --add safe.directory "$(pwd)" 2>/dev/null || true
        sudo chown -R $USER:$USER . 2>/dev/null || true
        
        git pull origin main
        cd ..
    else
        print_status "Cloning repository..."
        git clone "$REPO_URL" "$PROJECT_DIR"
        
        # Fix ownership if cloned as root
        sudo chown -R $USER:$USER "$PROJECT_DIR" 2>/dev/null || true
    fi
    
    cd "$PROJECT_DIR"
    
    # Make scripts executable
    print_status "Making scripts executable..."
    chmod +x *.sh 2>/dev/null || true
    
    print_success "Repository setup completed!"
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

# Function to start services
start_services() {
    print_status "Starting Docker services..."
    
    # Try to build and start all services
    if docker compose up -d --build; then
        print_success "Services started successfully!"
    else
        print_warning "Initial build failed. Trying alternative approach..."
        
        # Try with no-cache build
        print_status "Trying with no-cache build..."
        if docker compose build --no-cache && docker compose up -d; then
            print_success "Services started with no-cache build!"
        else
            print_error "Build failed. Trying alternative Dockerfile..."
            
            # Try minimal Dockerfile first
            if [[ -f "Dockerfile.python.minimal" ]]; then
                print_status "Using minimal Dockerfile..."
                cp Dockerfile.python.minimal Dockerfile.python
                if docker compose build --no-cache && docker compose up -d; then
                    print_success "Services started with minimal Dockerfile!"
                else
                    print_error "Minimal Dockerfile failed. Trying alternative..."
                    if [[ -f "Dockerfile.python.backup" ]]; then
                        cp Dockerfile.python.backup Dockerfile.python
                        if docker compose build --no-cache && docker compose up -d; then
                            print_success "Services started with alternative Dockerfile!"
                        else
                            print_error "All build attempts failed. Please check the logs."
                            print_status "Run: docker compose logs face_detection"
                            exit 1
                        fi
                    else
                        print_error "All build attempts failed. Please check the logs."
                        print_status "Run: docker compose logs face_detection"
                        exit 1
                    fi
                fi
            elif [[ -f "Dockerfile.python.backup" ]]; then
                print_status "Using alternative Dockerfile..."
                cp Dockerfile.python.backup Dockerfile.python
                if docker compose build --no-cache && docker compose up -d; then
                    print_success "Services started with alternative Dockerfile!"
                else
                    print_error "All build attempts failed. Please check the logs."
                    print_status "Run: docker compose logs face_detection"
                    exit 1
                fi
            else
                print_error "Build failed and no alternative Dockerfile found."
                print_status "Please check the logs: docker compose logs face_detection"
                exit 1
            fi
        fi
    fi
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 10
    
    # Check service status
    print_status "Checking service status..."
    docker compose ps
}

# Function to stop services
stop_services() {
    print_status "Stopping Docker services..."
    docker compose down
    print_success "All services stopped!"
}

# Function to restart services
restart_services() {
    print_status "Restarting Docker services..."
    docker compose restart
    print_success "All services restarted!"
}

# Function to show service status
show_status() {
    print_status "Service Status:"
    docker compose ps
    echo
    print_status "Resource Usage:"
    docker stats --no-stream
}

# Function to show logs
show_logs() {
    print_status "Showing service logs (Press Ctrl+C to exit)..."
    docker compose logs -f
}

# Function to backup database
backup_database() {
    print_status "Creating database backup..."
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Create backup with timestamp
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/backup_$timestamp.sql"
    
    docker exec smartattendance-db-1 mysqldump -u attendance_user -pattendance_pass smart_attendance > "$backup_file"
    
    if [[ -f "$backup_file" ]]; then
        print_success "Database backup created: $backup_file"
    else
        print_error "Database backup failed!"
        exit 1
    fi
}

# Function to restore database
restore_database() {
    print_status "Available backups:"
    ls -la "$BACKUP_DIR"/*.sql 2>/dev/null || {
        print_error "No backup files found in $BACKUP_DIR"
        exit 1
    }
    
    echo
    read -p "Enter backup filename (without path): " backup_file
    
    if [[ ! -f "$BACKUP_DIR/$backup_file" ]]; then
        print_error "Backup file not found: $BACKUP_DIR/$backup_file"
        exit 1
    fi
    
    print_warning "This will overwrite the current database. Are you sure?"
    read -p "Type 'yes' to continue: " confirm
    
    if [[ $confirm == "yes" ]]; then
        print_status "Restoring database from $backup_file..."
        docker exec -i smartattendance-db-1 mysql -u attendance_user -pattendance_pass smart_attendance < "$BACKUP_DIR/$backup_file"
        print_success "Database restored successfully!"
    else
        print_status "Database restore cancelled."
    fi
}

# Function to fix Docker permissions
fix_docker_permissions() {
    print_status "Fixing Docker permissions..."
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    # Check Docker daemon status
    if sudo systemctl is-active --quiet docker; then
        print_success "Docker daemon is running"
    else
        print_warning "Starting Docker daemon..."
        sudo systemctl start docker
        sudo systemctl enable docker
    fi
    
    # Test Docker without sudo
    print_status "Testing Docker permissions..."
    if docker ps >/dev/null 2>&1; then
        print_success "Docker is working properly!"
    else
        print_warning "Docker permissions not yet active"
        print_status "You need to log out and log back in, or run: newgrp docker"
        echo
        read -p "Do you want to activate docker group now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Activating docker group..."
            newgrp docker
        else
            print_status "Please log out and log back in, then run: docker ps"
        fi
    fi
}

# Function to fix Docker build issues
fix_docker_build() {
    print_status "Fixing Docker build issues..."
    
    cd "$PROJECT_DIR"
    
    print_status "Cleaning up Docker resources..."
    docker compose down -v --remove-orphans
    docker system prune -f
    
    print_status "Trying minimal Dockerfile..."
    if [[ -f "Dockerfile.python.minimal" ]]; then
        cp Dockerfile.python.minimal Dockerfile.python
        print_success "Using minimal Dockerfile"
    elif [[ -f "Dockerfile.python.backup" ]]; then
        cp Dockerfile.python.backup Dockerfile.python
        print_success "Using alternative Dockerfile"
    else
        print_warning "No alternative Dockerfile found"
    fi
    
    print_status "Attempting rebuild with no cache..."
    if docker compose build --no-cache; then
        print_success "Build successful!"
        print_status "Starting services..."
        docker compose up -d
    else
        print_error "Build still failing. Trying without face recognition..."
        print_status "Creating simplified version without face recognition..."
        
        # Create a simplified requirements.txt without face-recognition
        cat > requirements.txt << EOF
numpy==1.24.3
Pillow==10.0.1
Flask==2.3.3
redis==4.6.0
pymysql==1.1.0
requests==2.31.0
python-dotenv==1.0.0
opencv-python-headless==4.8.1.78
EOF
        
        print_status "Rebuilding with simplified requirements..."
        if docker compose build --no-cache && docker compose up -d; then
            print_success "Build successful with simplified version!"
            print_warning "Note: Face recognition is disabled. You can enable it later."
        else
            print_error "All build attempts failed. Check logs: docker compose logs face_detection"
            exit 1
        fi
    fi
}

# Function to clean up
clean_up() {
    print_warning "This will remove all containers, images, and volumes. Are you sure?"
    read -p "Type 'yes' to continue: " confirm
    
    if [[ $confirm == "yes" ]]; then
        print_status "Cleaning up Docker resources..."
        docker compose down -v --remove-orphans
        docker system prune -a -f
        print_success "Cleanup completed!"
    else
        print_status "Cleanup cancelled."
    fi
}

# Function to display access information
display_access_info() {
    print_success "Smart Attendance System is now running!"
    echo
    echo "=========================================="
    echo "🎉 Access URLs:"
    echo "=========================================="
    echo "• Main Portal: http://localhost:8080"
    echo "• Admin Portal: http://localhost:8080/login.php?user_type=admin"
    echo "• Teacher Portal: http://localhost:8080/login.php?user_type=teacher"
    echo "• Live View: http://localhost:8080/admin/live_view.php"
    echo "• Python Service: http://localhost:5001"
    echo
    echo "Default Login Credentials:"
    echo "• Admin: username: admin, password: password"
    echo
    echo "Useful Commands:"
    echo "• View logs: $0 logs"
    echo "• Restart services: $0 restart"
    echo "• Stop services: $0 stop"
    echo "• Update system: $0 update"
}

# Function to perform fresh installation
install_system() {
    echo "=========================================="
    echo "Smart Attendance Management System"
    echo "Fresh Installation"
    echo "=========================================="
    echo
    
    check_root
    check_system_requirements
    
    print_status "Starting fresh installation..."
    echo
    
    install_git
    install_docker
    
    echo
    print_warning "You need to log out and log back in for Docker group changes to take effect."
    print_warning "After logging back in, run: $0 install-continue"
    echo
    
    read -p "Have you logged out and back in? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Please log out and log back in, then run: $0 install-continue"
        exit 0
    fi
    
    # Verify Docker is working
    if ! docker ps >/dev/null 2>&1; then
        print_error "Docker is not working properly. Please check your installation."
        exit 1
    fi
    
    setup_repository
    configure_environment
    start_services
    display_access_info
}

# Function to continue installation after Docker setup
install_continue() {
    print_status "Continuing installation..."
    
    # Verify Docker is working
    if ! docker ps >/dev/null 2>&1; then
        print_error "Docker is not working properly. Please check your installation."
        exit 1
    fi
    
    setup_repository
    configure_environment
    start_services
    display_access_info
}

# Function to update system
update_system() {
    print_status "Updating Smart Attendance System..."
    
    # Check if project directory exists
    if [[ ! -d "$PROJECT_DIR" ]]; then
        print_error "Project directory not found. Please run installation first."
        exit 1
    fi
    
    cd "$PROJECT_DIR"
    
    # Create backup before update
    print_status "Creating backup before update..."
    mkdir -p "$BACKUP_DIR"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/backup_before_update_$timestamp.sql"
    docker exec smartattendance-db-1 mysqldump -u attendance_user -pattendance_pass smart_attendance > "$backup_file" 2>/dev/null || true
    
    # Pull latest changes
    print_status "Pulling latest changes..."
    git pull origin main
    
    # Rebuild and restart services
    print_status "Rebuilding and restarting services..."
    docker compose down
    docker compose up -d --build
    
    print_success "System updated successfully!"
    print_status "Backup created: $backup_file"
}

# Main function
main() {
    case "${1:-help}" in
        "install")
            install_system
            ;;
        "install-continue")
            install_continue
            ;;
        "update")
            update_system
            ;;
        "start")
            cd "$PROJECT_DIR" && start_services
            ;;
        "stop")
            cd "$PROJECT_DIR" && stop_services
            ;;
        "restart")
            cd "$PROJECT_DIR" && restart_services
            ;;
        "status")
            cd "$PROJECT_DIR" && show_status
            ;;
        "logs")
            cd "$PROJECT_DIR" && show_logs
            ;;
        "backup")
            cd "$PROJECT_DIR" && backup_database
            ;;
        "restore")
            cd "$PROJECT_DIR" && restore_database
            ;;
        "fix-docker")
            fix_docker_permissions
            ;;
        "fix-build")
            fix_docker_build
            ;;
        "clean")
            cd "$PROJECT_DIR" && clean_up
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            print_error "Unknown command: $1"
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
