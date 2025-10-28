#!/bin/bash

# Comprehensive system check and fix
# This script checks all components and fixes any remaining issues

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

print_header "Comprehensive System Check and Fix"
echo "Checking all components and fixing any remaining issues..."
echo ""

# Step 1: Check all containers
print_step "1. Checking all containers..."
docker ps

# Step 2: Check database connection
print_step "2. Checking database connection..."
if docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; SELECT 1;" 2>/dev/null; then
    print_success "Database connection working!"
else
    print_error "Database connection failed!"
    exit 1
fi

# Step 3: Check all tables
print_step "3. Checking all tables..."
tables=$(docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; SHOW TABLES;" 2>/dev/null | grep -v "Tables_in")
echo "Tables found: $tables"

# Step 4: Check admin user
print_step "4. Checking admin user..."
if docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; SELECT username FROM admin_users WHERE username='admin';" 2>/dev/null | grep -q "admin"; then
    print_success "Admin user exists!"
else
    print_warning "Admin user not found. Creating..."
    docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; INSERT IGNORE INTO admin_users (username, password, email) VALUES ('admin', '\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin@example.com');" 2>/dev/null
    print_success "Admin user created!"
fi

# Step 5: Test web container database connection
print_step "5. Testing web container database connection..."
if docker exec smart_attendance-web-1 php -r "
try {
    \$pdo = new PDO('mysql:host=db;dbname=smart_attendance', 'attendance_user', 'attendance_pass');
    echo 'Database connection successful!';
} catch (Exception \$e) {
    echo 'Database connection failed: ' . \$e->getMessage();
}
" 2>/dev/null; then
    print_success "Web container can connect to database!"
else
    print_warning "Web container cannot connect to database."
    print_status "Checking network connectivity..."
    docker exec smart_attendance-web-1 ping -c 1 db 2>/dev/null || print_warning "Cannot ping db container"
fi

# Step 6: Check web service
print_step "6. Checking web service..."
if curl -f http://localhost > /dev/null 2>&1; then
    print_success "Web service is working!"
else
    print_warning "Web service not responding. Checking logs..."
    docker logs smart_attendance-web-1 | tail -10
fi

# Step 7: Test login page
print_step "7. Testing login page..."
login_response=$(curl -s http://localhost/login.php?user_type=admin)
if echo "$login_response" | grep -q "Smart Attendance"; then
    print_success "Login page is working!"
else
    print_warning "Login page not working. Checking for errors..."
    echo "$login_response" | head -10
fi

# Step 8: Test admin login process
print_step "8. Testing admin login process..."
login_test=$(curl -s -X POST -d "username=admin&password=password&user_type=admin" http://localhost/auth/login_process.php)
if echo "$login_test" | grep -q "dashboard"; then
    print_success "Admin login process is working!"
else
    print_warning "Admin login process not working. Checking for errors..."
    echo "$login_test" | head -10
fi

# Step 9: Check PHP errors
print_step "9. Checking PHP errors..."
if docker exec smart_attendance-web-1 php -l /var/www/html/models/Admin.php 2>/dev/null; then
    print_success "Admin.php syntax is correct!"
else
    print_warning "Admin.php has syntax errors!"
    docker exec smart_attendance-web-1 php -l /var/www/html/models/Admin.php
fi

# Step 10: Check database configuration
print_step "10. Checking database configuration..."
if docker exec smart_attendance-web-1 php -r "
require_once '/var/www/html/config/database.php';
try {
    \$database = new Database();
    \$db = \$database->getConnection();
    if (\$db) {
        echo 'Database connection object created successfully!';
    } else {
        echo 'Database connection object is null!';
    }
} catch (Exception \$e) {
    echo 'Database connection failed: ' . \$e->getMessage();
}
" 2>/dev/null; then
    print_success "Database configuration is working!"
else
    print_warning "Database configuration has issues!"
fi

# Step 11: Check file permissions
print_step "11. Checking file permissions..."
if docker exec smart_attendance-web-1 ls -la /var/www/html/models/Admin.php 2>/dev/null; then
    print_success "Admin.php file exists and is accessible!"
else
    print_warning "Admin.php file not accessible!"
fi

# Step 12: Restart all services
print_step "12. Restarting all services..."
docker compose restart
sleep 15

# Step 13: Final test
print_step "13. Final system test..."
if curl -f http://localhost > /dev/null 2>&1; then
    print_success "Web service is working after restart!"
else
    print_warning "Web service not working after restart. Checking logs..."
    docker logs smart_attendance-web-1 | tail -10
fi

# Step 14: Show current status
print_step "14. Current system status..."
docker ps

print_header "System Check Complete!"
echo ""
echo "If you're still getting errors, please share:"
echo "1. The exact error message you're seeing"
echo "2. Which page you're trying to access"
echo "3. What happens when you try to login"
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
print_success "System check completed!"
