#!/bin/bash

# Simple web-only fix using nginx + php-fpm
# This avoids Apache and uses a more reliable PHP setup

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

print_status "Creating simple web-only system with nginx + php-fpm..."

# Stop current services
docker compose down

# Create simple docker-compose with nginx + php-fpm
print_status "Creating docker-compose with nginx + php-fpm..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./src:/var/www/html
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - php
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

# Create nginx configuration
print_status "Creating nginx configuration..."
cat > nginx.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

print_status "Starting web system with nginx + php-fpm..."
if docker compose up -d; then
    print_success "Web system started successfully!"
    echo
    echo "=========================================="
    echo "🎉 Web System is running!"
    echo "=========================================="
    echo "Access URLs:"
    echo "• Main Portal: http://localhost:8080"
    echo "• Admin Portal: http://localhost:8080/login.php?user_type=admin"
    echo "• Default Login: admin / password"
    echo
    print_status "Services running:"
    docker compose ps
else
    print_error "Nginx + PHP-FPM also failed. Let's try the simplest possible approach..."
    
    # Create ultra-simple PHP setup
    print_status "Creating ultra-simple PHP setup..."
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  web:
    image: php:8.2-cli
    ports:
      - "8080:8000"
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
        apt-get update &&
        apt-get install -y libpng-dev libfreetype6-dev libjpeg62-turbo-dev &&
        docker-php-ext-configure gd --with-freetype --with-jpeg &&
        docker-php-ext-install gd pdo_mysql &&
        chown -R www-data:www-data /var/www/html &&
        chmod -R 755 /var/www/html &&
        mkdir -p /var/www/html/uploads/faces &&
        chown -R www-data:www-data /var/www/html/uploads &&
        cd /var/www/html &&
        php -S 0.0.0.0:8000
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
    
    print_status "Starting ultra-simple PHP setup..."
    if docker compose up -d; then
        print_success "Ultra-simple PHP system started!"
        echo
        echo "=========================================="
        echo "🎉 Simple PHP System is running!"
        echo "=========================================="
        echo "Access URLs:"
        echo "• Main Portal: http://localhost:8080"
        echo "• Admin Portal: http://localhost:8080/login.php?user_type=admin"
        echo "• Default Login: admin / password"
        echo
        print_warning "Note: Using PHP built-in server"
        print_warning "This is for development/testing only"
    else
        print_error "All web approaches failed!"
        print_status "Database and Redis are still running"
        print_status "You can access MySQL directly on port 3306"
        print_status "Try installing PHP on the host system instead"
    fi
fi

print_success "Fix completed!"
