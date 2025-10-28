#!/bin/bash

# Smart Attendance Management System - Unified Management Script
# This is the ONLY script you need for all operations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

show_help() {
    print_header "Smart Attendance Management System"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install     - Complete installation on cloud VM"
    echo "  start       - Start all services"
    echo "  stop        - Stop all services"
    echo "  restart     - Restart all services"
    echo "  status      - Show service status"
    echo "  logs        - Show service logs"
    echo "  fix         - Fix common issues"
    echo "  update      - Update system"
    echo "  backup      - Backup database"
    echo "  restore     - Restore database"
    echo "  clean       - Clean up Docker resources"
    echo "  help        - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 install    # Install everything"
    echo "  $0 start      # Start services"
    echo "  $0 status     # Check status"
    echo "  $0 fix        # Fix issues"
    echo ""
}

# Check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Install Docker
install_docker() {
    print_step "Installing Docker..."
    if ! command -v docker &> /dev/null; then
        # Remove old Docker versions
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
        
        print_success "Docker installed!"
    else
        print_success "Docker already installed!"
    fi
}

# Fix Docker permissions
fix_docker_permissions() {
    print_step "Fixing Docker permissions..."
    if ! docker ps > /dev/null 2>&1; then
        print_status "Docker permission issue detected. Fixing..."
        
        # Start Docker service
        sudo systemctl start docker
        sudo systemctl enable docker
        
        # Fix Docker socket permissions
        sudo chmod 666 /var/run/docker.sock 2>/dev/null || true
        
        # Restart Docker service
        sudo systemctl restart docker
        
        # Wait for Docker to be ready
        sleep 5
        
        # Test Docker access
        if docker ps > /dev/null 2>&1; then
            print_success "Docker permissions fixed!"
        else
            print_warning "Docker permissions still not working. You may need to log out and log back in."
            print_status "Alternatively, try running: newgrp docker"
            print_status "Or restart your session completely."
            print_status "Then run this script again."
            exit 1
        fi
    else
        print_success "Docker permissions are working!"
    fi
}

# Setup repository
setup_repository() {
    print_step "Setting up repository..."
    if [ -d "Smart_Attendance" ]; then
        print_warning "Smart_Attendance directory already exists. Updating..."
        cd Smart_Attendance
        git pull origin main
    else
        git clone https://github.com/zawnaing-2024/Smart_Attendance.git
        cd Smart_Attendance
    fi
    
    # Fix git ownership
    git config --global --add safe.directory "$(pwd)"
    sudo chown -R $USER:$USER .
    
    print_success "Repository setup complete!"
}

# Build and start services
build_and_start() {
    print_step "Building and starting services..."
    print_status "This may take several minutes as packages are downloaded and installed..."
    
    # Build all services
    docker compose build --no-cache
    
    # Start all services
    docker compose up -d
    
    print_success "Services built and started!"
}

# Wait for services
wait_for_services() {
    print_step "Waiting for services to be ready..."
    print_status "Waiting for package installation and service startup..."
    sleep 60
}

