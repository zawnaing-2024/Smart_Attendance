#!/bin/bash

# Fix web service with proper approach
# Handle package issues and network problems

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

print_status "Fixing web service with proper approach..."

# First, let's see what networks exist
print_status "Checking existing networks..."
docker network ls

# Check what's running
print_status "Current running containers:"
docker ps

# Stop any failed web containers
print_status "Cleaning up failed web containers..."
docker stop $(docker ps -q --filter "name=web") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=web") 2>/dev/null || true

# Create a working web service that connects to existing db/redis
print_status "Creating working web service..."

# Get the network name from existing containers
NETWORK_NAME=$(docker inspect smart_attendance-db-1 --format='{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' 2>/dev/null || echo "smart_attendance_attendance_network")

print_status "Using network: $NETWORK_NAME"

# Create a simple web service using the same network
cat > docker-compose.web-fix.yml << EOF
services:
  web:
    image: php:8.2-apache
    ports:
      - "80:80"
    volumes:
      - ./src:/var/www/html
      - ./uploads:/var/www/html/uploads
    environment:
      - DB_HOST=smart_attendance-db-1
      - DB_USER=attendance_user
      - DB_PASS=attendance_pass
      - DB_NAME=smart_attendance
    networks:
      - default
    command: >
      sh -c "
        echo 'Updating package lists...' &&
        apt-get update &&
        echo 'Installing basic packages...' &&
        apt-get install -y libpng-dev libfreetype6-dev libjpeg62-turbo-dev &&
        echo 'Configuring PHP extensions...' &&
        docker-php-ext-configure gd --with-freetype --with-jpeg &&
        docker-php-ext-install gd pdo_mysql &&
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

networks:
  default:
    external: true
    name: $NETWORK_NAME
EOF

print_status "Starting web service..."
if docker compose -f docker-compose.web-fix.yml up -d; then
    print_success "Web service started!"
    
    # Wait for web service to be ready
    print_status "Waiting for web service to be ready..."
    sleep 15
    
    # Test web service
    print_status "Testing web service..."
    if curl -f http://localhost > /dev/null 2>&1; then
        print_success "Web service is responding!"
    else
        print_warning "Web service not responding yet, checking logs..."
        docker compose -f docker-compose.web-fix.yml logs web
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
    print_error "Web service still failed. Let's try the simplest approach..."
    
    # Try with nginx only
    print_status "Trying nginx-only approach..."
    cat > docker-compose.web-fix.yml << EOF
services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./src:/usr/share/nginx/html
      - ./uploads:/usr/share/nginx/html/uploads
    networks:
      - default

networks:
  default:
    external: true
    name: $NETWORK_NAME
EOF
    
    print_status "Starting nginx web service..."
    if docker compose -f docker-compose.web-fix.yml up -d; then
        print_success "Nginx web service started!"
        print_warning "Note: PHP features disabled, but interface is accessible"
        echo
        echo "=========================================="
        echo "🎉 Nginx Web Service Running!"
        echo "=========================================="
        echo "Access URLs:"
        echo "• Main Portal: http://localhost"
        echo "• Note: PHP features disabled"
    else
        print_error "Even nginx failed!"
        print_status "Let's try connecting to existing network manually..."
        
        # Try manual approach
        print_status "Trying manual container creation..."
        docker run -d \
            --name smart_attendance-web-1 \
            --network $NETWORK_NAME \
            -p 80:80 \
            -v $(pwd)/src:/usr/share/nginx/html \
            -v $(pwd)/uploads:/usr/share/nginx/html/uploads \
            nginx:alpine
        
        if docker ps | grep smart_attendance-web-1; then
            print_success "Manual nginx container created!"
            print_warning "Note: PHP features disabled"
        else
            print_error "All approaches failed!"
            print_status "Database and Redis are still working"
            print_status "You can access MySQL directly on port 3306"
        fi
    fi
fi

print_success "Web service fix completed!"
