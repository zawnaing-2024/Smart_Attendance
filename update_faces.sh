#!/bin/bash

# Smart Attendance System - Face Encoding Update Script
# This script updates face encodings for all students

echo "🤖 Updating face encodings for Smart Attendance System..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if containers are running
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ Smart Attendance containers are not running. Please start the system first."
    echo "   Run: docker-compose up -d"
    exit 1
fi

echo "✅ Docker containers are running"

# Update face encodings
echo "🔄 Processing face encodings..."
docker-compose exec face_detection python generate_face_encodings.py --all

if [ $? -eq 0 ]; then
    echo "✅ Face encodings updated successfully!"
    echo ""
    echo "📝 Next steps:"
    echo "   1. Check the face detection system is working"
    echo "   2. Test with live camera feeds"
    echo "   3. Verify attendance records are being created"
else
    echo "❌ Failed to update face encodings"
    echo "   Check the logs: docker-compose logs face_detection"
    exit 1
fi