# Fix database issues
fix_database() {
    print_step "Fixing database issues..."
    
    # Drop and recreate all tables with proper structure
    print_status "Recreating all tables with proper structure..."
    
    # Drop all tables
    docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; 
    DROP TABLE IF EXISTS detection_schedule;
    DROP TABLE IF EXISTS attendance;
    DROP TABLE IF EXISTS cameras;
    DROP TABLE IF EXISTS students;
    DROP TABLE IF EXISTS teachers;
    DROP TABLE IF EXISTS admin_users;
    DROP TABLE IF EXISTS grades;
    DROP TABLE IF EXISTS system_settings;
    DROP TABLE IF EXISTS sms_config;" 2>/dev/null

    # Create all tables with proper structure
    print_status "Creating all tables..."
    docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; 
    CREATE TABLE grades (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(50) NOT NULL,
        description TEXT,
        level INT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        is_active BOOLEAN DEFAULT TRUE,
        UNIQUE KEY unique_grade_level (name, level)
    );
    
    CREATE TABLE admin_users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        full_name VARCHAR(100) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        is_active BOOLEAN DEFAULT TRUE
    );
    
    CREATE TABLE teachers (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        position VARCHAR(100) NOT NULL,
        full_name VARCHAR(100) NOT NULL,
        phone VARCHAR(20),
        grade_id INT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        is_active BOOLEAN DEFAULT TRUE,
        FOREIGN KEY (grade_id) REFERENCES grades(id) ON DELETE SET NULL
    );
    
    CREATE TABLE students (
        id INT AUTO_INCREMENT PRIMARY KEY,
        roll_number VARCHAR(20) UNIQUE NOT NULL,
        name VARCHAR(100) NOT NULL,
        grade VARCHAR(20) NOT NULL,
        class VARCHAR(20),
        parent_name VARCHAR(100),
        parent_phone VARCHAR(20),
        parent_email VARCHAR(100),
        face_encoding TEXT,
        face_image_path VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        is_active BOOLEAN DEFAULT TRUE
    );
    
    CREATE TABLE cameras (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        rtsp_url VARCHAR(500) NOT NULL,
        username VARCHAR(100),
        password VARCHAR(255),
        location VARCHAR(200),
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    );
    
    CREATE TABLE attendance (
        id INT AUTO_INCREMENT PRIMARY KEY,
        student_id INT NOT NULL,
        camera_id INT NOT NULL,
        attendance_type ENUM('entry', 'exit') NOT NULL,
        detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        confidence_score DECIMAL(5,2),
        image_path VARCHAR(255),
        status ENUM('pending', 'confirmed', 'rejected') DEFAULT 'pending',
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
        FOREIGN KEY (camera_id) REFERENCES cameras(id) ON DELETE CASCADE,
        INDEX idx_student_date (student_id, detected_at),
        INDEX idx_camera_date (camera_id, detected_at)
    );
    
    CREATE TABLE system_settings (
        id INT AUTO_INCREMENT PRIMARY KEY,
        setting_key VARCHAR(100) UNIQUE NOT NULL,
        setting_value TEXT,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    );
    
    CREATE TABLE detection_schedule (
        id INT AUTO_INCREMENT PRIMARY KEY,
        camera_id INT,
        day_of_week ENUM('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday') NOT NULL,
        start_time TIME NOT NULL,
        end_time TIME NOT NULL,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (camera_id) REFERENCES cameras(id) ON DELETE CASCADE,
        UNIQUE KEY unique_camera_day (camera_id, day_of_week)
    );" 2>/dev/null

    # Insert default data
    print_status "Inserting default data..."
    docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; 
    INSERT INTO admin_users (username, password, email, full_name) VALUES 
    ('admin', '\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin@smartattendance.com', 'System Administrator');
    
    INSERT INTO grades (name, description, level) VALUES 
    ('Grade 1', 'First Grade - Basic level', 1),
    ('Grade 2', 'Second Grade - Elementary level', 2),
    ('Grade 3', 'Third Grade - Elementary level', 3),
    ('Grade 4', 'Fourth Grade - Elementary level', 4),
    ('Grade 5', 'Fifth Grade - Elementary level', 5);
    
    INSERT INTO system_settings (setting_key, setting_value, description) VALUES 
    ('attendance_threshold', '0.6', 'Face recognition confidence threshold'),
    ('sms_enabled', 'false', 'Enable SMS notifications'),
    ('auto_confirm_attendance', 'true', 'Automatically confirm attendance'),
    ('attendance_timeout', '30', 'Attendance confirmation timeout in minutes'),
    ('detection_enabled', 'true', 'Enable face detection system'),
    ('live_view_always_on', 'true', 'Keep camera live view always visible');" 2>/dev/null

    print_success "Database fixed!"
}

