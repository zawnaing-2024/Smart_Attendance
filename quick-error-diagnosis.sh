#!/bin/bash

# Quick error diagnosis script
# This script helps identify what specific error you're seeing

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

print_status "Quick error diagnosis..."

# Test main page
print_status "Testing main page..."
main_response=$(curl -s http://localhost)
if echo "$main_response" | grep -q "Smart Attendance"; then
    print_success "Main page is working!"
else
    print_warning "Main page not working. Response:"
    echo "$main_response" | head -5
fi

# Test admin login page
print_status "Testing admin login page..."
admin_response=$(curl -s http://localhost/login.php?user_type=admin)
if echo "$admin_response" | grep -q "Smart Attendance"; then
    print_success "Admin login page is working!"
else
    print_warning "Admin login page not working. Response:"
    echo "$admin_response" | head -5
fi

# Test teacher login page
print_status "Testing teacher login page..."
teacher_response=$(curl -s http://localhost/login.php?user_type=teacher)
if echo "$teacher_response" | grep -q "Smart Attendance"; then
    print_success "Teacher login page is working!"
else
    print_warning "Teacher login page not working. Response:"
    echo "$teacher_response" | head -5
fi

# Test admin login process
print_status "Testing admin login process..."
login_response=$(curl -s -X POST -d "username=admin&password=password&user_type=admin" http://localhost/auth/login_process.php)
if echo "$login_response" | grep -q "dashboard"; then
    print_success "Admin login process is working!"
else
    print_warning "Admin login process not working. Response:"
    echo "$login_response" | head -5
fi

# Test database connection
print_status "Testing database connection..."
db_test=$(docker exec smart_attendance-web-1 php -r "
try {
    \$pdo = new PDO('mysql:host=db;dbname=smart_attendance', 'attendance_user', 'attendance_pass');
    echo 'Database connection successful!';
} catch (Exception \$e) {
    echo 'Database connection failed: ' . \$e->getMessage();
}
" 2>/dev/null)
echo "Database test result: $db_test"

# Check web container logs
print_status "Checking web container logs..."
docker logs smart_attendance-web-1 | tail -10

# Check database container logs
print_status "Checking database container logs..."
docker logs smart_attendance-db-1 | tail -10

print_success "Error diagnosis completed!"
echo ""
echo "Please share the specific error message you're seeing so I can help fix it."
