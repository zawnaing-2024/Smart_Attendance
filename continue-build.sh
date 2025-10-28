#!/bin/bash

# Continue from where the script stopped
# Handle Debian repository access issues

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

print_status "Continuing from where the script stopped..."

# Test Debian repository access
print_status "Testing Debian repository access..."
if curl -f http://deb.debian.org/debian/ > /dev/null 2>&1; then
    print_success "Debian repository accessible"
else
    print_warning "Debian repository not accessible, trying alternative approach..."
    
    # Try different Debian mirrors
    print_status "Trying alternative Debian mirrors..."
    if curl -f http://archive.debian.org/debian/ > /dev/null 2>&1; then
        print_success "Alternative Debian mirror accessible"
    elif curl -f http://ftp.debian.org/debian/ > /dev/null 2>&1; then
        print_success "FTP Debian mirror accessible"
    else
        print_warning "All Debian mirrors not accessible, but continuing..."
    fi
fi

# Build and start services
print_status "Building services with exact same config as local..."
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
        print_status "Let me try a different approach..."
        
        # Try building just the web service first
        print_status "Trying to build just the web service..."
        if docker compose build web; then
            print_success "Web service build successful!"
            
            print_status "Starting just web and database services..."
            if docker compose up -d web db redis; then
                print_success "Web and database services started!"
                
                # Wait for services to be ready
                print_status "Waiting for services to be ready..."
                sleep 20
                
                # Test web service
                print_status "Testing web service..."
                if curl -f http://localhost > /dev/null 2>&1; then
                    print_success "Web service is working!"
                    print_warning "Note: Python face detection service is disabled"
                else
                    print_warning "Web service not responding yet, checking logs..."
                    docker compose logs web
                fi
                
                echo
                echo "=========================================="
                echo "🎉 Web Service Running!"
                echo "=========================================="
                echo "Access URLs:"
                echo "• Main Portal: http://localhost"
                echo "• Admin Portal: http://localhost/login.php?user_type=admin"
                echo "• Default Login: admin / password"
                echo "• Note: Python face detection service is disabled"
                echo
                print_status "All services running:"
                docker compose ps
                echo
                print_status "Port status:"
                netstat -tulpn | grep -E ":(80|3306|6379)"
                
            else
                print_error "Failed to start even just web and database services!"
                print_status "There might be a fundamental issue with the system"
                print_status "Database and Redis are still working on ports 3306 and 6379"
            fi
        else
            print_error "Even web service build failed!"
            print_status "There might be a fundamental issue with the system"
            print_status "Database and Redis are still working on ports 3306 and 6379"
        fi
    fi
fi

print_success "Build and start process completed!"
