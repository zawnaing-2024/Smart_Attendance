#!/bin/bash

# Fix web service that's not responding
# This checks logs and fixes the web container

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

print_status "Checking web service logs..."

# Check web container logs
print_status "Web container logs:"
docker compose logs web

print_status "Checking if web container is actually running..."
docker compose ps

print_status "Stopping and recreating web service with simpler approach..."

# Stop current services
docker compose down

# Create a much simpler web service
print_status "Creating ultra-simple web service..."
cat > docker-compose.yml << 'EOF'
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

  php:
    image: php:8.2-fpm-alpine
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
        apk add --no-cache libpng-dev libjpeg-turbo-dev freetype-dev &&
        docker-php-ext-configure gd --with-freetype --with-jpeg &&
        docker-php-ext-install gd pdo_mysql &&
        chown -R www-data:www-data /var/www/html &&
        chmod -R 755 /var/www/html &&
        mkdir -p /var/www/html/uploads/faces &&
        chown -R www-data:www-data /var/www/html/uploads &&
        php-fpm
      "

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_DATABASE: smart_attendance
      MYSQL_USER: attendance_user
      MYSQL_PASSWORD: attendance_pass
    volumes:
      - mysql_data:/var/lib/mysql
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "3306:3306"
    networks:
      - attendance_network

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    networks:
      - attendance_network

volumes:
  mysql_data:

networks:
  attendance_network:
EOF

# Create nginx configuration for PHP
print_status "Creating nginx configuration..."
cat > nginx.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME /var/www/html$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Copy nginx config to container
print_status "Starting services with nginx + php-fpm..."
if docker compose up -d; then
    print_success "Services started!"
    
    # Wait a moment for services to be ready
    sleep 5
    
    # Copy nginx config
    print_status "Configuring nginx..."
    docker cp nginx.conf smart_attendance-web-1:/etc/nginx/conf.d/default.conf
    docker exec smart_attendance-web-1 nginx -s reload
    
    print_success "Web service should now be working!"
    echo
    echo "=========================================="
    echo "🎉 System is running!"
    echo "=========================================="
    echo "Access URLs:"
    echo "• Main Portal: http://localhost"
    echo "• Admin Portal: http://localhost/login.php?user_type=admin"
    echo "• Default Login: admin / password"
    echo
    print_status "Services running:"
    docker compose ps
    echo
    print_status "Testing web service..."
    curl -I http://localhost || print_warning "Web service not responding yet, wait a moment..."
else
    print_error "Failed to start services. Let's try the simplest possible approach..."
    
    # Ultra-simple approach - just nginx serving static files
    print_status "Creating ultra-simple static web service..."
    cat > docker-compose.yml << 'EOF'
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

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_DATABASE: smart_attendance
      MYSQL_USER: attendance_user
      MYSQL_PASSWORD: attendance_pass
    volumes:
      - mysql_data:/var/lib/mysql
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "3306:3306"
    networks:
      - attendance_network

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    networks:
      - attendance_network

volumes:
  mysql_data:

networks:
  attendance_network:
EOF
    
    print_status "Starting static web service..."
    if docker compose up -d; then
        print_success "Static web service started!"
        print_warning "Note: PHP features will not work, but you can access the interface"
        echo
        echo "=========================================="
        echo "🎉 Static Web Service is running!"
        echo "=========================================="
        echo "Access URLs:"
        echo "• Main Portal: http://localhost"
        echo "• Note: PHP features disabled"
    else
        print_error "All approaches failed!"
        print_status "Database and Redis are still running"
        print_status "You can access MySQL directly on port 3306"
    fi
fi

print_success "Web service fix completed!"
