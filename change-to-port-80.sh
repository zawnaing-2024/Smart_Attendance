#!/bin/bash

# Quick port change from 8080 to 80
# This changes the web service to use port 80 instead of 8080

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

print_status "Changing web service port from 8080 to 80..."

# Stop current services
docker compose down

# Create docker-compose with port 80
print_status "Creating docker-compose with port 80..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  web:
    image: php:8.2-fpm-alpine
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
        apk add --no-cache nginx libpng-dev libjpeg-turbo-dev freetype-dev &&
        docker-php-ext-configure gd --with-freetype --with-jpeg &&
        docker-php-ext-install gd pdo_mysql &&
        chown -R www-data:www-data /var/www/html &&
        chmod -R 755 /var/www/html &&
        mkdir -p /var/www/html/uploads/faces &&
        chown -R www-data:www-data /var/www/html/uploads &&
        echo 'server {
            listen 80;
            server_name localhost;
            root /var/www/html;
            index index.php index.html;
            location / {
                try_files \$uri \$uri/ /index.php?\$query_string;
            }
            location ~ \.php$ {
                fastcgi_pass 127.0.0.1:9000;
                fastcgi_index index.php;
                fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                include fastcgi_params;
            }
        }' > /etc/nginx/http.d/default.conf &&
        php-fpm -D &&
        nginx -g 'daemon off;'
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

print_status "Starting services on port 80..."
if docker compose up -d; then
    print_success "Services started successfully on port 80!"
    echo
    echo "=========================================="
    echo "🎉 System is now running on port 80!"
    echo "=========================================="
    echo "Access URLs:"
    echo "• Main Portal: http://localhost"
    echo "• Admin Portal: http://localhost/login.php?user_type=admin"
    echo "• Default Login: admin / password"
    echo
    print_status "Services running:"
    docker compose ps
    echo
    print_status "Port status:"
    netstat -tulpn | grep -E ":(80|3306|6379|5001)"
else
    print_error "Failed to start on port 80. Port might be in use."
    print_status "Checking what's using port 80..."
    sudo netstat -tulpn | grep :80 || echo "Port 80 appears to be free"
    
    print_warning "Trying with sudo privileges..."
    if sudo docker compose up -d; then
        print_success "Services started with sudo!"
        echo
        echo "=========================================="
        echo "🎉 System is now running on port 80!"
        echo "=========================================="
        echo "Access URLs:"
        echo "• Main Portal: http://localhost"
        echo "• Admin Portal: http://localhost/login.php?user_type=admin"
        echo "• Default Login: admin / password"
    else
        print_error "Still failed. Let's try port 8080 again..."
        sed -i 's/"80:80"/"8080:80"/' docker-compose.yml
        docker compose up -d
        print_warning "Reverted to port 8080: http://localhost:8080"
    fi
fi

print_success "Port change completed!"
