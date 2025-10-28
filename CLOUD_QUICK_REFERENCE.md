# Smart Attendance Management System - Cloud Setup Quick Reference

## 🚀 One-Command Installation

```bash
curl -fsSL https://raw.githubusercontent.com/zawnaing-2024/Smart_Attendance/main/install.sh | bash
```

## 🌐 Access URLs

- **Main Portal**: http://your-vm-ip
- **Admin Portal**: http://your-vm-ip/login.php?user_type=admin
- **Teacher Portal**: http://your-vm-ip/login.php?user_type=teacher
- **Python Service**: http://your-vm-ip:5001

## 🔐 Default Login

- **Username**: `admin`
- **Password**: `password`

## 🔧 Service Management

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# Restart services
docker compose restart

# View logs
docker compose logs

# Check status
docker ps
```

## 📊 Services

| Service | Port | Technology | Purpose |
|---------|------|------------|---------|
| Web | 80 | PHP 8.2 + Apache | Admin/Teacher portals |
| Database | 3306 | MySQL 8.0 | Data storage |
| Cache | 6379 | Redis 7 | Caching |
| Face Detection | 5001 | Python 3.9 + Flask | Face recognition |

## 🎯 Key Features

### Admin Portal
- Teacher management
- Student management with face photos
- Camera management (RTSP)
- Grade management
- Face detection schedules
- Live view with time controls
- Attendance reports

### Teacher Portal
- Student management for assigned grade
- Attendance reports
- Live view monitoring
- Dashboard overview

### Face Detection
- Real-time face recognition
- Time-based detection control
- Automatic attendance tracking
- SMS notifications (configurable)

## 🛠️ Troubleshooting

```bash
# Check all services
docker ps

# Check logs
docker compose logs

# Restart if needed
docker compose restart

# Check ports
netstat -tulpn | grep -E ":(80|3306|6379|5001)"
```

## 📁 Important Files

- `docker-compose.yml` - Service configuration
- `src/` - PHP application source
- `face_detection/` - Python face detection service
- `database/init.sql` - Database initialization
- `uploads/` - File uploads (student photos)

## 🔄 Updates

```bash
# Update system
git pull origin main
docker compose down
docker compose up -d
```

## 🛡️ Security

- Change default admin password
- Configure firewall (allow ports 80, 443)
- Use strong passwords
- Regular system updates

## 📞 Support

- GitHub: https://github.com/zawnaing-2024/Smart_Attendance
- Check logs for errors
- Verify all services are running

---

**Your Smart Attendance Management System is now ready!** 🎉
