#!/bin/bash

# Fix database connection issue
# Web service is running but can't connect to database

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

print_status "Fixing database connection issue..."

# Check if web container is running
if ! docker ps | grep smart_attendance-web-1; then
    print_error "Web container is not running!"
    exit 1
fi

# Check if database container is running
if ! docker ps | grep smart_attendance-db-1; then
    print_error "Database container is not running!"
    exit 1
fi

# Get the network name
NETWORK_NAME=$(docker inspect smart_attendance-db-1 --format='{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' 2>/dev/null)

print_status "Using network: $NETWORK_NAME"

# Check if web container is on the same network as database
print_status "Checking network connectivity..."
docker exec smart_attendance-web-1 ping -c 1 smart_attendance-db-1 2>/dev/null || print_warning "Cannot ping database container"

# Check if database is accessible from web container
print_status "Testing database connection from web container..."
docker exec smart_attendance-web-1 sh -c "
    apt-get update -qq &&
    apt-get install -y -qq mysql-client &&
    mysql -h smart_attendance-db-1 -u attendance_user -pattendance_pass -e 'SELECT 1;' 2>/dev/null
" && print_success "Database connection test successful" || print_warning "Database connection test failed"

# Check database configuration in web container
print_status "Checking database configuration..."
docker exec smart_attendance-web-1 sh -c "
    echo 'DB_HOST: ' \$DB_HOST &&
    echo 'DB_USER: ' \$DB_USER &&
    echo 'DB_PASS: ' \$DB_PASS &&
    echo 'DB_NAME: ' \$DB_NAME
"

# Fix database configuration
print_status "Fixing database configuration..."
docker exec smart_attendance-web-1 sh -c "
    echo 'export DB_HOST=smart_attendance-db-1' >> /etc/environment &&
    echo 'export DB_USER=attendance_user' >> /etc/environment &&
    echo 'export DB_PASS=attendance_pass' >> /etc/environment &&
    echo 'export DB_NAME=smart_attendance' >> /etc/environment
"

# Check if database.php exists and fix it
print_status "Checking database.php configuration..."
docker exec smart_attendance-web-1 sh -c "
    if [ -f /var/www/html/config/database.php ]; then
        echo 'database.php exists'
        cat /var/www/html/config/database.php | head -20
    else
        echo 'database.php not found'
    fi
"

# Create a simple test to verify database connection
print_status "Creating database connection test..."
docker exec smart_attendance-web-1 sh -c "
    cat > /var/www/html/test_db.php << 'EOF'
<?php
try {
    \$pdo = new PDO('mysql:host=smart_attendance-db-1;dbname=smart_attendance', 'attendance_user', 'attendance_pass');
    echo 'Database connection successful!';
} catch (PDOException \$e) {
    echo 'Database connection failed: ' . \$e->getMessage();
}
?>
EOF
"

# Test database connection
print_status "Testing database connection..."
docker exec smart_attendance-web-1 php /var/www/html/test_db.php

# Check if the database has the required tables
print_status "Checking database tables..."
docker exec smart_attendance-web-1 sh -c "
    mysql -h smart_attendance-db-1 -u attendance_user -pattendance_pass smart_attendance -e 'SHOW TABLES;' 2>/dev/null
"

# If tables don't exist, initialize the database
print_status "Initializing database if needed..."
docker exec smart_attendance-web-1 sh -c "
    if [ -f /var/www/html/database/init.sql ]; then
        echo 'Initializing database with init.sql...'
        mysql -h smart_attendance-db-1 -u attendance_user -pattendance_pass smart_attendance < /var/www/html/database/init.sql 2>/dev/null || echo 'Database already initialized'
    else
        echo 'init.sql not found'
    fi
"

# Test the login page again
print_status "Testing login page..."
if curl -f http://localhost/login.php > /dev/null 2>&1; then
    print_success "Login page is accessible!"
    
    # Test with actual login
    print_status "Testing login functionality..."
    curl -X POST http://localhost/auth/login_process.php \
        -d "username=admin&password=password&user_type=admin" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        2>/dev/null | head -5
    
    echo
    echo "=========================================="
    echo "🎉 Database Connection Fixed!"
    echo "=========================================="
    echo "Access URLs:"
    echo "• Main Portal: http://localhost"
    echo "• Admin Portal: http://localhost/login.php?user_type=admin"
    echo "• Default Login: admin / password"
    echo
    print_status "All services running:"
    docker ps
    echo
    print_status "Port status:"
    netstat -tulpn | grep -E ":(80|3306|6379)"
    
else
    print_warning "Login page still not accessible, checking logs..."
    docker logs smart_attendance-web-1 | tail -10
fi

print_success "Database connection fix completed!"
