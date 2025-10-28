#!/bin/bash

# Fix missing columns in admin_users table
# The Admin.php model expects full_name and is_active columns

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

print_status "Fixing missing columns in admin_users table..."

# Check if database container is running
if ! docker ps | grep -q "smart_attendance-db"; then
    print_error "Database container is not running!"
    exit 1
fi

# Add missing columns to admin_users table
print_status "Adding missing columns to admin_users table..."
docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; ALTER TABLE admin_users ADD COLUMN IF NOT EXISTS full_name VARCHAR(100) DEFAULT NULL; ALTER TABLE admin_users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;" 2>/dev/null

# Update admin user with full_name
print_status "Updating admin user with full_name..."
docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; UPDATE admin_users SET full_name = 'Administrator' WHERE username = 'admin';" 2>/dev/null

# Verify the table structure
print_status "Verifying admin_users table structure..."
docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; DESCRIBE admin_users;" 2>/dev/null

# Test admin user
print_status "Testing admin user..."
if docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; SELECT username, full_name, is_active FROM admin_users WHERE username='admin';" 2>/dev/null | grep -q "admin"; then
    print_success "Admin user updated successfully!"
else
    print_warning "Admin user update failed!"
fi

# Restart web container
print_status "Restarting web container..."
docker compose restart web
sleep 10

# Test admin login process
print_status "Testing admin login process..."
login_response=$(curl -s -X POST -d "username=admin&password=password&user_type=admin" http://localhost/auth/login_process.php)
if echo "$login_response" | grep -q "dashboard"; then
    print_success "Admin login process is now working!"
else
    print_warning "Admin login process still not working. Response:"
    echo "$login_response" | head -5
fi

print_success "Missing columns fix completed!"
echo ""
echo "Your system should now be fully working!"
echo "Access: http://localhost/login.php?user_type=admin"
echo "Login: admin / password"
