# Smart Attendance Management System

A comprehensive face recognition-based attendance management system with three portals: Admin, Teacher, and Live View. The system uses Docker for easy deployment and includes time-frame controls for face detection.

## 🚀 Features

### Admin Portal
- **Teacher Management**: Add, edit, delete teacher accounts with grade assignments
- **Student Management**: Add, edit, delete students with face image uploads
- **Camera Management**: Configure CCTV cameras with RTSP streams
- **Grade Management**: Organize teachers and students by grades/classes
- **Live View**: Real-time face detection with time-frame controls
- **Settings**: Configure detection schedules, SMS settings, and system parameters
- **Reports**: View attendance records and analytics

### Teacher Portal
- **Dashboard**: View assigned students and attendance statistics
- **Student Management**: Manage students for assigned grade only
- **Live View**: Monitor face detection for assigned students
- **Reports**: Generate attendance reports for assigned students

### Live View Portal
- **Real-time Monitoring**: Live camera feeds with face detection
- **Time-frame Control**: Manual scheduling of detection periods
- **Status Indicators**: Visual feedback on detection status
- **Multi-camera Support**: Monitor multiple cameras simultaneously

## 🚀 Quick Installation (Ubuntu)

### One-Command Installation

```bash
# Download and run the unified deployment script
curl -fsSL https://raw.githubusercontent.com/zawnaing-2024/Smart_Attendance/main/smart-attendance.sh | bash -s install
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/zawnaing-2024/Smart_Attendance.git
cd Smart_Attendance

# Run installation
chmod +x smart-attendance.sh
./smart-attendance.sh install
```

### Access the Application

- **Main Portal**: http://localhost:8080
- **Admin Portal**: http://localhost:8080/login.php?user_type=admin
- **Teacher Portal**: http://localhost:8080/login.php?user_type=teacher
- **Live View**: http://localhost:8080/admin/live_view.php
- **Python Service**: http://localhost:5001

### Default Login Credentials

- **Admin**: username: `admin`, password: `password`
- **Teacher**: Create teacher accounts through admin portal

## 🔧 Configuration

### Camera Setup

1. **Add Cameras**: Go to Admin → Cameras
2. **Configure RTSP**: Enter camera RTSP URL, username, password
3. **Test Connection**: Verify camera accessibility

### Detection Schedule

1. **Go to Settings**: Admin → Settings
2. **Face Detection Schedule**: Configure time frames
3. **Set Active Times**: Choose days and hours for detection
4. **Live View Always On**: Camera feeds remain visible

### Student Management

1. **Upload Face Images**: Add student photos during registration
2. **Generate Encodings**: Run face encoding generation
3. **Test Recognition**: Verify face detection accuracy

## 📱 SMS Integration

### Supported Providers

- **Twilio**: Account SID, Auth Token, Phone Number
- **Nexmo (Vonage)**: API Key, API Secret, From Number
- **TextLocal**: API Key, Sender Name

### Configuration

1. **Go to Settings**: Admin → Settings
2. **SMS Configuration**: Enter provider details
3. **Enable SMS**: Toggle SMS notifications
4. **Test Messages**: Send test notifications

## 🛠️ Maintenance & Management

### Unified Script Commands

The `smart-attendance.sh` script handles all operations:

```bash
# Update system
./smart-attendance.sh update

# Start services
./smart-attendance.sh start

# Stop services
./smart-attendance.sh stop

# Restart services
./smart-attendance.sh restart

# View service status
./smart-attendance.sh status

# View logs
./smart-attendance.sh logs

# Backup database
./smart-attendance.sh backup

# Restore database
./smart-attendance.sh restore

# Fix Docker permissions
./smart-attendance.sh fix-docker

# Clean up containers
./smart-attendance.sh clean

# Show help
./smart-attendance.sh help
```

### Quick Commands

```bash
# Update and restart
./smart-attendance.sh update

# Check status
./smart-attendance.sh status

# View logs
./smart-attendance.sh logs
```

## 🔍 Troubleshooting

### Common Issues

1. **Camera Not Showing**
   - Check RTSP URL format
   - Verify camera credentials
   - Test network connectivity

2. **Face Detection Not Working**
   - Check detection schedule settings
   - Verify face encodings are generated
   - Check Python service logs

3. **Database Connection Issues**
   - Verify database container is running
   - Check environment variables
   - Review database logs

4. **Port Conflicts**
   - Check if ports 8080, 5001, 3306 are available
   - Modify docker-compose.yml if needed

### Debug Commands

```bash
# Check service status
./smart-attendance.sh status

# View logs
./smart-attendance.sh logs

# Fix Docker permissions
./smart-attendance.sh fix-docker

# Manual Docker commands (if needed)
docker compose ps
docker compose logs [service_name]
docker exec -it smartattendance-web-1 bash
docker exec -it smartattendance-db-1 mysql -u attendance_user -pattendance_pass
```

## 📊 System Requirements

### Minimum Requirements
- **CPU**: 2 cores
- **RAM**: 4GB
- **Storage**: 20GB free space
- **Network**: Stable internet connection

### Recommended Requirements
- **CPU**: 4+ cores
- **RAM**: 8GB+
- **Storage**: 50GB+ SSD
- **GPU**: CUDA-compatible (for faster face processing)

## 🔐 Security Considerations

1. **Change Default Passwords**: Update admin and database passwords
2. **Use HTTPS**: Configure SSL certificates for production
3. **Firewall**: Restrict access to necessary ports only
4. **Regular Updates**: Keep system and dependencies updated
5. **Backup Strategy**: Implement regular database backups

## 📞 Support

For issues and questions:
- **GitHub Issues**: Create an issue on the repository
- **Documentation**: Check this README and code comments
- **Community**: Join discussions in the repository

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 🎯 Roadmap

- [ ] Mobile app integration
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Cloud deployment options
- [ ] API documentation
- [ ] Automated testing suite

---

**Made with ❤️ for educational institutions**