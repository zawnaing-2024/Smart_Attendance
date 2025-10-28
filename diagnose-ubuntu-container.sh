#!/bin/bash

# Diagnose why Ubuntu 22.04 web container is not running
# Check logs and fix the issue

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

print_status "Diagnosing why Ubuntu 22.04 web container is not running..."

# Check all containers
print_status "Checking all containers..."
docker ps -a | grep smart_attendance || print_warning "No smart_attendance containers found"

# Check web container specifically
print_status "Checking web container status..."
docker ps -a | grep web || print_warning "No web container found"

# Check web container logs
print_status "Checking web container logs..."
docker logs smart_attendance-web-1 2>/dev/null || print_warning "No web container logs found"

# Check if container exists but is stopped
if docker ps -a | grep smart_attendance-web-1 | grep -q "Exited"; then
    print_warning "Web container exists but is stopped (Exited)"
    print_status "Checking exit code..."
    docker ps -a | grep smart_attendance-web-1
    
    print_status "Checking logs for errors..."
    docker logs smart_attendance-web-1 | tail -20
fi

# Get the network name from existing containers
NETWORK_NAME=$(docker inspect smart_attendance-db-1 --format='{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' 2>/dev/null)

print_status "Using network: $NETWORK_NAME"

# Clean up any failed containers
print_status "Cleaning up failed containers..."
docker stop smart_attendance-web-1 2>/dev/null || true
docker rm smart_attendance-web-1 2>/dev/null || true

# Try a simpler Ubuntu approach
print_status "Trying simpler Ubuntu approach..."

# Create Ubuntu container with step-by-step installation
print_status "Creating Ubuntu container with step-by-step installation..."
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
    ubuntu:22.04 \
    sleep infinity

# Wait for container to start
print_status "Waiting for container to start..."
sleep 5

# Install packages step by step
print_status "Installing packages step by step..."

# Update package lists
print_status "Updating package lists..."
docker exec smart_attendance-web-1 apt-get update

# Install Apache
print_status "Installing Apache..."
docker exec smart_attendance-web-1 apt-get install -y apache2

# Install PHP
print_status "Installing PHP..."
docker exec smart_attendance-web-1 apt-get install -y php

# Install PHP extensions
print_status "Installing PHP extensions..."
docker exec smart_attendance-web-1 apt-get install -y php-mysql php-gd php-mbstring php-xml php-curl

# Install Apache PHP module
print_status "Installing Apache PHP module..."
docker exec smart_attendance-web-1 apt-get install -y libapache2-mod-php

# Enable Apache modules
print_status "Enabling Apache modules..."
docker exec smart_attendance-web-1 a2enmod rewrite
docker exec smart_attendance-web-1 a2enmod php8.1

# Configure Apache
print_status "Configuring Apache..."
docker exec smart_attendance-web-1 sh -c "
    echo '<Directory /var/www/html>' >> /etc/apache2/apache2.conf &&
    echo '    AllowOverride All' >> /etc/apache2/apache2.conf &&
    echo '</Directory>' >> /etc/apache2/apache2.conf
"

# Set permissions
print_status "Setting permissions..."
docker exec smart_attendance-web-1 chown -R www-data:www-data /var/www/html
docker exec smart_attendance-web-1 chmod -R 755 /var/www/html
docker exec smart_attendance-web-1 mkdir -p /var/www/html/uploads/faces
docker exec smart_attendance-web-1 chown -R www-data:www-data /var/www/html/uploads

# Start Apache
print_status "Starting Apache..."
docker exec smart_attendance-web-1 apache2ctl start

# Wait for Apache to start
print_status "Waiting for Apache to start..."
sleep 10

# Check if Apache is running
print_status "Checking if Apache is running..."
docker exec smart_attendance-web-1 ps aux | grep apache || print_warning "Apache not running"

# Check PHP version
print_status "Checking PHP version..."
docker exec smart_attendance-web-1 php -v

# Check PHP extensions
print_status "Checking PHP extensions..."
docker exec smart_attendance-web-1 php -m | grep -i pdo || print_warning "No PDO extensions found"

# Test database connection
print_status "Testing database connection..."
docker exec smart_attendance-web-1 php -r "
    try {
        \$pdo = new PDO('mysql:host=smart_attendance-db-1;dbname=smart_attendance', 'attendance_user', 'attendance_pass');
        echo 'Database connection successful!' . PHP_EOL;
    } catch (PDOException \$e) {
        echo 'Database connection failed: ' . \$e->getMessage() . PHP_EOL;
    }
"

# Test web service
print_status "Testing web service..."
if curl -f http://localhost > /dev/null 2>&1; then
    print_success "Ubuntu Apache web service is working!"
    echo
    echo "=========================================="
    echo "🎉 Ubuntu Apache Working!"
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
    print_warning "Web service not responding, checking logs..."
    docker logs smart_attendance-web-1 | tail -20
    
    print_status "Checking Apache status..."
    docker exec smart_attendance-web-1 systemctl status apache2 2>/dev/null || print_warning "Cannot check Apache status"
    
    print_status "Checking Apache error logs..."
    docker exec smart_attendance-web-1 tail -20 /var/log/apache2/error.log 2>/dev/null || print_warning "No Apache error logs"
    
    print_status "Trying to start Apache manually..."
    docker exec smart_attendance-web-1 apache2ctl start 2>/dev/null || print_warning "Cannot start Apache manually"
    
    sleep 5
    
    if curl -f http://localhost > /dev/null 2>&1; then
        print_success "Apache started manually and working!"
    else
        print_error "Apache still not working. Let me try a different approach..."
        
        # Try with nginx instead
        print_status "Trying nginx instead of Apache..."
        docker stop smart_attendance-web-1 2>/dev/null || true
        docker rm smart_attendance-web-1 2>/dev/null || true
        
        # Create nginx container
        print_status "Creating nginx container..."
        docker run -d \
            --name smart_attendance-web-1 \
            --network $NETWORK_NAME \
            -p 80:80 \
            -v $(pwd)/src:/usr/share/nginx/html \
            -v $(pwd)/uploads:/usr/share/nginx/html/uploads \
            nginx:alpine
        
        sleep 5
        
        if curl -f http://localhost > /dev/null 2>&1; then
            print_success "Nginx web service is working!"
            print_warning "Note: PHP features disabled, but interface is accessible"
        else
            print_error "Even nginx failed!"
            print_status "There might be a fundamental issue with the system"
            print_status "Database and Redis are still working on ports 3306 and 6379"
        fi
    fi
fi

print_success "Ubuntu Apache diagnosis completed!"
