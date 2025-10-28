# Smart Attendance Management System

A comprehensive attendance management system with real-time face detection, automated SMS notifications, and multi-portal access for schools.

## 🚀 Features

- **Real-time Face Detection**: Automated student recognition using CCTV cameras
- **Multi-Portal Access**: Admin, Teacher, and Live View portals
- **SMS Notifications**: Automatic alerts to parents when students enter/leave
- **CCTV Integration**: Support for RTSP camera streams
- **Docker Deployment**: Easy setup and deployment with Docker Compose
- **Database Management**: MySQL database with automated initialization
- **Redis Caching**: Fast data access and messaging

## 🏗️ System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Admin Portal  │    │  Teacher Portal │    │  Live View      │
│   (PHP/Apache)  │    │   (PHP/Apache)  │    │   (Python/Flask)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   MySQL Database │
                    │   (Port 3306)   │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Redis Cache    │
                    │   (Port 6379)   │
                    └─────────────────┘
```

## 📋 Prerequisites

- Docker and Docker Compose installed
- Git (for cloning the repository)
- At least 4GB RAM available for Docker
- Ports 8080, 3306, 6379, and 5001 available

## 🛠️ Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/zawnaing-2024/Smart_Attendance.git
cd Smart_Attendance
```

### 2. Start the System

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps
```

### 3. Access the System

- **Main Portal**: http://localhost:8080
- **Live Face Detection**: http://localhost:5001
- **Database**: localhost:3306 (user: `attendance_user`, password: `attendance_pass`)
- **Redis**: localhost:6379

## 🔧 Configuration

### Database Configuration

The system automatically creates the following tables:
- `admins` - Admin user accounts
- `teachers` - Teacher accounts
- `students` - Student information with face encodings
- `cameras` - CCTV camera configurations
- `attendance` - Attendance records
- `sms_settings` - SMS API configuration

### Environment Variables

Key environment variables in `docker-compose.yml`:

```yaml
environment:
  - DB_HOST=db
  - DB_USER=attendance_user
  - DB_PASS=attendance_pass
  - DB_NAME=smart_attendance
  - REDIS_HOST=redis
  - REDIS_PORT=6379
```

## 📱 Portal Access

### Admin Portal
- **URL**: http://localhost:8080/admin/
- **Features**:
  - Manage teacher accounts
  - Add/edit/delete students
  - Configure CCTV cameras
  - View attendance reports
  - SMS settings management

### Teacher Portal
- **URL**: http://localhost:8080/teacher/
- **Features**:
  - View class attendance
  - Generate attendance reports
  - Student management for assigned classes

### Live View Portal
- **URL**: http://localhost:5001
- **Features**:
  - Real-time face detection feed
  - Live attendance monitoring
  - Student recognition display

## 🔄 Development & Testing

### Local Development

```bash
# Rebuild containers after code changes
docker-compose down
docker-compose up --build -d

# View logs
docker-compose logs -f

# Access container shell
docker-compose exec web bash
docker-compose exec face_detection bash
```

### Testing Face Detection

The face detection service currently runs in simulation mode for testing. To test:

1. Access http://localhost:5001
2. You'll see a live feed with simulated face detection
3. The system generates random student names and bounding boxes

## 🚀 Production Deployment

### Ubuntu Server Deployment

1. **Install Docker on Ubuntu**:
```bash
sudo apt update
sudo apt install docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker
```

2. **Clone and Deploy**:
```bash
git clone https://github.com/zawnaing-2024/Smart_Attendance.git
cd Smart_Attendance
docker-compose up -d
```

3. **Configure Firewall**:
```bash
sudo ufw allow 8080
sudo ufw allow 5001
sudo ufw enable
```

### Production Environment Variables

For production, update the following in `docker-compose.yml`:

```yaml
environment:
  - DB_HOST=your-db-host
  - DB_USER=your-db-user
  - DB_PASS=your-secure-password
  - DB_NAME=smart_attendance
  - REDIS_HOST=your-redis-host
  - REDIS_PORT=6379
```

## 📊 Monitoring & Maintenance

### Health Checks

```bash
# Check all services
docker-compose ps

# Check specific service logs
docker-compose logs web
docker-compose logs face_detection
docker-compose logs db
docker-compose logs redis

# Check resource usage
docker stats
```

### Backup Database

```bash
# Create backup
docker-compose exec db mysqldump -u attendance_user -pattendance_pass smart_attendance > backup.sql

# Restore backup
docker-compose exec -T db mysql -u attendance_user -pattendance_pass smart_attendance < backup.sql
```

### Update System

```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose down
docker-compose up --build -d
```

## 🔧 Troubleshooting

### Common Issues

1. **Port Already in Use**:
   ```bash
   # Check what's using the port
   sudo netstat -tulpn | grep :8080
   
   # Kill the process or change port in docker-compose.yml
   ```

2. **Database Connection Issues**:
   ```bash
   # Check database logs
   docker-compose logs db
   
   # Restart database
   docker-compose restart db
   ```

3. **Face Detection Service Not Starting**:
   ```bash
   # Check Python service logs
   docker-compose logs face_detection
   
   # Rebuild Python container
   docker-compose up --build face_detection
   ```

4. **Permission Issues**:
   ```bash
   # Fix file permissions
   sudo chown -R $USER:$USER .
   chmod -R 755 src/
   ```

### Log Locations

- **Web Service**: `docker-compose logs web`
- **Face Detection**: `docker-compose logs face_detection`
- **Database**: `docker-compose logs db`
- **Redis**: `docker-compose logs redis`

## 📝 API Documentation

### Face Detection API

- **GET** `/` - Live view page
- **GET** `/video_feed` - Video stream endpoint

### Database API (Internal)

The system uses MySQL with the following key tables:

```sql
-- Students table
CREATE TABLE students (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    roll_number VARCHAR(50) UNIQUE,
    grade VARCHAR(50),
    face_encoding TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Attendance table
CREATE TABLE attendance (
    id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT,
    camera_id INT,
    direction ENUM('in', 'out'),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id)
);
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions:
- Create an issue on GitHub
- Contact: [Your Contact Information]

## 🔮 Future Enhancements

- [ ] Real OpenCV face recognition implementation
- [ ] Mobile app for parents
- [ ] Advanced analytics dashboard
- [ ] Multi-school support
- [ ] Integration with school management systems
- [ ] AI-powered attendance predictions
- [ ] Biometric integration (fingerprint, iris)

---

**Note**: This system is currently in development mode with simulated face detection. For production use, implement real face recognition using OpenCV or similar libraries.