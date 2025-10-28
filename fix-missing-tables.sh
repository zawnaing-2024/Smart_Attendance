#!/bin/bash

# Fix missing database tables
# The database exists but tables are missing

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

print_status "Fixing missing database tables..."

# Check if database container is running
if ! docker ps | grep -q "smart_attendance-db"; then
    print_error "Database container is not running!"
    exit 1
fi

print_success "Database container is running!"

# Check if database exists
print_status "Checking if database exists..."
if docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; SELECT 1;" 2>/dev/null; then
    print_success "Database 'smart_attendance' exists!"
else
    print_warning "Database 'smart_attendance' does not exist. Creating..."
    docker exec smart_attendance-db-1 mysql -u root -proot_password -e "CREATE DATABASE IF NOT EXISTS smart_attendance;" 2>/dev/null
    print_success "Database created!"
fi

# Check if tables exist
print_status "Checking if tables exist..."
if docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; SHOW TABLES;" 2>/dev/null | grep -q "admin_users"; then
    print_success "Tables exist!"
else
    print_warning "Tables do not exist. Initializing database..."
    
    # Check if init.sql exists
    if [ -f "database/init.sql" ]; then
        print_status "Found init.sql file. Initializing database..."
        docker exec -i smart_attendance-db-1 mysql -u root -proot_password smart_attendance < database/init.sql
        print_success "Database initialized with init.sql!"
    else
        print_warning "init.sql file not found. Creating tables manually..."
        
        # Create tables manually
        docker exec smart_attendance-db-1 mysql -u root -proot_password smart_attendance -e "
        CREATE TABLE IF NOT EXISTS admin_users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            password VARCHAR(255) NOT NULL,
            email VARCHAR(100),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        INSERT IGNORE INTO admin_users (username, password, email) VALUES 
        ('admin', '\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin@example.com');
        
        CREATE TABLE IF NOT EXISTS teachers (
            id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            password VARCHAR(255) NOT NULL,
            email VARCHAR(100),
            position VARCHAR(100),
            grade_id INT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        CREATE TABLE IF NOT EXISTS students (
            id INT AUTO_INCREMENT PRIMARY KEY,
            roll_number VARCHAR(20) UNIQUE NOT NULL,
            name VARCHAR(100) NOT NULL,
            grade VARCHAR(20),
            face_photo_path VARCHAR(255),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        CREATE TABLE IF NOT EXISTS cameras (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            location VARCHAR(100),
            rtsp_url VARCHAR(255),
            username VARCHAR(50),
            password VARCHAR(50),
            is_active BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        CREATE TABLE IF NOT EXISTS grades (
            id INT AUTO_INCREMENT PRIMARY KEY,
            grade_name VARCHAR(50) UNIQUE NOT NULL,
            description TEXT,
            is_active BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        INSERT IGNORE INTO grades (grade_name, description) VALUES 
        ('Grade 1', 'First Grade'),
        ('Grade 2', 'Second Grade'),
        ('Grade 3', 'Third Grade'),
        ('Grade 4', 'Fourth Grade'),
        ('Grade 5', 'Fifth Grade');
        
        CREATE TABLE IF NOT EXISTS attendance (
            id INT AUTO_INCREMENT PRIMARY KEY,
            student_id INT,
            camera_id INT,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            status ENUM('present', 'absent') DEFAULT 'present',
            confidence_score DECIMAL(5,2),
            FOREIGN KEY (student_id) REFERENCES students(id),
            FOREIGN KEY (camera_id) REFERENCES cameras(id)
        );
        
        CREATE TABLE IF NOT EXISTS system_settings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            setting_key VARCHAR(100) UNIQUE NOT NULL,
            setting_value TEXT,
            description TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        );
        
        INSERT IGNORE INTO system_settings (setting_key, setting_value, description) VALUES 
        ('attendance_threshold', '0.6', 'Face recognition confidence threshold'),
        ('sms_enabled', 'false', 'Enable SMS notifications'),
        ('auto_confirm_attendance', 'true', 'Automatically confirm attendance'),
        ('attendance_timeout', '30', 'Attendance confirmation timeout in minutes'),
        ('detection_enabled', 'true', 'Enable face detection system'),
        ('live_view_always_on', 'true', 'Keep camera live view always visible');
        "
        print_success "Database tables created manually!"
    fi
fi

# Verify tables exist
print_status "Verifying tables exist..."
if docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; SHOW TABLES;" 2>/dev/null | grep -q "admin_users"; then
    print_success "Tables verified! Database is ready!"
else
    print_error "Tables still don't exist. There might be an issue with the database initialization."
    exit 1
fi

# Test admin user
print_status "Testing admin user..."
if docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; SELECT username FROM admin_users WHERE username='admin';" 2>/dev/null | grep -q "admin"; then
    print_success "Admin user exists!"
else
    print_warning "Admin user not found. Creating..."
    docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; INSERT IGNORE INTO admin_users (username, password, email) VALUES ('admin', '\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin@example.com');" 2>/dev/null
    print_success "Admin user created!"
fi

# Restart web container
print_status "Restarting web container..."
docker compose restart web
sleep 10

# Test web service
print_status "Testing web service..."
if curl -f http://localhost > /dev/null 2>&1; then
    print_success "Web service is working!"
else
    print_warning "Web service not responding. Checking logs..."
    docker logs smart_attendance-web-1 | tail -10
fi

# Test admin login page
print_status "Testing admin login page..."
if curl -s http://localhost/login.php?user_type=admin | grep -q "Smart Attendance"; then
    print_success "Admin login page is working!"
else
    print_warning "Admin login page not working. Checking for errors..."
    curl -s http://localhost/login.php?user_type=admin | head -10
fi

print_success "Database tables fix completed!"
echo ""
echo "Your system is now ready!"
echo "Access: http://localhost/login.php?user_type=admin"
echo "Login: admin / password"
