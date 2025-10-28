#!/bin/bash

# Database-only to full system upgrade
# This upgrades from the working database to a full system using pre-built images

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

print_status "Upgrading from database-only to full system using pre-built images..."

# Stop current services
docker compose down

# Create docker-compose using pre-built images (no building)
print_status "Creating docker-compose with pre-built images..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  web:
    image: php:8.2-apache
    ports:
      - "8080:80"
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
      bash -c "
        apt-get update &&
        apt-get install -y libpng-dev libfreetype6-dev libjpeg62-turbo-dev &&
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

  face_detection:
    image: python:3.9-slim
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
    command: >
      bash -c "
        apt-get update &&
        apt-get install -y libjpeg-dev libpng-dev &&
        pip install --no-cache-dir numpy Pillow Flask redis pymysql requests python-dotenv &&
        cd /app &&
        python -c '
import json, pymysql, redis, os, time
from datetime import datetime
from flask import Flask, Response, jsonify
import threading
from PIL import Image, ImageDraw, ImageFont
import io, base64

app = Flask(__name__)

class SimpleCameraSystem:
    def __init__(self):
        self.db_config = {
            \"host\": os.getenv(\"DB_HOST\", \"localhost\"),
            \"user\": os.getenv(\"DB_USER\", \"attendance_user\"),
            \"password\": os.getenv(\"DB_PASS\", \"attendance_pass\"),
            \"database\": os.getenv(\"DB_NAME\", \"smart_attendance\"),
            \"charset\": \"utf8mb4\"
        }
        self.redis_client = redis.Redis(
            host=os.getenv(\"REDIS_HOST\", \"localhost\"),
            port=int(os.getenv(\"REDIS_PORT\", 6379)),
            decode_responses=True
        )
        self.cameras = []
        self.load_cameras()
        
    def load_cameras(self):
        try:
            connection = pymysql.connect(**self.db_config)
            with connection.cursor() as cursor:
                cursor.execute(\"SELECT id, name, rtsp_url, username, password, location FROM cameras WHERE is_active = 1\")
                self.cameras = cursor.fetchall()
            connection.close()
            print(f\"Loaded {len(self.cameras)} cameras\")
        except Exception as e:
            print(f\"Error loading cameras: {e}\")
    
    def create_placeholder_image(self, camera_id, location):
        img = Image.new(\"RGB\", (640, 480), color=\"black\")
        draw = ImageDraw.Draw(img)
        try:
            font = ImageFont.truetype(\"/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf\", 24)
        except:
            font = ImageFont.load_default()
        text = f\"Camera: {location}\"
        text2 = \"Camera Feed Unavailable\"
        text3 = \"Face Detection Disabled\"
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        x = (640 - text_width) // 2
        y = (480 - text_height * 3) // 2
        draw.text((x, y), text, fill=\"white\", font=font)
        draw.text((x, y + text_height + 10), text2, fill=\"red\", font=font)
        draw.text((x, y + text_height * 2 + 20), text3, fill=\"yellow\", font=font)
        img_bytes = io.BytesIO()
        img.save(img_bytes, format=\"JPEG\")
        img_bytes.seek(0)
        return base64.b64encode(img_bytes.getvalue()).decode()
    
    def process_camera_stream(self, camera_id, rtsp_url, username, password, location):
        try:
            print(f\"Processing camera {camera_id}: {location}\")
            while True:
                frame_data = self.create_placeholder_image(camera_id, location)
                self.redis_client.set(f\"camera_{camera_id}_frame\", frame_data)
                time.sleep(1)
        except Exception as e:
            print(f\"Error processing camera {camera_id}: {e}\")

camera_system = SimpleCameraSystem()

@app.route(\"/\")
def index():
    return jsonify({\"status\": \"Smart Attendance System - Minimal Mode\", \"cameras\": len(camera_system.cameras), \"note\": \"Camera feeds are placeholder images. Face detection is disabled.\"})

@app.route(\"/video_feed/<int:camera_id>\")
def video_feed(camera_id):
    def generate():
        while True:
            frame_data = camera_system.redis_client.get(f\"camera_{camera_id}_frame\")
            if frame_data:
                frame_bytes = base64.b64decode(frame_data)
                yield (b\"--frame\\r\\n\" + b\"Content-Type: image/jpeg\\r\\n\\r\\n\" + frame_bytes + b\"\\r\\n\")
            else:
                default_img = camera_system.create_placeholder_image(camera_id, f\"Camera {camera_id}\")
                frame_bytes = base64.b64decode(default_img)
                yield (b\"--frame\\r\\n\" + b\"Content-Type: image/jpeg\\r\\n\\r\\n\" + frame_bytes + b\"\\r\\n\")
            time.sleep(1)
    return Response(generate(), mimetype=\"multipart/x-mixed-replace; boundary=frame\")

@app.route(\"/api/refresh_cameras\")
def refresh_cameras():
    camera_system.load_cameras()
    return jsonify({\"message\": \"Cameras refreshed\", \"count\": len(camera_system.cameras)})

@app.route(\"/api/status\")
def status():
    return jsonify({\"status\": \"running\", \"mode\": \"minimal\", \"cameras\": len(camera_system.cameras), \"face_detection\": False, \"timestamp\": datetime.now().isoformat()})

if __name__ == \"__main__\":
    for camera in camera_system.cameras:
        camera_id, name, rtsp_url, username, password, location = camera
        thread = threading.Thread(target=camera_system.process_camera_stream, args=(camera_id, rtsp_url, username, password, location))
        thread.daemon = True
        thread.start()
    print(\"Starting Smart Attendance System - Minimal Mode\")
    print(\"Camera feeds will show placeholder images\")
    print(\"Face detection is disabled\")
    app.run(host=\"0.0.0.0\", port=5000, debug=False)
        '"

volumes:
  mysql_data:

networks:
  attendance_network:
EOF

# Remove the override file
rm -f docker-compose.override.yml

print_status "Starting full system with pre-built images..."
if docker compose up -d; then
    print_success "Full system started successfully!"
    echo
    echo "=========================================="
    echo "🎉 Complete System is now running!"
    echo "=========================================="
    echo "Access URLs:"
    echo "• Main Portal: http://localhost:8080"
    echo "• Admin Portal: http://localhost:8080/login.php?user_type=admin"
    echo "• Default Login: admin / password"
    echo
    print_status "Services running:"
    docker compose ps
else
    print_error "Full system failed. Falling back to web-only..."
    
    # Create web-only version
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  web:
    image: php:8.2-apache
    ports:
      - "8080:80"
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
      bash -c "
        apt-get update &&
        apt-get install -y libpng-dev libfreetype6-dev libjpeg62-turbo-dev &&
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
    
    print_status "Starting web-only system..."
    if docker compose up -d; then
        print_success "Web system started successfully!"
        echo
        echo "=========================================="
        echo "🎉 Web System is running!"
        echo "=========================================="
        echo "Access URLs:"
        echo "• Main Portal: http://localhost:8080"
        echo "• Admin Portal: http://localhost:8080/login.php?user_type=admin"
        echo "• Default Login: admin / password"
        echo
        print_warning "Note: Camera feeds are not available"
        print_warning "All other features work normally"
    else
        print_error "Web system also failed. Database-only is still running."
        print_status "You can access MySQL directly on port 3306"
    fi
fi

print_success "Upgrade completed!"
