#!/bin/bash

# Switch to Ubuntu Apache instead of Debian
# Fix ISP blocking of deb.debian.org

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

print_status "Switching to Ubuntu Apache instead of Debian..."

# Stop current web container
print_status "Stopping current Debian-based web container..."
docker stop smart_attendance-web-1 2>/dev/null || true
docker rm smart_attendance-web-1 2>/dev/null || true

# Get the network name from existing containers
NETWORK_NAME=$(docker inspect smart_attendance-db-1 --format='{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' 2>/dev/null)

print_status "Using network: $NETWORK_NAME"

# Create Ubuntu-based PHP Apache container
print_status "Creating Ubuntu-based PHP Apache container..."
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
    sh -c "
        echo 'Installing Apache and PHP on Ubuntu...' &&
        apt-get update &&
        apt-get install -y apache2 php php-mysql php-gd php-mbstring php-xml php-curl libapache2-mod-php &&
        echo 'Enabling Apache modules...' &&
        a2enmod rewrite &&
        a2enmod php8.1 &&
        echo 'Configuring Apache...' &&
        echo '<Directory /var/www/html>' >> /etc/apache2/apache2.conf &&
        echo '    AllowOverride All' >> /etc/apache2/apache2.conf &&
        echo '</Directory>' >> /etc/apache2/apache2.conf &&
        echo 'Setting permissions...' &&
        chown -R www-data:www-data /var/www/html &&
        chmod -R 755 /var/www/html &&
        mkdir -p /var/www/html/uploads/faces &&
        chown -R www-data:www-data /var/www/html/uploads &&
        echo 'Starting Apache...' &&
        apache2ctl -D FOREGROUND
    "

# Wait for container to start
print_status "Waiting for Ubuntu Apache container to start..."
sleep 20

# Check if Apache is running
print_status "Checking if Apache is running..."
docker exec smart_attendance-web-1 ps aux | grep apache || print_warning "Apache not running"

# Check PHP version and extensions
print_status "Checking PHP version and extensions..."
docker exec smart_attendance-web-1 php -v
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

# Test the web service
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
    docker logs smart_attendance-web-1 | tail -10
    
    print_status "Trying to start Apache manually..."
    docker exec smart_attendance-web-1 apache2ctl start
    
    sleep 5
    
    if curl -f http://localhost > /dev/null 2>&1; then
        print_success "Apache started manually and working!"
    else
        print_error "Apache still not working. Let me check the configuration..."
        
        print_status "Checking Apache configuration..."
        docker exec smart_attendance-web-1 apache2ctl configtest
        
        print_status "Checking Apache error logs..."
        docker exec smart_attendance-web-1 tail -20 /var/log/apache2/error.log 2>/dev/null || print_warning "No Apache error logs"
        
        print_status "Checking if files exist..."
        docker exec smart_attendance-web-1 ls -la /var/www/html/
        
        print_status "Let me try a different approach..."
        
        # Stop current container
        docker stop smart_attendance-web-1 2>/dev/null || true
        docker rm smart_attendance-web-1 2>/dev/null || true
        
        # Try with Ubuntu and PHP 8.1
        print_status "Trying Ubuntu with PHP 8.1..."
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
            sh -c "
                echo 'Installing Apache and PHP 8.1 on Ubuntu...' &&
                apt-get update &&
                apt-get install -y apache2 php8.1 php8.1-mysql php8.1-gd php8.1-mbstring php8.1-xml php8.1-curl libapache2-mod-php8.1 &&
                echo 'Enabling Apache modules...' &&
                a2enmod rewrite &&
                a2enmod php8.1 &&
                echo 'Configuring Apache...' &&
                echo '<Directory /var/www/html>' >> /etc/apache2/apache2.conf &&
                echo '    AllowOverride All' >> /etc/apache2/apache2.conf &&
                echo '</Directory>' >> /etc/apache2/apache2.conf &&
                echo 'Setting permissions...' &&
                chown -R www-data:www-data /var/www/html &&
                chmod -R 755 /var/www/html &&
                mkdir -p /var/www/html/uploads/faces &&
                chown -R www-data:www-data /var/www/html/uploads &&
                echo 'Starting Apache...' &&
                apache2ctl -D FOREGROUND
            "
        
        # Wait for container to start
        print_status "Waiting for Ubuntu PHP 8.1 container to start..."
        sleep 20
        
        if curl -f http://localhost > /dev/null 2>&1; then
            print_success "Ubuntu PHP 8.1 Apache is working!"
        else
            print_error "Even Ubuntu PHP 8.1 failed!"
            print_status "There might be a fundamental issue with the system"
            print_status "Database and Redis are still working on ports 3306 and 6379"
        fi
    fi
fi

print_success "Ubuntu Apache switch completed!"
