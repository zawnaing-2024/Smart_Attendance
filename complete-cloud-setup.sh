#!/bin/bash

# Complete Smart Attendance Management System Setup
# This script installs everything exactly like the local setup on cloud VM

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

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
    exit 1
fi

print_header "Smart Attendance Management System - Complete Cloud VM Setup"
echo "This script will install everything exactly like your local setup"
echo ""

# Step 1: Update system
print_step "1. Updating system packages..."
sudo apt update && sudo apt upgrade -y
print_success "System updated!"

# Step 2: Install Docker
print_step "2. Installing Docker..."
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

# Step 3: Install additional tools
print_step "3. Installing additional tools..."
sudo apt install -y git curl wget net-tools telnet htop nano vim
print_success "Additional tools installed!"

# Step 4: Clone repository
print_step "4. Cloning Smart Attendance repository..."
if [ -d "Smart_Attendance" ]; then
    print_warning "Smart_Attendance directory already exists. Updating..."
    cd Smart_Attendance
    git pull origin main
else
    git clone https://github.com/zawnaing-2024/Smart_Attendance.git
    cd Smart_Attendance
fi
print_success "Repository cloned/updated!"

# Step 5: Fix git ownership (if needed)
print_step "5. Fixing git ownership..."
git config --global --add safe.directory "$(pwd)"
sudo chown -R $USER:$USER .
print_success "Git ownership fixed!"

# Step 6: Make scripts executable
print_step "6. Making scripts executable..."
chmod +x *.sh
print_success "Scripts made executable!"

# Step 7: Stop any existing containers
print_step "7. Stopping any existing containers..."
docker compose down 2>/dev/null || true
docker system prune -f 2>/dev/null || true
print_success "Existing containers stopped!"

# Step 8: Build and start services
print_step "8. Building and starting services..."
print_status "This may take several minutes as packages are downloaded and installed..."

# Build all services
docker compose build --no-cache

# Start all services
docker compose up -d

print_success "Services built and started!"

# Step 9: Wait for services to be ready
print_step "9. Waiting for services to be ready..."
print_status "Waiting for package installation and service startup..."
sleep 60

# Step 10: Check service status
print_step "10. Checking service status..."
print_status "Container status:"
docker ps

# Step 11: Test services
print_step "11. Testing services..."

# Test web service
print_status "Testing web service..."
if curl -f http://localhost > /dev/null 2>&1; then
    print_success "Web service is working!"
    
    # Check if it's serving the PHP app
    if curl -s http://localhost | grep -q "Smart Attendance"; then
        print_success "PHP app is being served!"
    else
        print_warning "Still serving default page, checking what's being served..."
        curl -s http://localhost | head -5
    fi
else
    print_warning "Web service not responding, checking logs..."
    docker logs smart_attendance-web-1 | tail -10
    
    # Check if Apache is running inside container
    print_status "Checking if Apache is running inside container..."
    docker exec smart_attendance-web-1 ps aux | grep apache || print_warning "Apache not running"
    
    # Check Apache error logs
    print_status "Checking Apache error logs..."
    docker exec smart_attendance-web-1 tail -20 /var/log/apache2/error.log 2>/dev/null || print_warning "No Apache error logs"
    
    # Try to start Apache manually
    print_status "Trying to start Apache manually..."
    docker exec smart_attendance-web-1 apache2ctl start 2>/dev/null || print_warning "Cannot start Apache manually"
    
    sleep 10
    
    # Test web service again
    print_status "Testing web service again..."
    if curl -f http://localhost > /dev/null 2>&1; then
        print_success "Web service is now working!"
    else
        print_error "Web service still not working!"
        print_status "There might be a fundamental issue with the web container"
    fi
fi

# Test Python service
print_status "Testing Python service..."
if curl -f http://localhost:5001 > /dev/null 2>&1; then
    print_success "Python service is working!"
else
    print_warning "Python service not responding, checking logs..."
    docker logs smart_attendance-face_detection-1 | tail -10
    
    # Check if Python is running inside container
    print_status "Checking if Python is running inside container..."
    docker exec smart_attendance-face_detection-1 ps aux | grep python || print_warning "Python not running"
fi

# Step 12: Show final status
print_step "12. Final status check..."
print_status "All services running:"
docker ps

print_status "Port status:"
netstat -tulpn | grep -E ":(80|3306|6379|5001)" 2>/dev/null || print_warning "netstat not available"

# Step 13: Show access information
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
echo "• Start services: docker compose up -d"
echo "• Stop services: docker compose down"
echo "• View logs: docker compose logs [service_name]"
echo "• Restart services: docker compose restart"
echo ""
echo "File Locations:"
echo "• Project directory: $(pwd)"
echo "• Docker compose file: $(pwd)/docker-compose.yml"
echo "• Source code: $(pwd)/src"
echo "• Database: MySQL on port 3306"
echo "• Cache: Redis on port 6379"
echo ""

# Step 14: Show next steps
print_header "Next Steps"
echo "1. Access the admin portal: http://localhost/login.php?user_type=admin"
echo "2. Login with admin/password"
echo "3. Add teachers, students, and cameras"
echo "4. Configure face detection schedules"
echo "5. Test the live view functionality"
echo ""

print_success "Smart Attendance Management System is now running!"
print_status "All services are configured exactly like your local setup!"
