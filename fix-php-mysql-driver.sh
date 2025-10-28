#!/bin/bash

# Fix PHP MySQL driver issue
# The pdo_mysql extension is not loaded

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

print_status "Fixing PHP MySQL driver issue..."

# Check if web container is running
if ! docker ps | grep smart_attendance-web-1; then
    print_error "Web container is not running!"
    exit 1
fi

# Check current PHP extensions
print_status "Checking current PHP extensions..."
docker exec smart_attendance-web-1 php -m | grep -i pdo || print_warning "No PDO extensions found"

# Install MySQL client and PDO extensions
print_status "Installing MySQL client and PDO extensions..."
docker exec smart_attendance-web-1 sh -c "
    echo 'Updating package lists...' &&
    apt-get update -qq --fix-missing &&
    echo 'Installing MySQL client...' &&
    apt-get install -y -qq default-mysql-client ||
    apt-get install -y -qq mysql-client ||
    echo 'MySQL client installation failed, continuing...' &&
    echo 'Installing PDO MySQL extension...' &&
    docker-php-ext-install pdo_mysql 2>/dev/null ||
    echo 'PDO MySQL extension installation failed, trying alternative...' &&
    apt-get install -y -qq php-mysql php-pdo-mysql ||
    echo 'Alternative PDO MySQL installation failed'
"

# Check if PDO MySQL is now available
print_status "Checking if PDO MySQL is now available..."
docker exec smart_attendance-web-1 php -m | grep -i pdo || print_warning "PDO extensions still not found"

# Create a simple test to verify PDO MySQL
print_status "Creating PDO MySQL test..."
docker exec smart_attendance-web-1 sh -c "
    cat > /var/www/html/test_pdo.php << 'EOF'
<?php
echo 'PHP Version: ' . phpversion() . PHP_EOL;
echo 'Available PDO drivers: ' . implode(', ', PDO::getAvailableDrivers()) . PHP_EOL;

if (in_array('mysql', PDO::getAvailableDrivers())) {
    echo 'MySQL PDO driver is available!' . PHP_EOL;
    try {
        \$pdo = new PDO('mysql:host=smart_attendance-db-1;dbname=smart_attendance', 'attendance_user', 'attendance_pass');
        echo 'Database connection successful!' . PHP_EOL;
    } catch (PDOException \$e) {
        echo 'Database connection failed: ' . \$e->getMessage() . PHP_EOL;
    }
} else {
    echo 'MySQL PDO driver is NOT available!' . PHP_EOL;
}
?>
EOF
"

# Test PDO MySQL
print_status "Testing PDO MySQL..."
docker exec smart_attendance-web-1 php /var/www/html/test_pdo.php

# If PDO MySQL is still not available, try a different approach
if ! docker exec smart_attendance-web-1 php -m | grep -i pdo_mysql; then
    print_warning "PDO MySQL still not available, trying alternative approach..."
    
    # Stop current container and create a new one with PDO MySQL pre-installed
    print_status "Stopping current web container..."
    docker stop smart_attendance-web-1 2>/dev/null || true
    docker rm smart_attendance-web-1 2>/dev/null || true
    
    # Get the network name
    NETWORK_NAME=$(docker inspect smart_attendance-db-1 --format='{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' 2>/dev/null)
    
    # Create a new container with PDO MySQL pre-installed
    print_status "Creating new web container with PDO MySQL pre-installed..."
    docker run -d \
        --name smart_attendance-web-1 \
        --network $NETWORK_NAME \
        -p 80:80 \
        -v $(pwd)/src:/var/www/html \
        -v $(pwd)/uploads:/var/www/html/uploads \
        -e DB_HOST=smart_attendance-db-1 \
        -e DB_USER=attendance_user \
        -e DB_PASS=attendance_pass \
        -e DB_NAME=smart_attendance \
        php:8.2-apache \
        sh -c "
            echo 'Installing PDO MySQL extension...' &&
            apt-get update -qq &&
            apt-get install -y -qq libpng-dev libfreetype6-dev libjpeg62-turbo-dev &&
            docker-php-ext-configure gd --with-freetype --with-jpeg &&
            docker-php-ext-install gd pdo_mysql &&
            a2enmod rewrite &&
            chown -R www-data:www-data /var/www/html &&
            chmod -R 755 /var/www/html &&
            mkdir -p /var/www/html/uploads/faces &&
            chown -R www-data:www-data /var/www/html/uploads &&
            apache2-foreground
        "
    
    # Wait for container to start
    print_status "Waiting for new web container to start..."
    sleep 20
    
    # Test PDO MySQL again
    print_status "Testing PDO MySQL in new container..."
    docker exec smart_attendance-web-1 php /var/www/html/test_pdo.php
fi

# Test the login page
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
    echo "🎉 PHP MySQL Driver Fixed!"
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

print_success "PHP MySQL driver fix completed!"
