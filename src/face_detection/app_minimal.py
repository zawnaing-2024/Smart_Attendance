import json
import pymysql
import redis
import os
import time
from datetime import datetime
from flask import Flask, render_template, Response, jsonify
import threading
import queue
from PIL import Image, ImageDraw, ImageFont
import io
import base64

app = Flask(__name__)

class SimpleCameraSystem:
    def __init__(self):
        self.db_config = {
            'host': os.getenv('DB_HOST', 'localhost'),
            'user': os.getenv('DB_USER', 'attendance_user'),
            'password': os.getenv('DB_PASS', 'attendance_pass'),
            'database': os.getenv('DB_NAME', 'smart_attendance'),
            'charset': 'utf8mb4'
        }
        
        self.redis_client = redis.Redis(
            host=os.getenv('REDIS_HOST', 'localhost'),
            port=int(os.getenv('REDIS_PORT', 6379)),
            decode_responses=True
        )
        
        self.cameras = []
        self.load_cameras()
        
    def load_cameras(self):
        try:
            connection = pymysql.connect(**self.db_config)
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT id, name, rtsp_url, username, password, location 
                    FROM cameras 
                    WHERE is_active = 1
                """)
                self.cameras = cursor.fetchall()
            connection.close()
            print(f"Loaded {len(self.cameras)} cameras")
        except Exception as e:
            print(f"Error loading cameras: {e}")
    
    def create_placeholder_image(self, camera_id, location):
        """Create a placeholder image when camera is not available"""
        # Create a simple image with text
        img = Image.new('RGB', (640, 480), color='black')
        draw = ImageDraw.Draw(img)
        
        # Try to use a default font, fallback to basic if not available
        try:
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 24)
        except:
            font = ImageFont.load_default()
        
        # Add text to image
        text = f"Camera: {location}"
        text2 = "Camera Feed Unavailable"
        text3 = "Face Detection Disabled"
        
        # Get text bounding box
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        
        # Center the text
        x = (640 - text_width) // 2
        y = (480 - text_height * 3) // 2
        
        draw.text((x, y), text, fill='white', font=font)
        draw.text((x, y + text_height + 10), text2, fill='red', font=font)
        draw.text((x, y + text_height * 2 + 20), text3, fill='yellow', font=font)
        
        # Convert to bytes
        img_bytes = io.BytesIO()
        img.save(img_bytes, format='JPEG')
        img_bytes.seek(0)
        
        return base64.b64encode(img_bytes.getvalue()).decode()
    
    def process_camera_stream(self, camera_id, rtsp_url, username, password, location):
        """Process camera stream - simplified version without OpenCV"""
        try:
            print(f"Processing camera {camera_id}: {location}")
            
            # For now, just create placeholder images
            # In a real implementation, you would connect to the RTSP stream
            while True:
                # Create placeholder image
                frame_data = self.create_placeholder_image(camera_id, location)
                
                # Store frame for web display
                self.redis_client.set(f"camera_{camera_id}_frame", frame_data)
                
                # Wait before next frame
                time.sleep(1)
                
        except Exception as e:
            print(f"Error processing camera {camera_id}: {e}")

# Initialize system
camera_system = SimpleCameraSystem()

@app.route('/')
def index():
    return jsonify({
        "status": "Smart Attendance System - Ultra Minimal Mode", 
        "cameras": len(camera_system.cameras),
        "note": "Camera feeds are placeholder images. Face detection is disabled."
    })

@app.route('/video_feed/<int:camera_id>')
def video_feed(camera_id):
    def generate():
        while True:
            frame_data = camera_system.redis_client.get(f"camera_{camera_id}_frame")
            if frame_data:
                frame_bytes = base64.b64decode(frame_data)
                yield (b'--frame\r\n'
                       b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')
            else:
                # Create a default placeholder if no frame data
                default_img = camera_system.create_placeholder_image(camera_id, f"Camera {camera_id}")
                frame_bytes = base64.b64decode(default_img)
                yield (b'--frame\r\n'
                       b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')
            time.sleep(1)
    
    return Response(generate(), mimetype='multipart/x-mixed-replace; boundary=frame')

@app.route('/api/refresh_cameras')
def refresh_cameras():
    camera_system.load_cameras()
    return jsonify({"message": "Cameras refreshed", "count": len(camera_system.cameras)})

@app.route('/api/status')
def status():
    return jsonify({
        "status": "running",
        "mode": "ultra_minimal",
        "cameras": len(camera_system.cameras),
        "face_detection": False,
        "timestamp": datetime.now().isoformat()
    })

if __name__ == '__main__':
    # Start camera processing threads
    for camera in camera_system.cameras:
        camera_id, name, rtsp_url, username, password, location = camera
        thread = threading.Thread(target=camera_system.process_camera_stream, 
                                 args=(camera_id, rtsp_url, username, password, location))
        thread.daemon = True
        thread.start()
    
    print("Starting Smart Attendance System - Ultra Minimal Mode")
    print("Camera feeds will show placeholder images")
    print("Face detection is disabled")
    
    app.run(host='0.0.0.0', port=5000, debug=False)
