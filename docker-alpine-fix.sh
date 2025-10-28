#!/bin/bash

# Docker-only solution using Alpine Linux (more reliable)
# This uses Alpine-based images which have fewer package conflicts

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

print_status "Creating Docker solution using Alpine Linux..."

# Stop current services
docker compose down

# Create docker-compose using Alpine-based images
print_status "Creating docker-compose with Alpine-based images..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  web:
    image: php:8.2-fpm-alpine
    ports:
      - "8080:80"
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

print_status "Starting Docker system with Alpine Linux..."
if docker compose up -d; then
    print_success "Docker system started successfully!"
    echo
    echo "=========================================="
    echo "🎉 Complete Docker System is running!"
    echo "=========================================="
    echo "Access URLs:"
    echo "• Main Portal: http://localhost:8080"
    echo "• Admin Portal: http://localhost:8080/login.php?user_type=admin"
    echo "• Default Login: admin / password"
    echo
    print_status "Services running:"
    docker compose ps
else
    print_error "Alpine approach failed. Trying with Ubuntu-based PHP..."
    
    # Try with Ubuntu-based PHP but simpler
    print_status "Creating Ubuntu-based PHP with minimal packages..."
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  web:
    image: ubuntu:22.04
    ports:
      - "8080:80"
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
      bash -c "
        apt-get update &&
        apt-get install -y php8.1 php8.1-fpm php8.1-mysql php8.1-gd nginx &&
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
        }' > /etc/nginx/sites-available/default &&
        chown -R www-data:www-data /var/www/html &&
        chmod -R 755 /var/www/html &&
        mkdir -p /var/www/html/uploads/faces &&
        chown -R www-data:www-data /var/www/html/uploads &&
        service php8.1-fpm start &&
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
    
    print_status "Starting Ubuntu-based PHP system..."
    if docker compose up -d; then
        print_success "Ubuntu-based PHP system started!"
        echo
        echo "=========================================="
        echo "🎉 Docker System is running!"
        echo "=========================================="
        echo "Access URLs:"
        echo "• Main Portal: http://localhost:8080"
        echo "• Admin Portal: http://localhost:8080/login.php?user_type=admin"
        echo "• Default Login: admin / password"
        echo
        print_status "Services running:"
        docker compose ps
    else
        print_error "All Docker approaches failed!"
        print_status "Database and Redis are still running"
        print_status "You can access MySQL directly on port 3306"
        print_status "Check logs: docker compose logs web"
    fi
fi

print_success "Docker fix completed!"
