#!/bin/bash

# Smart Attendance System - Local Development Setup Script
# This script sets up the Smart Attendance system for local development on macOS

echo "🚀 Setting up Smart Attendance System for Local Development..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker Desktop for Mac first."
    echo "   Download from: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p uploads/faces
mkdir -p face_models
mkdir -p logs

# Set permissions
chmod 755 uploads/faces
chmod 755 face_models
chmod 755 logs

echo "✅ Directories created"

# Create environment file
echo "⚙️ Creating environment configuration..."
cat > .env << EOF
# Database Configuration
DB_HOST=db
DB_USER=attendance_user
DB_PASS=attendance_pass
DB_NAME=smart_attendance

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379

# Face Detection Configuration
ATTENDANCE_THRESHOLD=0.6
SMS_ENABLED=false
AUTO_CONFIRM_ATTENDANCE=true
ATTENDANCE_TIMEOUT=30

# Development Settings
DEBUG=true
LOG_LEVEL=INFO
EOF

echo "✅ Environment file created"

# Build and start containers
echo "🐳 Building and starting Docker containers..."
docker-compose up --build -d

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 30

# Check if containers are running
echo "🔍 Checking container status..."
docker-compose ps

# Generate face encodings for existing students
echo "🤖 Setting up face recognition system..."
docker-compose exec face_detection python generate_face_encodings.py --all

echo ""
echo "🎉 Smart Attendance System is now running!"
echo ""
echo "📋 Access Information:"
echo "   • Admin Portal: http://localhost:8080/login.php"
echo "   • Default Admin Login: admin / admin123"
echo "   • Live View Portal: http://localhost:5000"
echo "   • Face Detection API: http://localhost:5000/api/"
echo ""
echo "📊 Database Information:"
echo "   • MySQL Host: localhost:3306"
echo "   • Database: smart_attendance"
echo "   • Username: attendance_user"
echo "   • Password: attendance_pass"
echo ""
echo "🔧 Management Commands:"
echo "   • View logs: docker-compose logs -f"
echo "   • Stop system: docker-compose down"
echo "   • Restart system: docker-compose restart"
echo "   • Update face encodings: docker-compose exec face_detection python generate_face_encodings.py --all"
echo ""
echo "📝 Next Steps:"
echo "   1. Login to admin portal and add teachers"
echo "   2. Add students with face images"
echo "   3. Configure cameras with RTSP URLs"
echo "   4. Set up SMS API in settings"
echo "   5. Test face detection with live cameras"
echo ""
echo "✨ Setup complete! Happy coding!"
