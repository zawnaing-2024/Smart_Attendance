#!/bin/bash

# Smart Attendance System - Production Deployment Script for Ubuntu
# This script deploys the Smart Attendance system on Ubuntu server

set -e

echo "🚀 Deploying Smart Attendance System on Ubuntu..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "📦 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "✅ Docker installed. Please log out and log back in for group changes to take effect."
    exit 0
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "📦 Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose installed"
fi

# Create application directory
APP_DIR="/opt/smart-attendance"
echo "📁 Creating application directory at $APP_DIR..."
sudo mkdir -p $APP_DIR
sudo chown $USER:$USER $APP_DIR

# Copy application files
echo "📋 Copying application files..."
cp -r . $APP_DIR/
cd $APP_DIR

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p uploads/faces
mkdir -p face_models
mkdir -p logs
mkdir -p backups

# Set permissions
chmod 755 uploads/faces
chmod 755 face_models
chmod 755 logs
chmod 755 backups

# Create production environment file
echo "⚙️ Creating production environment configuration..."
cat > .env << EOF
# Database Configuration
DB_HOST=db
DB_USER=attendance_user
DB_PASS=attendance_pass_prod_$(openssl rand -hex 8)
DB_NAME=smart_attendance

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379

# Face Detection Configuration
ATTENDANCE_THRESHOLD=0.6
SMS_ENABLED=true
AUTO_CONFIRM_ATTENDANCE=true
ATTENDANCE_TIMEOUT=30

# Production Settings
DEBUG=false
LOG_LEVEL=WARNING
EOF

# Create production docker-compose override
echo "🐳 Creating production Docker Compose configuration..."
cat > docker-compose.prod.yml << EOF
version: '3.8'

services:
  web:
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./src:/var/www/html
      - ./uploads:/var/www/html/uploads
      - ./logs:/var/log/apache2
    environment:
      - DB_HOST=db
      - DB_USER=attendance_user
      - DB_PASS=\${DB_PASS}
      - DB_NAME=smart_attendance
      - REDIS_HOST=redis
      - REDIS_PORT=6379

  db:
    environment:
      MYSQL_ROOT_PASSWORD=root_password_prod_$(openssl rand -hex 12)
      MYSQL_DATABASE=smart_attendance
      MYSQL_USER=attendance_user
      MYSQL_PASSWORD=\${DB_PASS}
    volumes:
      - mysql_data_prod:/var/lib/mysql
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
      - ./backups:/backups

  face_detection:
    environment:
      - DB_HOST=db
      - DB_USER=attendance_user
      - DB_PASS=\${DB_PASS}
      - DB_NAME=smart_attendance
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    volumes:
      - ./src:/app/src
      - ./uploads:/app/uploads
      - ./face_models:/app/face_models
      - ./logs:/app/logs

volumes:
  mysql_data_prod:
EOF

# Create systemd service file
echo "🔧 Creating systemd service..."
sudo tee /etc/systemd/system/smart-attendance.service > /dev/null << EOF
[Unit]
Description=Smart Attendance System
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$APP_DIR
ExecStart=/usr/local/bin/docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.yml -f docker-compose.prod.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Create backup script
echo "💾 Creating backup script..."
cat > backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/smart-attendance/backups"
DATE=$(date +%Y%m%d_%H%M%S)

echo "Creating backup: $DATE"

# Create database backup
docker-compose exec -T db mysqldump -u root -p$MYSQL_ROOT_PASSWORD smart_attendance > $BACKUP_DIR/database_$DATE.sql

# Create application backup
tar -czf $BACKUP_DIR/application_$DATE.tar.gz src/ uploads/ face_models/ .env

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x backup.sh

# Create update script
echo "🔄 Creating update script..."
cat > update.sh << 'EOF'
#!/bin/bash
echo "Updating Smart Attendance System..."

# Stop services
docker-compose -f docker-compose.yml -f docker-compose.prod.yml down

# Backup current data
./backup.sh

# Pull latest images
docker-compose -f docker-compose.yml -f docker-compose.prod.yml pull

# Rebuild and start services
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up --build -d

echo "Update completed!"
EOF

chmod +x update.sh

# Create monitoring script
echo "📊 Creating monitoring script..."
cat > monitor.sh << 'EOF'
#!/bin/bash
echo "Smart Attendance System Status"
echo "=============================="

# Check Docker containers
echo "Docker Containers:"
docker-compose ps

echo ""
echo "System Resources:"
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "Memory Usage: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "Disk Usage: $(df -h / | awk 'NR==2 {print $5}')"

echo ""
echo "Application Logs (last 10 lines):"
docker-compose logs --tail=10 web
EOF

chmod +x monitor.sh

# Enable and start the service
echo "🚀 Enabling and starting Smart Attendance service..."
sudo systemctl daemon-reload
sudo systemctl enable smart-attendance.service
sudo systemctl start smart-attendance.service

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 60

# Check service status
echo "🔍 Checking service status..."
sudo systemctl status smart-attendance.service --no-pager

# Generate face encodings
echo "🤖 Setting up face recognition system..."
docker-compose -f docker-compose.yml -f docker-compose.prod.yml exec face_detection python generate_face_encodings.py --all

# Create cron job for backups
echo "⏰ Setting up automated backups..."
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/smart-attendance/backup.sh") | crontab -

echo ""
echo "🎉 Smart Attendance System deployed successfully!"
echo ""
echo "📋 Access Information:"
echo "   • Admin Portal: http://$(hostname -I | awk '{print $1}')/login.php"
echo "   • Default Admin Login: admin / admin123"
echo "   • Live View Portal: http://$(hostname -I | awk '{print $1}'):5000"
echo ""
echo "🔧 Management Commands:"
echo "   • Service status: sudo systemctl status smart-attendance"
echo "   • Start service: sudo systemctl start smart-attendance"
echo "   • Stop service: sudo systemctl stop smart-attendance"
echo "   • View logs: docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f"
echo "   • Create backup: ./backup.sh"
echo "   • Update system: ./update.sh"
echo "   • Monitor system: ./monitor.sh"
echo ""
echo "📝 Security Recommendations:"
echo "   1. Change default admin password"
echo "   2. Configure SSL/TLS certificates"
echo "   3. Set up firewall rules"
echo "   4. Configure SMS API credentials"
echo "   5. Set up monitoring and alerting"
echo ""
echo "✨ Deployment complete!"
