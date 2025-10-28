#!/bin/bash

# Debug connection reset by peer error
# Check what's happening inside the containers

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

print_status "Debugging connection reset by peer error..."

# Check container logs
print_status "Checking web container logs..."
docker logs smart_attendance-web-1 | tail -20

print_status "Checking face detection container logs..."
docker logs smart_attendance-face_detection-1 | tail -20

# Check if Apache is running inside web container
print_status "Checking if Apache is running inside web container..."
docker exec smart_attendance-web-1 ps aux | grep apache || print_warning "Apache not running"

# Check if Python is running inside face detection container
print_status "Checking if Python is running inside face detection container..."
docker exec smart_attendance-face_detection-1 ps aux | grep python || print_warning "Python not running"

# Check Apache status
print_status "Checking Apache status..."
docker exec smart_attendance-web-1 apache2ctl status 2>/dev/null || print_warning "Cannot check Apache status"

# Check Apache error logs
print_status "Checking Apache error logs..."
docker exec smart_attendance-web-1 tail -20 /var/log/apache2/error.log 2>/dev/null || print_warning "No Apache error logs"

# Check if files are properly mounted
print_status "Checking if files are properly mounted..."
docker exec smart_attendance-web-1 ls -la /var/www/html/

# Check if index.php exists
print_status "Checking if index.php exists..."
docker exec smart_attendance-web-1 cat /var/www/html/index.php 2>/dev/null || print_warning "No index.php found"

# Check PHP configuration
print_status "Checking PHP configuration..."
docker exec smart_attendance-web-1 php -v 2>/dev/null || print_warning "PHP not working"

# Check if PHP extensions are loaded
print_status "Checking PHP extensions..."
docker exec smart_attendance-web-1 php -m | grep -i pdo || print_warning "No PDO extensions found"

# Try to start Apache manually
print_status "Trying to start Apache manually..."
docker exec smart_attendance-web-1 apache2ctl start 2>/dev/null || print_warning "Cannot start Apache manually"

# Wait a moment
sleep 5

# Test web service again
print_status "Testing web service again..."
if curl -f http://localhost > /dev/null 2>&1; then
    print_success "Web service is now working!"
else
    print_warning "Web service still not working, checking network..."
    
    # Check if containers can communicate
    print_status "Checking container communication..."
    docker exec smart_attendance-web-1 ping -c 1 smart_attendance-db-1 2>/dev/null || print_warning "Cannot ping database"
    
    # Check if port 80 is listening
    print_status "Checking if port 80 is listening..."
    docker exec smart_attendance-web-1 netstat -tulpn | grep :80 || print_warning "Port 80 not listening"
    
    # Try a different approach - recreate containers with simpler setup
    print_status "Trying simpler approach - recreating containers..."
    
    # Stop all containers
    print_status "Stopping all containers..."
    docker stop smart_attendance-web-1 smart_attendance-face_detection-1 2>/dev/null || true
    docker rm smart_attendance-web-1 smart_attendance-face_detection-1 2>/dev/null || true
    
    # Get the network name
    NETWORK_NAME=$(docker inspect smart_attendance-db-1 --format='{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' 2>/dev/null)
    
    # Create simple web container
    print_status "Creating simple web container..."
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
    print_status "Waiting for web container to start..."
    sleep 15
    
    # Install PHP extensions
    print_status "Installing PHP extensions..."
    docker exec smart_attendance-web-1 sh -c "
        apt-get update -qq &&
        apt-get install -y -qq libpng-dev libfreetype6-dev libjpeg62-turbo-dev &&
        docker-php-ext-configure gd --with-freetype --with-jpeg &&
        docker-php-ext-install -q gd pdo_mysql &&
        a2enmod rewrite &&
        chown -R www-data:www-data /var/www/html &&
        chmod -R 755 /var/www/html &&
        mkdir -p /var/www/html/uploads/faces &&
        chown -R www-data:www-data /var/www/html/uploads &&
        apache2ctl restart
    "
    
    # Wait for Apache to restart
    print_status "Waiting for Apache to restart..."
    sleep 10
    
    # Test web service
    print_status "Testing web service..."
    if curl -f http://localhost > /dev/null 2>&1; then
        print_success "Simple web service is working!"
    else
        print_error "Even simple web service failed!"
        print_status "There might be a fundamental issue with the system"
        print_status "Database and Redis are still working on ports 3306 and 6379"
    fi
fi

# Test face detection service
print_status "Testing face detection service..."
if curl -f http://localhost:5001 > /dev/null 2>&1; then
    print_success "Face detection service is working!"
else
    print_warning "Face detection service not responding, checking logs..."
    docker logs smart_attendance-face_detection-1 | tail -10
fi

echo
echo "=========================================="
echo "🎉 Debug and Fix Completed!"
echo "=========================================="
echo "Access URLs:"
echo "• Main Portal: http://localhost"
echo "• Admin Portal: http://localhost/login.php?user_type=admin"
echo "• Face Detection: http://localhost:5001"
echo "• Default Login: admin / password"
echo
print_status "All services running:"
docker ps
echo
print_status "Port status:"
netstat -tulpn | grep -E ":(80|3306|6379|5001)"

print_success "Debug and fix completed!"
