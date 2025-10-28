#!/bin/bash

# Fix database connection issues
# The web service can't connect to MySQL database

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}==========================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}==========================================${NC}"
}

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

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

print_header "Database Connection Fix"
echo "Fixing database connection issues..."
echo ""

# Step 1: Check current container status
print_step "1. Checking current container status..."
docker ps

# Step 2: Check if database container is running
print_step "2. Checking database container..."
if docker ps | grep -q "smart_attendance-db"; then
    print_success "Database container is running!"
else
    print_error "Database container is not running!"
    print_status "Starting database container..."
    docker compose up -d db
    sleep 10
fi

# Step 3: Check database logs
print_step "3. Checking database logs..."
docker logs smart_attendance-db-1 | tail -20

# Step 4: Test database connection
print_step "4. Testing database connection..."
if docker exec smart_attendance-db-1 mysql -u root -proot_password -e "SELECT 1;" 2>/dev/null; then
    print_success "Database is accessible!"
else
    print_warning "Database connection failed. Checking MySQL status..."
    docker exec smart_attendance-db-1 mysqladmin ping -h localhost -u root -proot_password 2>/dev/null || print_warning "MySQL not responding"
fi

# Step 5: Check if database exists
print_step "5. Checking if database exists..."
if docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; SELECT 1;" 2>/dev/null; then
    print_success "Database 'smart_attendance' exists!"
else
    print_warning "Database 'smart_attendance' does not exist. Creating..."
    docker exec smart_attendance-db-1 mysql -u root -proot_password -e "CREATE DATABASE IF NOT EXISTS smart_attendance;" 2>/dev/null
    print_success "Database created!"
fi

# Step 6: Check if tables exist
print_step "6. Checking if tables exist..."
if docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; SHOW TABLES;" 2>/dev/null | grep -q "admin_users"; then
    print_success "Tables exist!"
else
    print_warning "Tables do not exist. Initializing database..."
    docker exec -i smart_attendance-db-1 mysql -u root -proot_password smart_attendance < database/init.sql
    print_success "Database initialized!"
fi

# Step 7: Check web container database connection
print_step "7. Checking web container database connection..."
if docker exec smart_attendance-web-1 php -r "
try {
    \$pdo = new PDO('mysql:host=db;dbname=smart_attendance', 'attendance_user', 'attendance_pass');
    echo 'Database connection successful!';
} catch (Exception \$e) {
    echo 'Database connection failed: ' . \$e->getMessage();
}
" 2>/dev/null; then
    print_success "Web container can connect to database!"
else
    print_warning "Web container cannot connect to database. Checking network..."
    
    # Check if containers are on the same network
    print_status "Checking Docker network..."
    docker network ls
    docker network inspect smart_attendance_attendance_network 2>/dev/null || print_warning "Network not found"
    
    # Check if web container can reach db container
    print_status "Testing network connectivity..."
    docker exec smart_attendance-web-1 ping -c 1 db 2>/dev/null || print_warning "Cannot ping db container"
fi

# Step 8: Restart web container
print_step "8. Restarting web container..."
docker compose restart web
sleep 10

# Step 9: Test web service
print_step "9. Testing web service..."
if curl -f http://localhost > /dev/null 2>&1; then
    print_success "Web service is working!"
    
    # Test login page
    if curl -s http://localhost/login.php | grep -q "Smart Attendance"; then
        print_success "Login page is accessible!"
    else
        print_warning "Login page not accessible. Checking what's being served..."
        curl -s http://localhost | head -5
    fi
else
    print_warning "Web service not responding. Checking logs..."
    docker logs smart_attendance-web-1 | tail -10
fi

# Step 10: Test database connection from web
print_step "10. Testing database connection from web..."
if curl -s http://localhost/login.php?user_type=admin | grep -q "Smart Attendance"; then
    print_success "Admin login page is working!"
else
    print_warning "Admin login page not working. Checking for errors..."
    curl -s http://localhost/login.php?user_type=admin | head -10
fi

print_header "Database Connection Fix Complete!"
echo ""
echo "If the issue persists:"
echo "1. Check database logs: docker logs smart_attendance-db-1"
echo "2. Check web logs: docker logs smart_attendance-web-1"
echo "3. Restart all services: docker compose restart"
echo "4. Check network: docker network inspect smart_attendance_attendance_network"
echo ""
print_success "Database connection fix completed!"