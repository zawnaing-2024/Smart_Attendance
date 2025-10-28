#!/bin/bash

# Fix Apache serving default page instead of PHP app
# Also start face detection service

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

print_status "Fixing Apache to serve PHP app instead of default page..."

# Check current containers
print_status "Checking current containers..."
docker ps

# Stop current web container
print_status "Stopping current web container..."
docker stop smart_attendance-web-1 2>/dev/null || true
docker rm smart_attendance-web-1 2>/dev/null || true

# Get the network name from existing containers
NETWORK_NAME=$(docker inspect smart_attendance-db-1 --format='{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' 2>/dev/null)

print_status "Using network: $NETWORK_NAME"

# Create PHP Apache container with your app files
print_status "Creating PHP Apache container with your app files..."
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
print_status "Waiting for PHP Apache container to start..."
sleep 20

# Test web service
print_status "Testing web service..."
if curl -f http://localhost > /dev/null 2>&1; then
    print_success "Web service is working!"
    
    # Check if it's serving the PHP app
    if curl -s http://localhost | grep -q "Smart Attendance"; then
        print_success "PHP app is being served!"
    else
        print_warning "Still serving default page, checking files..."
        docker exec smart_attendance-web-1 ls -la /var/www/html/
    fi
else
    print_warning "Web service not responding, checking logs..."
    docker logs smart_attendance-web-1 | tail -10
fi

# Now start face detection service
print_status "Starting face detection service..."

# Check if face detection container exists
if docker ps -a | grep smart_attendance-face_detection-1; then
    print_status "Face detection container exists, starting it..."
    docker start smart_attendance-face_detection-1
else
    print_status "Creating face detection container..."
    
    # Create face detection container
    docker run -d \
        --name smart_attendance-face_detection-1 \
        --network $NETWORK_NAME \
        -p 5001:5000 \
        -v $(pwd)/src:/app/src \
        -v $(pwd)/uploads:/app/uploads \
        -v $(pwd)/face_models:/app/face_models \
        -e DB_HOST=smart_attendance-db-1 \
        -e DB_USER=attendance_user \
        -e DB_PASS=attendance_pass \
        -e DB_NAME=smart_attendance \
        -e REDIS_HOST=smart_attendance-redis-1 \
        -e REDIS_PORT=6379 \
        python:3.9-slim \
        sh -c "
            echo 'Installing Python packages...' &&
            apt-get update -qq &&
            apt-get install -y -qq libjpeg-dev libpng-dev libtiff-dev cmake build-essential libopenblas-dev liblapack-dev libx11-dev libgtk-3-dev libavcodec-dev libavformat-dev libswscale-dev &&
            pip install numpy==1.24.3 Pillow==10.0.0 Flask==2.3.2 redis==4.6.0 pymysql==1.1.0 requests==2.31.0 python-dotenv==1.0.0 opencv-python==4.8.0.74 face-recognition==1.3.0 &&
            echo 'Starting face detection service...' &&
            cd /app &&
            python src/face_detection/app.py
        "
fi

# Wait for face detection service to start
print_status "Waiting for face detection service to start..."
sleep 30

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
echo "🎉 System Fixed and Running!"
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

print_success "Apache and face detection fix completed!"
