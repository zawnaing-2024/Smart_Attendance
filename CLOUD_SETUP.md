# Smart Attendance Management System - Cloud VM Setup

## 🚀 Complete Installation Guide

This guide will help you install the Smart Attendance Management System on your cloud VM exactly like your local setup.

## 📋 Prerequisites

- Ubuntu 20.04+ or Debian 11+ cloud VM
- Root or sudo access
- Internet connection
- At least 2GB RAM and 10GB disk space

## 🛠️ Quick Installation

### Option 1: One-Command Installation
```bash
# Download and run the complete setup script
curl -fsSL https://raw.githubusercontent.com/zawnaing-2024/Smart_Attendance/main/complete-cloud-setup.sh | bash
```

### Option 2: Manual Installation
```bash
# Clone the repository
git clone https://github.com/zawnaing-2024/Smart_Attendance.git
cd Smart_Attendance

# Make scripts executable
chmod +x *.sh

# Run the complete setup
./complete-cloud-setup.sh
```

## 🔧 What the Setup Script Does

### 1. System Updates
- Updates all system packages
- Installs essential tools (git, curl, wget, etc.)

### 2. Docker Installation
- Installs Docker CE and Docker Compose
- Adds user to docker group
- Configures Docker for the project

### 3. Repository Setup
- Clones the Smart Attendance repository
- Fixes git ownership issues
- Makes all scripts executable

### 4. Service Deployment
- Builds all Docker containers (web, db, redis, face_detection)
- Starts all services with proper networking
- Waits for services to be ready

### 5. Service Testing
- Tests web service on port 80
- Tests Python face detection service on port 5001
- Verifies all services are working

## 🌐 Access URLs

After installation, you can access:

- **Main Portal**: http://your-vm-ip
- **Admin Portal**: http://your-vm-ip/login.php?user_type=admin
- **Teacher Portal**: http://your-vm-ip/login.php?user_type=teacher
- **Python Service**: http://your-vm-ip:5001

## 🔐 Default Login Credentials

- **Admin Username**: `admin`
- **Admin Password**: `password`

## 📊 Service Architecture

The system consists of 4 main services:

### 1. Web Service (PHP/Apache)
- **Port**: 80
- **Technology**: PHP 8.2 + Apache
- **Purpose**: Admin and Teacher portals
- **Features**: User management, student management, camera management, settings

### 2. Database Service (MySQL)
- **Port**: 3306
- **Technology**: MySQL 8.0
- **Purpose**: Data storage
- **Tables**: admins, teachers, students, cameras, attendance, grades, etc.

### 3. Cache Service (Redis)
- **Port**: 6379
- **Technology**: Redis 7
- **Purpose**: Caching and session management
- **Features**: Fast data access, session storage

### 4. Face Detection Service (Python)
- **Port**: 5001
- **Technology**: Python 3.9 + Flask + OpenCV
- **Purpose**: Real-time face detection and recognition
- **Features**: Live camera streaming, face recognition, attendance tracking

## 🎯 Key Features

### Admin Portal
- **Teacher Management**: Add, edit, delete teachers
- **Student Management**: Add, edit, delete students with face photos
- **Camera Management**: Add, edit, delete CCTV cameras (RTSP)
- **Grade Management**: Organize students and teachers by grades
- **Settings**: Configure SMS API, face detection schedules
- **Live View**: Real-time face detection with time-based controls
- **Reports**: Attendance reports and analytics

### Teacher Portal
- **Student Management**: Manage students for assigned grade
- **Attendance Reports**: View attendance data for their students
- **Live View**: Monitor face detection for their grade
- **Dashboard**: Overview of student attendance

### Face Detection System
- **Real-time Detection**: Live face recognition from CCTV cameras
- **Time-based Control**: Configure detection schedules per camera
- **Attendance Tracking**: Automatic attendance marking
- **SMS Notifications**: Send alerts to parents (configurable)

## 🔧 Service Management

### Start Services
```bash
docker compose up -d
```

### Stop Services
```bash
docker compose down
```

### Restart Services
```bash
docker compose restart
```

### View Logs
```bash
# All services
docker compose logs

# Specific service
docker compose logs web
docker compose logs face_detection
docker compose logs db
docker compose logs redis
```

### Check Status
```bash
docker ps
```

## 📁 File Structure

```
Smart_Attendance/
├── src/                    # PHP application source code
│   ├── admin/             # Admin portal pages
│   ├── teacher/           # Teacher portal pages
│   ├── models/            # Database models
│   ├── config/            # Configuration files
│   └── auth/              # Authentication logic
├── face_detection/        # Python face detection service
├── database/              # Database initialization scripts
├── uploads/               # File uploads (student photos, etc.)
├── docker-compose.yml     # Docker services configuration
├── Dockerfile             # Web service Dockerfile
├── Dockerfile.python      # Face detection service Dockerfile
└── requirements.txt       # Python dependencies
```

## 🛡️ Security Considerations

### Firewall Configuration
```bash
# Allow HTTP traffic
sudo ufw allow 80/tcp

# Allow HTTPS traffic (if using SSL)
sudo ufw allow 443/tcp

# Allow SSH (if needed)
sudo ufw allow 22/tcp

# Enable firewall
sudo ufw enable
```

### Database Security
- Change default MySQL root password
- Use strong passwords for database users
- Restrict database access to localhost only

### Application Security
- Change default admin password immediately
- Use strong passwords for all user accounts
- Regularly update system packages
- Monitor system logs for suspicious activity

## 🔄 Updates and Maintenance

### Update the System
```bash
# Pull latest changes
git pull origin main

# Restart services
docker compose down
docker compose up -d
```

### Backup Database
```bash
# Create backup
docker exec smart_attendance-db-1 mysqldump -u root -p smart_attendance > backup.sql

# Restore backup
docker exec -i smart_attendance-db-1 mysql -u root -p smart_attendance < backup.sql
```

### Monitor System Resources
```bash
# Check disk usage
df -h

# Check memory usage
free -h

# Check running processes
htop
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Services Not Starting
```bash
# Check Docker status
sudo systemctl status docker

# Check container logs
docker compose logs

# Restart Docker
sudo systemctl restart docker
```

#### 2. Port Conflicts
```bash
# Check what's using port 80
sudo netstat -tulpn | grep :80

# Check what's using port 5001
sudo netstat -tulpn | grep :5001
```

#### 3. Database Connection Issues
```bash
# Check database container
docker exec smart_attendance-db-1 mysql -u root -p

# Check database logs
docker logs smart_attendance-db-1
```

#### 4. Face Detection Not Working
```bash
# Check Python service logs
docker logs smart_attendance-face_detection-1

# Check if cameras are configured
# Access admin portal and check camera settings
```

### Getting Help

If you encounter issues:

1. Check the logs: `docker compose logs`
2. Verify all services are running: `docker ps`
3. Test network connectivity: `curl http://localhost`
4. Check system resources: `htop`, `df -h`

## 📞 Support

For technical support or questions:
- Check the GitHub repository: https://github.com/zawnaing-2024/Smart_Attendance
- Review the logs for error messages
- Ensure all prerequisites are met

## 🎉 Success!

Once installation is complete, you should see:
- All 4 services running (web, db, redis, face_detection)
- Web portal accessible at http://your-vm-ip
- Admin login working with admin/password
- Face detection service responding on port 5001

Your Smart Attendance Management System is now ready to use! 🚀
