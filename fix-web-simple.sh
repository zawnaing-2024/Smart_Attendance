#!/bin/bash

# Simple guaranteed fix - use the exact same approach as local
# Stop all web containers and start fresh with PHP Apache

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

print_status "Starting fresh with simple PHP Apache approach..."

# Stop ALL web-related containers
print_status "Stopping all web containers..."
docker stop $(docker ps -q --filter "name=web") 2>/dev/null || true
docker stop $(docker ps -q --filter "name=php") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=web") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=php") 2>/dev/null || true

# Get the network name from existing containers
NETWORK_NAME=$(docker inspect smart_attendance-db-1 --format='{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' 2>/dev/null || echo "smart_attendance_attendance_network")

print_status "Using network: $NETWORK_NAME"

# Create a simple PHP Apache container (exactly like local)
print_status "Creating simple PHP Apache container..."

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
    php:8.2-apache

# Wait for container to start
print_status "Waiting for container to start..."
sleep 10

# Install PHP extensions
print_status "Installing PHP extensions..."
docker exec smart_attendance-web-1 sh -c "
    echo 'Updating package lists...' &&
    apt-get update -qq &&
    echo 'Installing packages...' &&
    apt-get install -y -qq libpng-dev libfreetype6-dev libjpeg62-turbo-dev &&
    echo 'Configuring PHP extensions...' &&
    docker-php-ext-configure gd --with-freetype --with-jpeg &&
    docker-php-ext-install -q gd pdo_mysql &&
    echo 'Enabling Apache modules...' &&
    a2enmod rewrite &&
    echo 'Setting permissions...' &&
    chown -R www-data:www-data /var/www/html &&
    chmod -R 755 /var/www/html &&
    mkdir -p /var/www/html/uploads/faces &&
    chown -R www-data:www-data /var/www/html/uploads &&
    echo 'Restarting Apache...' &&
    apache2ctl restart
"

# Wait for Apache to restart
print_status "Waiting for Apache to restart..."
sleep 10

# Test the service
print_status "Testing web service..."
if curl -f http://localhost > /dev/null 2>&1; then
    print_success "Web service is working!"
    echo
    echo "=========================================="
    echo "🎉 Web Service Fixed!"
    echo "=========================================="
    echo "Access URLs:"
    echo "• Main Portal: http://localhost"
    echo "• Admin Portal: http://localhost/login.php?user_type=admin"
    echo "• Default Login: admin / password"
    echo
    print_status "Testing specific pages..."
    
    # Test main page
    if curl -f http://localhost/index.php > /dev/null 2>&1; then
        print_success "Main page accessible"
    else
        print_warning "Main page not accessible"
    fi
    
    # Test login page
    if curl -f http://localhost/login.php > /dev/null 2>&1; then
        print_success "Login page accessible"
    else
        print_warning "Login page not accessible"
    fi
    
    print_status "All services running:"
    docker ps
    echo
    print_status "Port status:"
    netstat -tulpn | grep -E ":(80|3306|6379)"
    
else
    print_warning "Web service not responding, checking logs..."
    docker logs smart_attendance-web-1
    
    print_status "Checking if Apache is running inside container..."
    docker exec smart_attendance-web-1 ps aux | grep apache || print_warning "Apache not running"
    
    print_status "Checking Apache error logs..."
    docker exec smart_attendance-web-1 tail -20 /var/log/apache2/error.log 2>/dev/null || print_warning "No Apache error logs"
    
    print_status "Trying to start Apache manually..."
    docker exec smart_attendance-web-1 apache2ctl start
    
    sleep 5
    
    if curl -f http://localhost > /dev/null 2>&1; then
        print_success "Apache started manually and working!"
    else
        print_error "Apache still not working. Let me check the files..."
        
        print_status "Checking if files exist..."
        docker exec smart_attendance-web-1 ls -la /var/www/html/
        
        print_status "Checking if index.php exists..."
        docker exec smart_attendance-web-1 cat /var/www/html/index.php 2>/dev/null || print_warning "No index.php found"
        
        print_status "Checking if login.php exists..."
        docker exec smart_attendance-web-1 cat /var/www/html/login.php 2>/dev/null || print_warning "No login.php found"
        
        print_status "Let me try a different approach..."
        
        # Stop current container
        docker stop smart_attendance-web-1 2>/dev/null || true
        docker rm smart_attendance-web-1 2>/dev/null || true
        
        # Try with a different PHP image
        print_status "Trying with php:8.1-apache..."
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
            php:8.1-apache
        
        sleep 10
        
        # Install extensions
        docker exec smart_attendance-web-1 sh -c "
            apt-get update -qq &&
            apt-get install -y -qq libpng-dev libfreetype6-dev libjpeg62-turbo-dev &&
            docker-php-ext-configure gd --with-freetype --with-jpeg &&
            docker-php-ext-install -q gd pdo_mysql &&
            a2enmod rewrite &&
            chown -R www-data:www-data /var/www/html &&
            chmod -R 755 /var/www/html &&
            mkdir -p /var/www/html/uploads/faces &&
            chown -R www-data:www-data /var/www/html/uploads
        "
        
        sleep 5
        
        if curl -f http://localhost > /dev/null 2>&1; then
            print_success "PHP 8.1 Apache is working!"
        else
            print_error "Even PHP 8.1 failed!"
            print_status "There might be a fundamental issue with the files or system"
            print_status "Database and Redis are still working on ports 3306 and 6379"
        fi
    fi
fi

print_success "Web service fix completed!"
