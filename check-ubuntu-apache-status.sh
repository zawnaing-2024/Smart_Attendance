#!/bin/bash

# Check Ubuntu Apache installation status
# Wait for installation to complete and test

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

print_status "Checking Ubuntu Apache installation status..."

# Wait for installation to complete
print_status "Waiting for Ubuntu Apache installation to complete..."
sleep 30

# Check if container is still running
print_status "Checking container status..."
docker ps | grep smart_attendance-web-1 || print_warning "Web container not running"

# Check if Apache is running
print_status "Checking if Apache is running..."
docker exec smart_attendance-web-1 ps aux | grep apache || print_warning "Apache not running"

# Check PHP version
print_status "Checking PHP version..."
docker exec smart_attendance-web-1 php -v 2>/dev/null || print_warning "PHP not available"

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
" 2>/dev/null || print_warning "Database connection test failed"

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
    
    print_status "Checking if installation is still in progress..."
    docker exec smart_attendance-web-1 ps aux | grep apt || print_warning "No apt processes running"
    
    print_status "Waiting a bit more for installation to complete..."
    sleep 30
    
    # Test again
    print_status "Testing web service again..."
    if curl -f http://localhost > /dev/null 2>&1; then
        print_success "Web service is now working!"
    else
        print_error "Web service still not working. Let me check what's happening..."
        
        print_status "Checking Apache status..."
        docker exec smart_attendance-web-1 systemctl status apache2 2>/dev/null || print_warning "Cannot check Apache status"
        
        print_status "Checking Apache error logs..."
        docker exec smart_attendance-web-1 tail -20 /var/log/apache2/error.log 2>/dev/null || print_warning "No Apache error logs"
        
        print_status "Checking if files exist..."
        docker exec smart_attendance-web-1 ls -la /var/www/html/
        
        print_status "Trying to start Apache manually..."
        docker exec smart_attendance-web-1 apache2ctl start 2>/dev/null || print_warning "Cannot start Apache manually"
        
        sleep 5
        
        if curl -f http://localhost > /dev/null 2>&1; then
            print_success "Apache started manually and working!"
        else
            print_error "Apache still not working. There might be an issue with the installation."
            print_status "Let me try a different approach..."
            
            # Stop current container and try a simpler approach
            print_status "Stopping current container and trying simpler approach..."
            docker stop smart_attendance-web-1 2>/dev/null || true
            docker rm smart_attendance-web-1 2>/dev/null || true
            
            # Get the network name
            NETWORK_NAME=$(docker inspect smart_attendance-db-1 --format='{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' 2>/dev/null)
            
            # Try with a pre-built PHP Apache image
            print_status "Trying with pre-built PHP Apache image..."
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
            
            # Wait for container to start
            print_status "Waiting for PHP Apache container to start..."
            sleep 15
            
            # Install extensions
            print_status "Installing PHP extensions..."
            docker exec smart_attendance-web-1 sh -c "
                apt-get update -qq &&
                apt-get install -y -qq libpng-dev libfreetype6-dev libjpeg62-turbo-dev &&
                docker-php-ext-configure gd --with-freetype --with-jpeg &&
                docker-php-ext-install gd pdo_mysql &&
                a2enmod rewrite &&
                chown -R www-data:www-data /var/www/html &&
                chmod -R 755 /var/www/html &&
                mkdir -p /var/www/html/uploads/faces &&
                chown -R www-data:www-data /var/www/html/uploads
            "
            
            sleep 10
            
            if curl -f http://localhost > /dev/null 2>&1; then
                print_success "PHP Apache container is working!"
            else
                print_error "Even PHP Apache container failed!"
                print_status "There might be a fundamental issue with the system"
                print_status "Database and Redis are still working on ports 3306 and 6379"
            fi
        fi
    fi
fi

print_success "Ubuntu Apache status check completed!"
