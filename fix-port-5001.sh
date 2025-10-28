#!/bin/bash

# Fix port 5001 already in use error
# Stop existing containers and start face detection service

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

print_status "Fixing port 5001 already in use error..."

# Check what's using port 5001
print_status "Checking what's using port 5001..."
netstat -tulpn | grep :5001 || print_warning "Port 5001 not found in netstat"

# Check all containers
print_status "Checking all containers..."
docker ps -a

# Stop any containers using port 5001
print_status "Stopping containers using port 5001..."
docker stop $(docker ps -q --filter "publish=5001") 2>/dev/null || true
docker rm $(docker ps -aq --filter "publish=5001") 2>/dev/null || true

# Stop any face detection containers
print_status "Stopping face detection containers..."
docker stop $(docker ps -q --filter "name=face_detection") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=face_detection") 2>/dev/null || true

# Get the network name from existing containers
NETWORK_NAME=$(docker inspect smart_attendance-db-1 --format='{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' 2>/dev/null)

print_status "Using network: $NETWORK_NAME"

# Wait a moment for ports to be released
print_status "Waiting for ports to be released..."
sleep 5

# Check if port 5001 is now free
print_status "Checking if port 5001 is now free..."
if netstat -tulpn | grep :5001; then
    print_warning "Port 5001 is still in use, trying to kill the process..."
    sudo fuser -k 5001/tcp 2>/dev/null || print_warning "Could not kill process on port 5001"
    sleep 5
fi

# Create face detection container
print_status "Creating face detection container..."
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

echo
echo "=========================================="
echo "🎉 Face Detection Service Fixed!"
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

print_success "Port 5001 fix completed!"
