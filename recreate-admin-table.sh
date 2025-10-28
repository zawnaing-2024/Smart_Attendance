#!/bin/bash

# Direct database fix - let's recreate the admin_users table properly
# This will fix the column issue once and for all

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

print_status "Recreating admin_users table with proper structure..."

# Drop and recreate admin_users table with proper structure
print_status "Dropping existing admin_users table..."
docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; DROP TABLE IF EXISTS admin_users;" 2>/dev/null

print_status "Creating admin_users table with proper structure..."
docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; 
CREATE TABLE admin_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);" 2>/dev/null

print_status "Inserting admin user with proper data..."
docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; 
INSERT INTO admin_users (username, password, email, full_name) VALUES 
('admin', '\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin@smartattendance.com', 'System Administrator');" 2>/dev/null

# Verify table structure
print_status "Verifying admin_users table structure:"
docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; DESCRIBE admin_users;" 2>/dev/null

# Check admin user data
print_status "Admin user data:"
docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; SELECT username, full_name, is_active FROM admin_users WHERE username='admin';" 2>/dev/null

# Restart web container
print_status "Restarting web container..."
docker compose restart web
sleep 15

# Test admin login process
print_status "Testing admin login process..."
login_response=$(curl -s -X POST -d "username=admin&password=password&user_type=admin" http://localhost/auth/login_process.php)
if echo "$login_response" | grep -q "dashboard"; then
    print_success "Admin login process is now working!"
elif echo "$login_response" | grep -q "full_name"; then
    print_error "Still getting full_name error. Response:"
    echo "$login_response" | head -5
else
    print_warning "Login response:"
    echo "$login_response" | head -5
fi

print_success "Admin users table recreation completed!"
echo ""
echo "Try accessing: http://localhost/login.php?user_type=admin"
echo "Login: admin / password"
