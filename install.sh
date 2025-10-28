#!/bin/bash

# One-liner installation script for Smart Attendance Management System
# This script downloads and runs the complete setup

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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header "Smart Attendance Management System - One-Liner Installation"
echo "This script will install everything on your cloud VM"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
    exit 1
fi

# Download and run the complete setup script
print_status "Downloading and running the complete setup script..."
curl -fsSL https://raw.githubusercontent.com/zawnaing-2024/Smart_Attendance/main/complete-cloud-setup.sh | bash

print_success "Installation completed!"
echo ""
print_header "🎉 Smart Attendance Management System is now running!"
echo ""
echo "Access URLs:"
echo "• Main Portal: http://localhost"
echo "• Admin Portal: http://localhost/login.php?user_type=admin"
echo "• Teacher Portal: http://localhost/login.php?user_type=teacher"
echo "• Python Service: http://localhost:5001"
echo ""
echo "Default Login:"
echo "• Username: admin"
echo "• Password: password"
echo ""
echo "Service Management:"
echo "• Start: docker compose up -d"
echo "• Stop: docker compose down"
echo "• Logs: docker compose logs"
echo ""
print_success "Your Smart Attendance Management System is ready to use!"
