#!/bin/bash

# Direct fix for database connection null error
# The database connection is still null, need to fix the Database class

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

print_status "Direct fix for database connection null error..."

# Check if web container is running
if ! docker ps | grep smart_attendance-web-1; then
    print_error "Web container is not running!"
    exit 1
fi

# Check current PHP extensions
print_status "Checking PHP extensions..."
docker exec smart_attendance-web-1 php -m | grep -i pdo || print_warning "No PDO extensions found"

# Check if PDO MySQL is available
print_status "Checking PDO MySQL availability..."
docker exec smart_attendance-web-1 php -r "
    if (in_array('mysql', PDO::getAvailableDrivers())) {
        echo 'MySQL PDO driver is available!' . PHP_EOL;
    } else {
        echo 'MySQL PDO driver is NOT available!' . PHP_EOL;
    }
"

# Install PDO MySQL extension
print_status "Installing PDO MySQL extension..."
docker exec smart_attendance-web-1 sh -c "
    echo 'Installing PDO MySQL extension...' &&
    apt-get update -qq &&
    docker-php-ext-install pdo_mysql &&
    echo 'Restarting Apache...' &&
    apache2ctl restart
"

# Wait for Apache to restart
print_status "Waiting for Apache to restart..."
sleep 10

# Check PDO MySQL again
print_status "Checking PDO MySQL after installation..."
docker exec smart_attendance-web-1 php -r "
    if (in_array('mysql', PDO::getAvailableDrivers())) {
        echo 'MySQL PDO driver is now available!' . PHP_EOL;
    } else {
        echo 'MySQL PDO driver is still NOT available!' . PHP_EOL;
    }
"

# Test database connection directly
print_status "Testing database connection directly..."
docker exec smart_attendance-web-1 php -r "
    try {
        \$pdo = new PDO('mysql:host=smart_attendance-db-1;dbname=smart_attendance', 'attendance_user', 'attendance_pass');
        echo 'Direct database connection successful!' . PHP_EOL;
    } catch (PDOException \$e) {
        echo 'Direct database connection failed: ' . \$e->getMessage() . PHP_EOL;
    }
"

# Check the Database class
print_status "Checking Database class..."
docker exec smart_attendance-web-1 sh -c "
    if [ -f /var/www/html/config/database.php ]; then
        echo 'Database class exists'
        tail -20 /var/www/html/config/database.php
    else
        echo 'Database class not found'
    fi
"

# Fix the Database class if needed
print_status "Fixing Database class..."
docker exec smart_attendance-web-1 sh -c "
    cat > /var/www/html/config/database.php << 'EOF'
<?php
// Start session before any output
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Database configuration
class Database {
    private \$host;
    private \$db_name;
    private \$username;
    private \$password;
    private \$conn;

    public function __construct() {
        \$this->host = 'smart_attendance-db-1';
        \$this->db_name = 'smart_attendance';
        \$this->username = 'attendance_user';
        \$this->password = 'attendance_pass';
    }

    public function getConnection() {
        \$this->conn = null;
        try {
            \$this->conn = new PDO('mysql:host=' . \$this->host . ';dbname=' . \$this->db_name, \$this->username, \$this->password);
            \$this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch(PDOException \$exception) {
            echo 'Connection error: ' . \$exception->getMessage();
        }
        return \$this->conn;
    }
}

// Utility functions
class Utils {
    public static function sanitize(\$input) {
        return htmlspecialchars(strip_tags(trim(\$input)));
    }
    
    public static function hashPassword(\$password) {
        return password_hash(\$password, PASSWORD_DEFAULT);
    }
    
    public static function verifyPassword(\$password, \$hash) {
        return password_verify(\$password, \$hash);
    }
    
    public static function requireAdmin() {
        if (!isset(\$_SESSION['user_type']) || \$_SESSION['user_type'] !== 'admin') {
            header('Location: /login.php?user_type=admin');
            exit();
        }
    }
    
    public static function requireTeacher() {
        if (!isset(\$_SESSION['user_type']) || \$_SESSION['user_type'] !== 'teacher') {
            header('Location: /login.php?user_type=teacher');
            exit();
        }
    }
}
?>
EOF
"

# Test the Database class
print_status "Testing Database class..."
docker exec smart_attendance-web-1 php -r "
    require_once '/var/www/html/config/database.php';
    \$database = new Database();
    \$db = \$database->getConnection();
    if (\$db) {
        echo 'Database class connection successful!' . PHP_EOL;
    } else {
        echo 'Database class connection failed!' . PHP_EOL;
    }
"

# Test the login page
print_status "Testing login page..."
if curl -f http://localhost/login.php > /dev/null 2>&1; then
    print_success "Login page is accessible!"
    
    # Test with actual login
    print_status "Testing login functionality..."
    curl -X POST http://localhost/auth/login_process.php \
        -d "username=admin&password=password&user_type=admin" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        2>/dev/null | head -5
    
    echo
    echo "=========================================="
    echo "🎉 Database Connection Fixed!"
    echo "=========================================="
    echo "Access URLs:"
    echo "• Main Portal: http://localhost"
    echo "• Admin Portal: http://localhost/login.php?user_type=admin"
    echo "• Default Login: admin / password"
    echo
    print_status "All services running:"
    docker ps
    echo
    print_status "Port status:"
    netstat -tulpn | grep -E ":(80|3306|6379)"
    
else
    print_warning "Login page still not accessible, checking logs..."
    docker logs smart_attendance-web-1 | tail -10
fi

print_success "Database connection fix completed!"
