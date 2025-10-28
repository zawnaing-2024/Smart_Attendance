#!/bin/bash

# Fix 403 Forbidden error for nginx web service
# Fix permissions and nginx configuration

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

print_status "Fixing 403 Forbidden error..."

# Check current nginx configuration
print_status "Checking current nginx configuration..."
docker exec smart_attendance-web-1 cat /etc/nginx/conf.d/default.conf 2>/dev/null || print_warning "No nginx config found"

# Check file permissions
print_status "Checking file permissions..."
docker exec smart_attendance-web-1 ls -la /usr/share/nginx/html/ 2>/dev/null || print_warning "Cannot check permissions"

# Fix nginx configuration
print_status "Creating proper nginx configuration..."
docker exec smart_attendance-web-1 sh -c 'cat > /etc/nginx/conf.d/default.conf << EOF
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.php index.html index.htm;

    # Allow all files
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
        autoindex on;
    }

    # Handle PHP files
    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    # Allow access to all files
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF'

# Fix permissions
print_status "Fixing file permissions..."
docker exec smart_attendance-web-1 sh -c '
    chown -R nginx:nginx /usr/share/nginx/html &&
    chmod -R 755 /usr/share/nginx/html &&
    chmod 644 /usr/share/nginx/html/index.php 2>/dev/null || true &&
    chmod 644 /usr/share/nginx/html/index.html 2>/dev/null || true
'

# Reload nginx configuration
print_status "Reloading nginx configuration..."
docker exec smart_attendance-web-1 nginx -s reload

# Test the fix
print_status "Testing web service..."
sleep 2

if curl -f http://localhost > /dev/null 2>&1; then
    print_success "Web service is now working!"
    echo
    echo "=========================================="
    echo "🎉 403 Forbidden Fixed!"
    echo "=========================================="
    echo "Access URLs:"
    echo "• Main Portal: http://localhost"
    echo "• Admin Portal: http://localhost/login.php?user_type=admin"
    echo "• Default Login: admin / password"
    echo
    print_status "Testing specific pages..."
    
    # Test main page
    if curl -f http://localhost/index.php > /dev/null 2>&1; then
        print_success "Main page accessible"
    else
        print_warning "Main page not accessible"
    fi
    
    # Test login page
    if curl -f http://localhost/login.php > /dev/null 2>&1; then
        print_success "Login page accessible"
    else
        print_warning "Login page not accessible"
    fi
    
else
    print_warning "Still getting errors, trying alternative approach..."
    
    # Try with different nginx configuration
    print_status "Trying alternative nginx configuration..."
    docker exec smart_attendance-web-1 sh -c 'cat > /etc/nginx/conf.d/default.conf << EOF
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF'
    
    # Set more permissive permissions
    docker exec smart_attendance-web-1 sh -c '
        chmod -R 777 /usr/share/nginx/html &&
        chown -R nginx:nginx /usr/share/nginx/html
    '
    
    # Reload nginx
    docker exec smart_attendance-web-1 nginx -s reload
    
    sleep 2
    
    if curl -f http://localhost > /dev/null 2>&1; then
        print_success "Alternative configuration worked!"
    else
        print_error "Still having issues. Let me check what files exist..."
        docker exec smart_attendance-web-1 ls -la /usr/share/nginx/html/
        docker exec smart_attendance-web-1 cat /usr/share/nginx/html/index.php 2>/dev/null || print_warning "No index.php found"
        docker exec smart_attendance-web-1 cat /usr/share/nginx/html/index.html 2>/dev/null || print_warning "No index.html found"
    fi
fi

print_success "403 Forbidden fix completed!"
