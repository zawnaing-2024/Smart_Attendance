#!/bin/bash

# Fix current issues and start face_detection service
# The web service is still installing packages and face_detection didn't start

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

print_status "Fixing current issues and starting face_detection service..."

# Check current status
print_status "Current container status:"
docker ps

# Stop current containers
print_status "Stopping current containers..."
docker compose down

# Wait a moment
sleep 5

# Start all services including face_detection
print_status "Starting all services including face_detection..."
docker compose up -d

# Wait for services to start
print_status "Waiting for services to start..."
sleep 30

# Check if all containers are running
print_status "Checking if all containers are running..."
docker ps

# Check if face_detection is running
if docker ps | grep face_detection; then
    print_success "Face detection service is running!"
else
    print_warning "Face detection service not running, checking logs..."
    docker logs smart_attendance-face_detection-1 2>/dev/null || print_warning "No face detection logs found"
    
    # Try to start face_detection manually
    print_status "Trying to start face_detection manually..."
    docker compose up -d face_detection
    sleep 20
fi

# Test web service
print_status "Testing web service..."
if curl -f http://localhost > /dev/null 2>&1; then
    print_success "Web service is working!"
    
    # Check if it's serving the PHP app
    if curl -s http://localhost | grep -q "Smart Attendance"; then
        print_success "PHP app is being served!"
    else
        print_warning "Still serving default page, checking what's being served..."
        curl -s http://localhost | head -5
    fi
else
    print_warning "Web service not responding, checking logs..."
    docker logs smart_attendance-web-1 | tail -10
    
    # Check if Apache is running inside container
    print_status "Checking if Apache is running inside container..."
    docker exec smart_attendance-web-1 ps aux | grep apache || print_warning "Apache not running"
    
    # Check Apache error logs
    print_status "Checking Apache error logs..."
    docker exec smart_attendance-web-1 tail -20 /var/log/apache2/error.log 2>/dev/null || print_warning "No Apache error logs"
    
    # Try to start Apache manually
    print_status "Trying to start Apache manually..."
    docker exec smart_attendance-web-1 apache2ctl start 2>/dev/null || print_warning "Cannot start Apache manually"
    
    sleep 10
    
    # Test web service again
    print_status "Testing web service again..."
    if curl -f http://localhost > /dev/null 2>&1; then
        print_success "Web service is now working!"
    else
        print_error "Web service still not working!"
        print_status "There might be a fundamental issue with the web container"
    fi
fi

# Test Python service
print_status "Testing Python service..."
if curl -f http://localhost:5001 > /dev/null 2>&1; then
    print_success "Python service is working!"
else
    print_warning "Python service not responding, checking logs..."
    docker logs smart_attendance-face_detection-1 | tail -10
    
    # Check if Python is running inside container
    print_status "Checking if Python is running inside container..."
    docker exec smart_attendance-face_detection-1 ps aux | grep python || print_warning "Python not running"
fi

echo
echo "=========================================="
echo "🎉 Services Status Check Completed!"
echo "=========================================="
echo "Access URLs:"
echo "• Main Portal: http://localhost"
echo "• Admin Portal: http://localhost/login.php?user_type=admin"
echo "• Python Service: http://localhost:5001"
echo "• Default Login: admin / password"
echo
print_status "All services running:"
docker ps
echo
print_status "Port status:"
netstat -tulpn | grep -E ":(80|3306|6379|5001)" 2>/dev/null || print_warning "netstat not available"

print_success "Services status check completed!"
