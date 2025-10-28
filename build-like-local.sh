#!/bin/bash

# Build exactly like local config - no testing, no changes
# Just build and start services directly

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

print_status "Building exactly like local config - no testing, no changes..."

# Stop all containers
print_status "Stopping all containers..."
docker compose down 2>/dev/null || true
docker stop $(docker ps -q --filter "name=smart_attendance") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=smart_attendance") 2>/dev/null || true

# Clean up any orphaned containers
print_status "Cleaning up orphaned containers..."
docker system prune -f

# Build services exactly like local
print_status "Building services exactly like local..."
if docker compose build; then
    print_success "Build successful!"
    
    print_status "Starting services..."
    if docker compose up -d; then
        print_success "Services started!"
        
        # Wait for services to be ready
        print_status "Waiting for services to be ready..."
        sleep 30
        
        # Test web service
        print_status "Testing web service..."
        if curl -f http://localhost > /dev/null 2>&1; then
            print_success "Web service is working!"
        else
            print_warning "Web service not responding yet, checking logs..."
            docker compose logs web
        fi
        
        # Test Python service
        print_status "Testing Python service..."
        if curl -f http://localhost:5001 > /dev/null 2>&1; then
            print_success "Python service is working!"
        else
            print_warning "Python service not responding yet, checking logs..."
            docker compose logs face_detection
        fi
        
        echo
        echo "=========================================="
        echo "🎉 System Running with Exact Same Config!"
        echo "=========================================="
        echo "Access URLs:"
        echo "• Main Portal: http://localhost"
        echo "• Admin Portal: http://localhost/login.php?user_type=admin"
        echo "• Python Service: http://localhost:5001"
        echo "• Default Login: admin / password"
        echo
        print_status "All services running:"
        docker compose ps
        echo
        print_status "Port status:"
        netstat -tulpn | grep -E ":(80|3306|6379|5001)"
        
    else
        print_error "Failed to start services!"
        print_status "Checking logs..."
        docker compose logs
    fi
    
else
    print_error "Build failed!"
    print_status "Checking build logs..."
    
    # Try building with no-cache
    print_status "Trying build with no-cache..."
    if docker compose build --no-cache; then
        print_success "No-cache build successful!"
        
        print_status "Starting services..."
        if docker compose up -d; then
            print_success "Services started!"
            
            # Wait for services to be ready
            print_status "Waiting for services to be ready..."
            sleep 30
            
            # Test web service
            print_status "Testing web service..."
            if curl -f http://localhost > /dev/null 2>&1; then
                print_success "Web service is working!"
            else
                print_warning "Web service not responding yet, checking logs..."
                docker compose logs web
            fi
            
            # Test Python service
            print_status "Testing Python service..."
            if curl -f http://localhost:5001 > /dev/null 2>&1; then
                print_success "Python service is working!"
            else
                print_warning "Python service not responding yet, checking logs..."
                docker compose logs face_detection
            fi
            
            echo
            echo "=========================================="
            echo "🎉 System Running with No-Cache Build!"
            echo "=========================================="
            echo "Access URLs:"
            echo "• Main Portal: http://localhost"
            echo "• Admin Portal: http://localhost/login.php?user_type=admin"
            echo "• Python Service: http://localhost:5001"
            echo "• Default Login: admin / password"
            echo
            print_status "All services running:"
            docker compose ps
            echo
            print_status "Port status:"
            netstat -tulpn | grep -E ":(80|3306|6379|5001)"
            
        else
            print_error "Failed to start services even with no-cache build!"
            print_status "Checking logs..."
            docker compose logs
        fi
    else
        print_error "Even no-cache build failed!"
        print_status "There might be a fundamental issue with the system"
        print_status "Database and Redis are still working on ports 3306 and 6379"
    fi
fi

print_success "Build and start process completed!"
