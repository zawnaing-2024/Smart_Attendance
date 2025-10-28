# Smart Attendance Management System

A comprehensive face recognition-based attendance management system with admin and teacher portals.

## 🚀 Quick Start

### One-Command Installation
```bash
curl -fsSL https://raw.githubusercontent.com/zawnaing-2024/Smart_Attendance/main/smart-attendance.sh | bash -s install
```

### Manual Installation
```bash
git clone https://github.com/zawnaing-2024/Smart_Attendance.git
cd Smart_Attendance
./smart-attendance.sh install
```

## 📋 System Requirements

- Ubuntu 20.04+ or Debian 11+
- Root or sudo access
- Internet connection
- At least 2GB RAM and 10GB disk space

## 🛠️ Management Commands

The system uses a single unified script for all operations:

```bash
# Installation
./smart-attendance.sh install

# Service Management
./smart-attendance.sh start      # Start all services
./smart-attendance.sh stop       # Stop all services
./smart-attendance.sh restart    # Restart all services
./smart-attendance.sh status     # Show service status

# Maintenance
./smart-attendance.sh logs       # Show service logs
./smart-attendance.sh fix        # Fix common issues
./smart-attendance.sh update     # Update system
./smart-attendance.sh backup     # Backup database
./smart-attendance.sh restore    # Restore database
./smart-attendance.sh clean      # Clean up Docker resources

# Help
./smart-attendance.sh help       # Show help
```

## 🌐 Access URLs

After installation:

- **Main Portal**: http://localhost
- **Admin Portal**: http://localhost/login.php?user_type=admin
- **Teacher Portal**: http://localhost/login.php?user_type=teacher
- **Python Service**: http://localhost:5001

## 🔐 Default Login

- **Username**: `admin`
- **Password**: `password`

## 🏗️ System Architecture

### Services
- **Web Service** (PHP 8.2 + Apache) - Port 80
- **Database Service** (MySQL 8.0) - Port 3306
- **Cache Service** (Redis 7) - Port 6379
- **Face Detection Service** (Python 3.9 + Flask) - Port 5001

### Key Features
- **Admin Portal**: Teacher management, student management, camera management, grade management, face detection schedules, live view, attendance reports
- **Teacher Portal**: Student management for assigned grade, attendance reports, live view monitoring, dashboard overview
- **Face Detection**: Real-time face recognition, time-based detection control, automatic attendance tracking, SMS notifications

## 📁 Project Structure

```
Smart_Attendance/
├── smart-attendance.sh          # Unified management script
├── docker-compose.yml           # Service configuration
├── Dockerfile                   # Web service Dockerfile
├── Dockerfile.python            # Face detection Dockerfile
├── src/                         # PHP application source
│   ├── admin/                   # Admin portal pages
│   ├── teacher/                 # Teacher portal pages
│   ├── models/                  # Database models
│   └── config/                  # Configuration files
├── face_detection/              # Python face detection service
├── database/                    # Database initialization
└── uploads/                     # File uploads
```

## 🔧 Troubleshooting

### Common Issues

1. **Docker Permission Issues**
   ```bash
   ./smart-attendance.sh fix
   ```

2. **Database Connection Issues**
   ```bash
   ./smart-attendance.sh fix
   ```

3. **Service Not Starting**
   ```bash
   ./smart-attendance.sh restart
   ./smart-attendance.sh logs
   ```

4. **Port Conflicts**
   ```bash
   ./smart-attendance.sh stop
   ./smart-attendance.sh clean
   ./smart-attendance.sh start
   ```

### Getting Help

- Check service status: `./smart-attendance.sh status`
- View logs: `./smart-attendance.sh logs`
- Fix issues: `./smart-attendance.sh fix`
- Clean restart: `./smart-attendance.sh clean && ./smart-attendance.sh start`

## 🔄 Updates

```bash
# Update system
./smart-attendance.sh update

# Or manual update
git pull origin main
./smart-attendance.sh restart
```

## 🛡️ Security

- Change default admin password immediately
- Configure firewall (allow ports 80, 443)
- Use strong passwords for all accounts
- Regular system updates

## 📞 Support

- GitHub: https://github.com/zawnaing-2024/Smart_Attendance
- Check logs for errors: `./smart-attendance.sh logs`
- Verify all services are running: `./smart-attendance.sh status`

## 🎉 Success!

Once installation is complete, you should see:
- All 4 services running (web, db, redis, face_detection)
- Web portal accessible at http://localhost
- Admin login working with admin/password
- Face detection service responding on port 5001

Your Smart Attendance Management System is now ready to use! 🚀