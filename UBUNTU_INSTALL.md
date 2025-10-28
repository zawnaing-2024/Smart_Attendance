# Quick Start Guide - Ubuntu Installation

## 🚀 One-Command Installation

For Ubuntu 20.04+ users, you can install the Smart Attendance System with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/zawnaing-2024/Smart_Attendance/main/install-ubuntu.sh | bash
```

## 📋 Manual Installation Steps

If you prefer manual installation or the script doesn't work:

### 1. Install Docker
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Log out and log back in, then verify
docker --version
```

### 2. Clone Repository
```bash
git clone https://github.com/zawnaing-2024/Smart_Attendance.git
cd Smart_Attendance
```

### 3. Start Services
```bash
# Make scripts executable
chmod +x *.sh

# Start all services
docker compose up -d --build
```

### 4. Access Application
- **Main Portal**: http://localhost:8080
- **Admin Login**: admin / password

## 🔧 Post-Installation Setup

1. **Add Cameras**: Admin → Cameras → Add Camera
2. **Add Students**: Admin → Students → Add Student (upload face photos)
3. **Configure Detection Schedule**: Admin → Settings → Face Detection Schedule
4. **Test Live View**: Admin → Live View

## 🆘 Troubleshooting

### Docker Issues
```bash
# Check Docker status
sudo systemctl status docker

# Restart Docker
sudo systemctl restart docker

# Check containers
docker compose ps
```

### Port Conflicts
```bash
# Check if ports are in use
sudo netstat -tulpn | grep :8080
sudo netstat -tulpn | grep :5001

# Kill processes if needed
sudo kill -9 <PID>
```

### Service Logs
```bash
# View all logs
docker compose logs -f

# View specific service logs
docker compose logs -f face_detection
docker compose logs -f web
```

## 📞 Support

- **GitHub Issues**: https://github.com/zawnaing-2024/Smart_Attendance/issues
- **Documentation**: See README.md for detailed instructions

---

**System Requirements**: Ubuntu 20.04+, 4GB RAM, 20GB disk space
