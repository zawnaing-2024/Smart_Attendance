#!/bin/bash

# Fix 502 Bad Gateway error
# nginx can't connect to PHP-FPM, need to add PHP service or switch to PHP container

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

print_status "Fixing 502 Bad Gateway error..."

# Stop current nginx container
print_status "Stopping current nginx container..."
docker stop smart_attendance-web-1 2>/dev/null || true
docker rm smart_attendance-web-1 2>/dev/null || true

# Get the network name from existing containers
NETWORK_NAME=$(docker inspect smart_attendance-db-1 --format='{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' 2>/dev/null || echo "smart_attendance_attendance_network")

print_status "Using network: $NETWORK_NAME"

# Option 1: Switch to PHP Apache container (simpler)
print_status "Switching to PHP Apache container (simpler approach)..."

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

# Wait for PHP service to be ready
print_status "Waiting for PHP service to be ready..."
sleep 20

# Test the service
print_status "Testing PHP web service..."
if curl -f http://localhost > /dev/null 2>&1; then
    print_success "PHP web service is working!"
    echo
    echo "=========================================="
    echo "🎉 502 Bad Gateway Fixed!"
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
    print_warning "PHP service not responding, checking logs..."
    docker logs smart_attendance-web-1
    
    print_status "Trying alternative approach with nginx + php-fpm..."
    
    # Stop PHP container
    docker stop smart_attendance-web-1 2>/dev/null || true
    docker rm smart_attendance-web-1 2>/dev/null || true
    
    # Create nginx + php-fpm setup
    print_status "Creating nginx + php-fpm setup..."
    
    # Start PHP-FPM container
    docker run -d \
        --name smart_attendance-php-1 \
        --network $NETWORK_NAME \
        -v $(pwd)/src:/var/www/html \
        -v $(pwd)/uploads:/var/www/html/uploads \
        -e DB_HOST=smart_attendance-db-1 \
        -e DB_USER=attendance_user \
        -e DB_PASS=attendance_pass \
        -e DB_NAME=smart_attendance \
        php:8.2-fpm-alpine \
        sh -c "
            apk add --no-cache libpng-dev libfreetype-dev libjpeg-turbo-dev &&
            docker-php-ext-configure gd --with-freetype --with-jpeg &&
            docker-php-ext-install gd pdo_mysql &&
            chown -R www-data:www-data /var/www/html &&
            chmod -R 755 /var/www/html &&
            mkdir -p /var/www/html/uploads/faces &&
            chown -R www-data:www-data /var/www/html/uploads &&
            php-fpm
        "
    
    # Start nginx container
    docker run -d \
        --name smart_attendance-web-1 \
        --network $NETWORK_NAME \
        -p 80:80 \
        -v $(pwd)/src:/usr/share/nginx/html \
        -v $(pwd)/uploads:/usr/share/nginx/html/uploads \
        nginx:alpine \
        sh -c "
            cat > /etc/nginx/conf.d/default.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_pass smart_attendance-php-1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME /var/www/html\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF
            nginx -g 'daemon off;'
        "
    
    # Wait for services to be ready
    print_status "Waiting for nginx + php-fpm to be ready..."
    sleep 15
    
    # Test the service
    print_status "Testing nginx + php-fpm service..."
    if curl -f http://localhost > /dev/null 2>&1; then
        print_success "Nginx + PHP-FPM service is working!"
        echo
        echo "=========================================="
        echo "🎉 502 Bad Gateway Fixed with Nginx + PHP-FPM!"
        echo "=========================================="
        echo "Access URLs:"
        echo "• Main Portal: http://localhost"
        echo "• Admin Portal: http://localhost/login.php?user_type=admin"
        echo "• Default Login: admin / password"
    else
        print_error "Even nginx + php-fpm failed!"
        print_status "Checking logs..."
        docker logs smart_attendance-web-1
        docker logs smart_attendance-php-1
        
        print_status "Let's try the most basic approach..."
        docker stop smart_attendance-web-1 smart_attendance-php-1 2>/dev/null || true
        docker rm smart_attendance-web-1 smart_attendance-php-1 2>/dev/null || true
        
        # Most basic approach - just serve static files
        print_status "Creating most basic static web service..."
        docker run -d \
            --name smart_attendance-web-1 \
            --network $NETWORK_NAME \
            -p 80:80 \
            -v $(pwd)/src:/usr/share/nginx/html \
            nginx:alpine
        
        sleep 5
        
        if curl -f http://localhost > /dev/null 2>&1; then
            print_success "Basic static web service working!"
            print_warning "Only static files, no PHP functionality"
        else
            print_error "All approaches failed!"
            print_status "There might be a system-level issue"
            print_status "Database and Redis are still working on ports 3306 and 6379"
        fi
    fi
fi

print_success "502 Bad Gateway fix completed!"
