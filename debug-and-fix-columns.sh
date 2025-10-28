#!/bin/bash

# Debug and fix the missing columns issue
# Let's see what's actually in the database and fix it

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

print_status "Debugging and fixing the missing columns issue..."

# Check if database container is running
if ! docker ps | grep -q "smart_attendance-db"; then
    print_error "Database container is not running!"
    exit 1
fi

# Check current table structure
print_status "Current admin_users table structure:"
docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; DESCRIBE admin_users;" 2>/dev/null

# Check if columns exist
print_status "Checking if full_name column exists..."
if docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; SHOW COLUMNS FROM admin_users LIKE 'full_name';" 2>/dev/null | grep -q "full_name"; then
    print_success "full_name column exists!"
else
    print_warning "full_name column does not exist. Adding it..."
    docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; ALTER TABLE admin_users ADD COLUMN full_name VARCHAR(100) DEFAULT NULL;" 2>/dev/null
    print_success "full_name column added!"
fi

print_status "Checking if is_active column exists..."
if docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; SHOW COLUMNS FROM admin_users LIKE 'is_active';" 2>/dev/null | grep -q "is_active"; then
    print_success "is_active column exists!"
else
    print_warning "is_active column does not exist. Adding it..."
    docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; ALTER TABLE admin_users ADD COLUMN is_active BOOLEAN DEFAULT TRUE;" 2>/dev/null
    print_success "is_active column added!"
fi

# Verify table structure again
print_status "Updated admin_users table structure:"
docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; DESCRIBE admin_users;" 2>/dev/null

# Update admin user with full_name
print_status "Updating admin user with full_name..."
docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; UPDATE admin_users SET full_name = 'Administrator' WHERE username = 'admin';" 2>/dev/null

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

print_success "Debug and fix completed!"
echo ""
echo "Try accessing: http://localhost/login.php?user_type=admin"
echo "Login: admin / password"
