#!/bin/bash

# Quick database connection test and fix
# This script quickly tests and fixes database connection issues

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

print_status "Quick database connection test and fix..."

# Check if database container is running
if ! docker ps | grep -q "smart_attendance-db"; then
    print_warning "Database container not running. Starting it..."
    docker compose up -d db
    sleep 15
fi

# Test database connection
print_status "Testing database connection..."
if docker exec smart_attendance-db-1 mysql -u root -proot_password -e "SELECT 1;" 2>/dev/null; then
    print_success "Database is accessible!"
else
    print_warning "Database not accessible. Waiting for MySQL to start..."
    sleep 10
fi

# Check if database exists
print_status "Checking if database exists..."
if docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; SELECT 1;" 2>/dev/null; then
    print_success "Database 'smart_attendance' exists!"
else
    print_warning "Database 'smart_attendance' does not exist. Creating..."
    docker exec smart_attendance-db-1 mysql -u root -proot_password -e "CREATE DATABASE IF NOT EXISTS smart_attendance;" 2>/dev/null
    print_success "Database created!"
fi

# Check if tables exist
print_status "Checking if tables exist..."
if docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; SHOW TABLES;" 2>/dev/null | grep -q "admin_users"; then
    print_success "Tables exist!"
else
    print_warning "Tables do not exist. Initializing database..."
    docker exec -i smart_attendance-db-1 mysql -u root -proot_password smart_attendance < database/init.sql
    print_success "Database initialized!"
fi

# Test web container database connection
print_status "Testing web container database connection..."
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

# Restart web container
print_status "Restarting web container..."
docker compose restart web
sleep 10

# Test web service
print_status "Testing web service..."
if curl -f http://localhost > /dev/null 2>&1; then
    print_success "Web service is working!"
else
    print_warning "Web service not responding. Checking logs..."
    docker logs smart_attendance-web-1 | tail -10
fi

print_success "Database connection fix completed!"
echo ""
echo "Try accessing: http://localhost/login.php?user_type=admin"
echo "Login with: admin / password"