# Test services
test_services() {
    print_step "Testing services..."
    
    # Test web service
    print_status "Testing web service..."
    if curl -f http://localhost > /dev/null 2>&1; then
        print_success "Web service is working!"
    else
        print_warning "Web service not responding. Checking logs..."
        docker logs smart_attendance-web-1 | tail -10
    fi
    
    # Test Python service
    print_status "Testing Python service..."
    if curl -f http://localhost:5001 > /dev/null 2>&1; then
        print_success "Python service is working!"
    else
        print_warning "Python service not responding. Checking logs..."
        docker logs smart_attendance-face_detection-1 | tail -10
    fi
    
    # Test admin login
    print_status "Testing admin login..."
    login_response=$(curl -s -X POST -d "username=admin&password=password&user_type=admin" http://localhost/auth/login_process.php)
    if echo "$login_response" | grep -q "dashboard"; then
        print_success "Admin login is working!"
    else
        print_warning "Admin login not working. Response:"
        echo "$login_response" | head -3
    fi
}

# Show final status
show_final_status() {
    print_header "🎉 Installation Complete!"
    echo ""
    echo "Access URLs:"
    echo "• Main Portal: http://localhost"
    echo "• Admin Portal: http://localhost/login.php?user_type=admin"
    echo "• Teacher Portal: http://localhost/login.php?user_type=teacher"
    echo "• Python Service: http://localhost:5001"
    echo ""
    echo "Default Login Credentials:"
    echo "• Admin Username: admin"
    echo "• Admin Password: password"
    echo ""
    echo "Service Management:"
    echo "• Start services: $0 start"
    echo "• Stop services: $0 stop"
    echo "• Restart services: $0 restart"
    echo "• Check status: $0 status"
    echo "• View logs: $0 logs"
    echo "• Fix issues: $0 fix"
    echo ""
    print_status "All services running:"
    docker ps
}

# Main installation function
install_system() {
    print_header "Smart Attendance Management System - Installation"
    echo "This script will install everything on your cloud VM"
    echo ""
    
    check_root
    
    # Step 1: Update system
    print_step "1. Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y git curl wget net-tools telnet htop nano vim
    print_success "System updated!"
    
    # Step 2: Install Docker
    install_docker
    
    # Step 3: Fix Docker permissions
    fix_docker_permissions
    
    # Step 4: Setup repository
    setup_repository
    
    # Step 5: Stop any existing containers
    print_step "5. Stopping any existing containers..."
    docker compose down 2>/dev/null || true
    docker system prune -f 2>/dev/null || true
    print_success "Existing containers stopped!"
    
    # Step 6: Build and start services
    build_and_start
    
    # Step 7: Wait for services
    wait_for_services
    
    # Step 8: Fix database
    fix_database
    
    # Step 9: Restart web container
    print_step "9. Restarting web container..."
    docker compose restart web
    sleep 15
    
    # Step 10: Test services
    test_services
    
    # Step 11: Show final status
    show_final_status
}

# Start services
start_services() {
    print_header "Starting Services"
    docker compose up -d
    print_success "Services started!"
    docker ps
}

# Stop services
stop_services() {
    print_header "Stopping Services"
    docker compose down
    print_success "Services stopped!"
}

# Restart services
restart_services() {
    print_header "Restarting Services"
    docker compose restart
    print_success "Services restarted!"
    docker ps
}

# Show status
show_status() {
    print_header "Service Status"
    docker ps
    echo ""
    print_status "Port status:"
    netstat -tulpn | grep -E ":(80|3306|6379|5001)" 2>/dev/null || print_warning "netstat not available"
}

# Show logs
show_logs() {
    print_header "Service Logs"
    if [ -n "$2" ]; then
        docker compose logs "$2"
    else
        docker compose logs
    fi
}

# Fix issues
fix_issues() {
    print_header "Fixing Common Issues"
    fix_docker_permissions
    fix_database
    docker compose restart
    print_success "Issues fixed!"
}

# Update system
update_system() {
    print_header "Updating System"
    git pull origin main
    docker compose down
    docker compose build --no-cache
    docker compose up -d
    print_success "System updated!"
}

# Backup database
backup_database() {
    print_header "Backing Up Database"
    docker exec smart_attendance-db-1 mysqldump -u root -proot_password smart_attendance > backup_$(date +%Y%m%d_%H%M%S).sql
    print_success "Database backed up!"
}

# Restore database
restore_database() {
    print_header "Restoring Database"
    if [ -n "$2" ]; then
        docker exec -i smart_attendance-db-1 mysql -u root -proot_password smart_attendance < "$2"
        print_success "Database restored!"
    else
        print_error "Please specify backup file: $0 restore backup_file.sql"
    fi
}

# Clean up
clean_up() {
    print_header "Cleaning Up Docker Resources"
    docker compose down
    docker system prune -f
    docker volume prune -f
    print_success "Cleanup completed!"
}

# Main script logic
case "${1:-help}" in
    install)
        install_system
        ;;
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$@"
        ;;
    fix)
        fix_issues
        ;;
    update)
        update_system
        ;;
    backup)
        backup_database
        ;;
    restore)
        restore_database "$@"
        ;;
    clean)
        clean_up
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
