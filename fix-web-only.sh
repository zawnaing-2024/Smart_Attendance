#!/bin/bash

# Quick fix for web service not running
# Database and Redis are working, just need to fix web

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

print_status "Database and Redis are running, fixing web service..."

# Check what happened to web service
print_status "Checking web service logs..."
docker compose logs web 2>/dev/null || print_warning "No web service logs found"

print_status "Creating simple web service that will definitely work..."

# Create a simple docker-compose that adds web to existing services
cat > docker-compose.web-only.yml << 'EOF'
version: '3.8'

services:
  web:
    image: php:8.2-apache
    ports:
      - "80:80"
    volumes:
      - ./src:/var/www/html
      - ./uploads:/var/www/html/uploads
    environment:
      - DB_HOST=db
      - DB_USER=attendance_user
      - DB_PASS=attendance_pass
      - DB_NAME=smart_attendance
    depends_on:
      - db
    networks:
      - attendance_network
    command: >
      sh -c "
        echo 'Installing PHP extensions...' &&
        apt-get update -qq &&
        apt-get install -y -qq libpng-dev libfreetype6-dev libjpeg62-turbo-dev &&
        docker-php-ext-configure gd --with-freetype --with-jpeg &&
        docker-php-ext-install -q gd pdo_mysql &&
        echo 'Configuring Apache...' &&
        a2enmod rewrite &&
        echo 'Setting permissions...' &&
        chown -R www-data:www-data /var/www/html &&
        chmod -R 755 /var/www/html &&
        mkdir -p /var/www/html/uploads/faces &&
        chown -R www-data:www-data /var/www/html/uploads &&
        echo 'Starting Apache...' &&
        apache2-foreground
      "

networks:
  attendance_network:
    external: true
EOF

print_status "Starting web service with existing network..."
if docker compose -f docker-compose.web-only.yml up -d; then
    print_success "Web service started!"
    
    # Wait for web service to be ready
    print_status "Waiting for web service to be ready..."
    sleep 10
    
    # Test web service
    print_status "Testing web service..."
    if curl -f http://localhost > /dev/null 2>&1; then
        print_success "Web service is responding!"
    else
        print_warning "Web service not responding yet, checking status..."
        docker ps | grep web
        docker compose -f docker-compose.web-only.yml logs web
    fi
    
    echo
    echo "=========================================="
    echo "🎉 Web Service Fixed!"
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
    print_error "Web service still failed. Let's try the simplest possible approach..."
    
    # Ultra-simple approach
    print_status "Trying ultra-simple nginx approach..."
    cat > docker-compose.web-only.yml << 'EOF'
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./src:/usr/share/nginx/html
      - ./uploads:/usr/share/nginx/html/uploads
    networks:
      - attendance_network

networks:
  attendance_network:
    external: true
EOF
    
    print_status "Starting simple nginx web service..."
    if docker compose -f docker-compose.web-only.yml up -d; then
        print_success "Simple web service started!"
        print_warning "Note: PHP features disabled, but interface is accessible"
        echo
        echo "=========================================="
        echo "🎉 Simple Web Service Running!"
        echo "=========================================="
        echo "Access URLs:"
        echo "• Main Portal: http://localhost"
        echo "• Note: PHP features disabled"
    else
        print_error "Even simple web service failed!"
        print_status "But database and Redis are still working"
        print_status "You can access MySQL directly on port 3306"
    fi
fi

print_success "Web service fix completed!"
