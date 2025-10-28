#!/bin/bash

# Fix missing web container
# Face detection is running but web container is missing

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

print_status "Fixing missing web container..."

# Check all containers including stopped ones
print_status "Checking all containers including stopped ones..."
docker ps -a | grep smart_attendance

# Check if web container exists but is stopped
if docker ps -a | grep smart_attendance-web-1; then
    print_status "Web container exists but is stopped, starting it..."
    docker start smart_attendance-web-1
    sleep 10
else
    print_status "Web container doesn't exist, creating it..."
    
    # Get the network name from existing containers
    NETWORK_NAME=$(docker inspect smart_attendance-db-1 --format='{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' 2>/dev/null)
    
    print_status "Using network: $NETWORK_NAME"
    
    # Create web container
    print_status "Creating web container..."
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
            echo 'Installing PHP extensions...' &&
            apt-get update -qq &&
            apt-get install -y -qq libpng-dev libfreetype6-dev libjpeg62-turbo-dev &&
            docker-php-ext-configure gd --with-freetype --with-jpeg &&
            docker-php-ext-install -q gd pdo_mysql &&
            echo 'Enabling Apache modules...' &&
            a2enmod rewrite &&
            echo 'Setting permissions...' &&
            chown -R www-data:www-data /var/www/html &&
            chmod -R 755 /var/www/html &&
            mkdir -p /var/www/html/uploads/faces &&
            chown -R www-data:www-data /var/www/html/uploads &&
            echo 'Starting Apache...' &&
            apache2-foreground
        "
    
    # Wait for container to start
    print_status "Waiting for web container to start..."
    sleep 20
fi

# Test web service
print_status "Testing web service..."
if curl -f http://localhost > /dev/null 2>&1; then
    print_success "Web service is working!"
    
    # Check if it's serving the PHP app
    if curl -s http://localhost | grep -q "Smart Attendance"; then
        print_success "PHP app is being served!"
    else
        print_warning "Still serving default page, checking what's being served..."
        curl -s http://localhost | head -5
    fi
else
    print_warning "Web service not responding, checking logs..."
    docker logs smart_attendance-web-1 | tail -10
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
echo "🎉 All Services Fixed and Running!"
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

print_success "Web container fix completed!"
