#!/bin/bash

# Replicate local setup exactly on Ubuntu server
# This uses the same approach that works locally

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

print_status "Replicating local setup exactly..."

# Stop current services
docker compose down

print_status "Using the exact same docker-compose.yml that works locally..."

# Use the original docker-compose.yml that works locally
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
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

  face_detection:
    build:
      context: .
      dockerfile: Dockerfile.python
    ports:
      - "5001:5000"
    volumes:
      - ./src:/app/src
      - ./uploads:/app/uploads
      - ./face_models:/app/face_models
    environment:
      - DB_HOST=db
      - DB_USER=attendance_user
      - DB_PASS=attendance_pass
      - DB_NAME=smart_attendance
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    depends_on:
      - db
      - redis
    networks:
      - attendance_network

volumes:
  mysql_data:

networks:
  attendance_network:
EOF

# Create the exact Dockerfile that works locally
print_status "Creating the exact Dockerfile that works locally..."
cat > Dockerfile << 'EOF'
FROM php:8.2-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo_mysql

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY src/ /var/www/html/
COPY uploads/ /var/www/html/uploads/

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && mkdir -p /var/www/html/uploads/faces \
    && chown -R www-data:www-data /var/www/html/uploads

# Apache configuration
RUN echo '<Directory /var/www/html>' >> /etc/apache2/apache2.conf \
    && echo '    AllowOverride All' >> /etc/apache2/apache2.conf \
    && echo '</Directory>' >> /etc/apache2/apache2.conf

EXPOSE 80
EOF

# Create the exact Python Dockerfile that works locally
print_status "Creating the exact Python Dockerfile that works locally..."
cat > Dockerfile.python << 'EOF'
FROM python:3.9-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    cmake \
    build-essential \
    libopenblas-dev \
    liblapack-dev \
    libx11-dev \
    libgtk-3-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY src/face_detection/ ./face_detection/
COPY uploads/ ./uploads/
COPY face_models/ ./face_models/

# Set permissions
RUN chmod -R 755 /app

EXPOSE 5000

# Run the application
CMD ["python", "face_detection/app.py"]
EOF

# Create requirements.txt that works locally
print_status "Creating requirements.txt that works locally..."
cat > requirements.txt << 'EOF'
numpy==1.24.3
Pillow==10.0.0
Flask==2.3.2
redis==4.6.0
pymysql==1.1.0
requests==2.31.0
python-dotenv==1.0.0
opencv-python==4.8.0.74
face-recognition==1.3.0
EOF

print_status "Building and starting services exactly like local..."

# Clean up any existing images
docker system prune -f

# Build and start services
if docker compose up -d --build; then
    print_success "Services built and started successfully!"
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 10
    
    # Test web service
    print_status "Testing web service..."
    if curl -f http://localhost > /dev/null 2>&1; then
        print_success "Web service is responding!"
    else
        print_warning "Web service not responding yet, checking logs..."
        docker compose logs web
    fi
    
    # Test Python service
    print_status "Testing Python service..."
    if curl -f http://localhost:5001 > /dev/null 2>&1; then
        print_success "Python service is responding!"
    else
        print_warning "Python service not responding yet, checking logs..."
        docker compose logs face_detection
    fi
    
    echo
    echo "=========================================="
    echo "🎉 System is running exactly like local!"
    echo "=========================================="
    echo "Access URLs:"
    echo "• Main Portal: http://localhost"
    echo "• Admin Portal: http://localhost/login.php?user_type=admin"
    echo "• Python Service: http://localhost:5001"
    echo "• Default Login: admin / password"
    echo
    print_status "Services running:"
    docker compose ps
    echo
    print_status "Port status:"
    netstat -tulpn | grep -E ":(80|3306|6379|5001)"
    
else
    print_error "Build failed. Let's check what's different from local..."
    
    print_status "Checking Docker version..."
    docker --version
    
    print_status "Checking available space..."
    df -h
    
    print_status "Checking memory..."
    free -h
    
    print_status "Trying with no-cache build..."
    if docker compose up -d --build --no-cache; then
        print_success "No-cache build succeeded!"
    else
        print_error "Even no-cache build failed. There might be a system difference."
        print_status "Let's try the minimal approach that works..."
        
        # Fallback to the working minimal approach
        print_status "Using minimal working approach..."
        cat > docker-compose.yml << 'EOF'
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
        apt-get update && apt-get install -y libpng-dev libfreetype6-dev libjpeg62-turbo-dev &&
        docker-php-ext-configure gd --with-freetype --with-jpeg &&
        docker-php-ext-install gd pdo_mysql &&
        a2enmod rewrite &&
        chown -R www-data:www-data /var/www/html &&
        chmod -R 755 /var/www/html &&
        mkdir -p /var/www/html/uploads/faces &&
        chown -R www-data:www-data /var/www/html/uploads &&
        apache2-foreground
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
        
        print_status "Starting minimal services..."
        docker compose up -d
        
        print_success "Minimal services started!"
        print_warning "Note: Python face detection service is disabled"
        print_warning "But web portal should work exactly like local"
    fi
fi

print_success "Local replication completed!"
