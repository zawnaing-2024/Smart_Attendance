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

## 🐳 Docker Installation (Ubuntu)

### Prerequisites

1. **Ubuntu 20.04 LTS or later**
2. **Docker and Docker Compose**
3. **Git**

### Step 1: Install Docker and Docker Compose

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Enable Docker to start on boot
sudo systemctl enable docker
sudo systemctl start docker

# Verify installation
docker --version
docker compose version
```

### Step 2: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/zawnaing-2024/Smart_Attendance.git
cd Smart_Attendance

# Make scripts executable
chmod +x setup_local.sh
chmod +x update.sh
chmod +x update_faces.sh
chmod +x deploy-ubuntu.sh
```

### Step 3: Configure Environment

```bash
# Copy environment file
cp env.example .env

# Edit environment variables (optional)
nano .env
```

### Step 4: Build and Start Services

```bash
# Build and start all services
docker compose up -d --build

# Check service status
docker compose ps

# View logs
docker compose logs -f
```

### Step 5: Access the Application

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

## 🛠️ Maintenance

### Update System

```bash
# Pull latest changes
git pull origin main

# Rebuild and restart services
docker compose down
docker compose up -d --build
```

### Backup Database

```bash
# Create backup
docker exec smartattendance-db-1 mysqldump -u attendance_user -pattendance_pass smart_attendance > backup.sql

# Restore backup
docker exec -i smartattendance-db-1 mysql -u attendance_user -pattendance_pass smart_attendance < backup.sql
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f face_detection
docker compose logs -f web
docker compose logs -f db
```

### Restart Services

```bash
# Restart all services
docker compose restart

# Restart specific service
docker compose restart face_detection
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
# Check container status
docker compose ps

# View service logs
docker compose logs [service_name]

# Access container shell
docker exec -it smartattendance-web-1 bash
docker exec -it smartattendance-db-1 mysql -u attendance_user -pattendance_pass

# Check network connectivity
docker network ls
docker network inspect smartattendance_attendance_network
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