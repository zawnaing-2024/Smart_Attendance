import cv2
import face_recognition
import numpy as np
import json
import pymysql
import redis
import os
import time
import requests
from datetime import datetime
import base64
from flask import Flask, render_template, Response, jsonify
import threading
import queue

app = Flask(__name__)

class FaceDetectionSystem:
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
        
        self.known_face_encodings = []
        self.known_face_names = []
        self.known_face_roll_numbers = []
        self.cameras = []
        self.attendance_threshold = 0.6
        
        # Load face encodings and camera configurations
        self.load_face_encodings()
        self.load_cameras()
        
        # Queue for detected faces
        self.detection_queue = queue.Queue()
        
    def load_face_encodings(self):
        """Load face encodings from database"""
        try:
            connection = pymysql.connect(**self.db_config)
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT id, roll_number, name, face_encoding 
                    FROM students 
                    WHERE face_encoding IS NOT NULL AND is_active = 1
                """)
                
                students = cursor.fetchall()
                
                for student in students:
                    student_id, roll_number, name, face_encoding_str = student
                    
                    if face_encoding_str:
                        try:
                            face_encoding = json.loads(face_encoding_str)
                            self.known_face_encodings.append(np.array(face_encoding))
                            self.known_face_names.append(name)
                            self.known_face_roll_numbers.append(roll_number)
                        except (json.JSONDecodeError, ValueError) as e:
                            print(f"Error loading face encoding for {name}: {e}")
                            
            connection.close()
            print(f"Loaded {len(self.known_face_encodings)} face encodings")
            
        except Exception as e:
            print(f"Error loading face encodings: {e}")
    
    def load_cameras(self):
        """Load camera configurations from database"""
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
    
    def get_rtsp_url(self, camera_id, rtsp_url, username=None, password=None):
        """Construct RTSP URL with credentials if provided"""
        if username and password:
            # Insert credentials into RTSP URL
            if 'rtsp://' in rtsp_url:
                rtsp_url = rtsp_url.replace('rtsp://', f'rtsp://{username}:{password}@')
            else:
                rtsp_url = f'rtsp://{username}:{password}@{rtsp_url}'
        return rtsp_url
    
    def detect_faces_in_frame(self, frame):
        """Detect faces in a frame and return face locations and encodings"""
        # Resize frame for faster processing
        small_frame = cv2.resize(frame, (0, 0), fx=0.25, fy=0.25)
        rgb_small_frame = cv2.cvtColor(small_frame, cv2.COLOR_BGR2RGB)
        
        # Find face locations and encodings
        face_locations = face_recognition.face_locations(rgb_small_frame)
        face_encodings = face_recognition.face_encodings(rgb_small_frame, face_locations)
        
        return face_locations, face_encodings
    
    def recognize_faces(self, face_encodings):
        """Recognize faces and return names and confidence scores"""
        face_names = []
        face_confidences = []
        
        for face_encoding in face_encodings:
            if len(self.known_face_encodings) == 0:
                face_names.append("Unknown")
                face_confidences.append(0.0)
                continue
                
            # Compare face encoding with known faces
            matches = face_recognition.compare_faces(
                self.known_face_encodings, 
                face_encoding, 
                tolerance=self.attendance_threshold
            )
            
            face_distances = face_recognition.face_distance(
                self.known_face_encodings, 
                face_encoding
            )
            
            best_match_index = np.argmin(face_distances)
            
            if matches[best_match_index]:
                confidence = 1 - face_distances[best_match_index]
                face_names.append(self.known_face_names[best_match_index])
                face_confidences.append(confidence)
            else:
                face_names.append("Unknown")
                face_confidences.append(0.0)
        
        return face_names, face_confidences
    
    def draw_face_boxes(self, frame, face_locations, face_names, face_confidences):
        """Draw bounding boxes around detected faces"""
        # Scale back up face locations since the frame was scaled down
        for (top, right, bottom, left), name, confidence in zip(face_locations, face_names, face_confidences):
            top *= 4
            right *= 4
            bottom *= 4
            left *= 4
            
            # Draw rectangle around face
            color = (0, 255, 0) if name != "Unknown" else (0, 0, 255)
            cv2.rectangle(frame, (left, top), (right, bottom), color, 2)
            
            # Draw label
            label = f"{name} ({confidence:.2f})" if name != "Unknown" else "Unknown"
            cv2.rectangle(frame, (left, bottom - 35), (right, bottom), color, cv2.FILLED)
            cv2.putText(frame, label, (left + 6, bottom - 6), 
                       cv2.FONT_HERSHEY_DUPLEX, 0.6, (255, 255, 255), 1)
        
        return frame
    
    def save_attendance_record(self, student_id, camera_id, attendance_type, confidence_score, image_path=None):
        """Save attendance record to database"""
        try:
            connection = pymysql.connect(**self.db_config)
            with connection.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO attendance (student_id, camera_id, attendance_type, confidence_score, image_path)
                    VALUES (%s, %s, %s, %s, %s)
                """, (student_id, camera_id, attendance_type, confidence_score, image_path))
                
                connection.commit()
                attendance_id = cursor.lastrowid
                
                # Get student info for SMS notification
                cursor.execute("""
                    SELECT s.name, s.roll_number, s.parent_phone, s.parent_name
                    FROM students s WHERE s.id = %s
                """, (student_id,))
                
                student_info = cursor.fetchone()
                
            connection.close()
            
            # Send SMS notification
            if student_info:
                self.send_sms_notification(student_info, attendance_type)
            
            # Publish to Redis for real-time updates
            self.redis_client.publish('attendance_updates', json.dumps({
                'attendance_id': attendance_id,
                'student_name': student_info[0] if student_info else 'Unknown',
                'roll_number': student_info[1] if student_info else 'Unknown',
                'attendance_type': attendance_type,
                'confidence_score': confidence_score,
                'timestamp': datetime.now().isoformat()
            }))
            
            return attendance_id
            
        except Exception as e:
            print(f"Error saving attendance record: {e}")
            return None
    
    def send_sms_notification(self, student_info, attendance_type):
        """Send SMS notification to parent"""
        try:
            name, roll_number, parent_phone, parent_name = student_info
            
            if not parent_phone:
                return
            
            # Get SMS configuration
            connection = pymysql.connect(**self.db_config)
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT provider, api_key, api_secret, sender_id 
                    FROM sms_config 
                    WHERE is_active = 1 
                    LIMIT 1
                """)
                
                sms_config = cursor.fetchone()
            connection.close()
            
            if not sms_config:
                print("No SMS configuration found")
                return
            
            provider, api_key, api_secret, sender_id = sms_config
            
            # Prepare message
            action = "entered" if attendance_type == "entry" else "left"
            message = f"Dear {parent_name}, your child {name} (Roll: {roll_number}) has {action} the school at {datetime.now().strftime('%H:%M')}."
            
            # Send SMS based on provider
            if provider.lower() == 'twilio':
                self.send_twilio_sms(parent_phone, message, api_key, api_secret, sender_id)
            elif provider.lower() == 'nexmo':
                self.send_nexmo_sms(parent_phone, message, api_key, api_secret, sender_id)
            else:
                print(f"Unsupported SMS provider: {provider}")
                
        except Exception as e:
            print(f"Error sending SMS notification: {e}")
    
    def send_twilio_sms(self, phone, message, api_key, api_secret, sender_id):
        """Send SMS using Twilio"""
        try:
            url = f"https://api.twilio.com/2010-04-01/Accounts/{api_key}/Messages.json"
            
            data = {
                'From': sender_id,
                'To': phone,
                'Body': message
            }
            
            response = requests.post(url, data=data, auth=(api_key, api_secret))
            
            if response.status_code == 201:
                print(f"SMS sent successfully to {phone}")
            else:
                print(f"Failed to send SMS: {response.text}")
                
        except Exception as e:
            print(f"Error sending Twilio SMS: {e}")
    
    def send_nexmo_sms(self, phone, message, api_key, api_secret, sender_id):
        """Send SMS using Nexmo (Vonage)"""
        try:
            url = "https://rest.nexmo.com/sms/json"
            
            data = {
                'api_key': api_key,
                'api_secret': api_secret,
                'to': phone,
                'from': sender_id,
                'text': message
            }
            
            response = requests.post(url, data=data)
            result = response.json()
            
            if result.get('messages', [{}])[0].get('status') == '0':
                print(f"SMS sent successfully to {phone}")
            else:
                print(f"Failed to send SMS: {result}")
                
        except Exception as e:
            print(f"Error sending Nexmo SMS: {e}")
    
    def process_camera_stream(self, camera_id, rtsp_url, username, password, location):
        """Process camera stream for face detection"""
        try:
            # Construct RTSP URL with credentials
            full_rtsp_url = self.get_rtsp_url(camera_id, rtsp_url, username, password)
            
            # Open camera stream
            cap = cv2.VideoCapture(full_rtsp_url)
            
            if not cap.isOpened():
                print(f"Error: Could not open camera {camera_id}")
                return
            
            print(f"Processing camera {camera_id}: {location}")
            
            frame_count = 0
            last_attendance_time = {}
            
            while True:
                ret, frame = cap.read()
                if not ret:
                    print(f"Error reading frame from camera {camera_id}")
                    break
                
                frame_count += 1
                
                # Process every 5th frame to reduce CPU load
                if frame_count % 5 == 0:
                    # Detect faces
                    face_locations, face_encodings = self.detect_faces_in_frame(frame)
                    
                    if face_encodings:
                        # Recognize faces
                        face_names, face_confidences = self.recognize_faces(face_encodings)
                        
                        # Process each detected face
                        for i, (name, confidence) in enumerate(zip(face_names, face_confidences)):
                            if name != "Unknown" and confidence > self.attendance_threshold:
                                # Get student ID
                                student_id = None
                                for j, known_name in enumerate(self.known_face_names):
                                    if known_name == name:
                                        # Find student ID by name
                                        try:
                                            connection = pymysql.connect(**self.db_config)
                                            with connection.cursor() as cursor:
                                                cursor.execute("""
                                                    SELECT id FROM students 
                                                    WHERE name = %s AND is_active = 1 
                                                    LIMIT 1
                                                """, (name,))
                                                result = cursor.fetchone()
                                                if result:
                                                    student_id = result[0]
                                            connection.close()
                                        except Exception as e:
                                            print(f"Error getting student ID: {e}")
                                        break
                                
                                if student_id:
                                    # Check if we should record attendance
                                    current_time = time.time()
                                    last_time = last_attendance_time.get(student_id, 0)
                                    
                                    # Only record if more than 30 seconds have passed
                                    if current_time - last_time > 30:
                                        # Determine attendance type based on time of day
                                        current_hour = datetime.now().hour
                                        attendance_type = "entry" if 6 <= current_hour <= 12 else "exit"
                                        
                                        # Save attendance record
                                        attendance_id = self.save_attendance_record(
                                            student_id, camera_id, attendance_type, confidence
                                        )
                                        
                                        if attendance_id:
                                            last_attendance_time[student_id] = current_time
                                            print(f"Recorded {attendance_type} for {name} (ID: {student_id})")
                    
                    # Draw face boxes
                    frame = self.draw_face_boxes(frame, face_locations, face_names, face_confidences)
                
                # Add camera info to frame
                cv2.putText(frame, f"Camera: {location}", (10, 30), 
                           cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)
                
                # Store frame for web display
                self.redis_client.set(f"camera_{camera_id}_frame", 
                                    base64.b64encode(cv2.imencode('.jpg', frame)[1]).decode())
                
                # Break on 'q' key press (for testing)
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    break
            
            cap.release()
            cv2.destroyAllWindows()
            
        except Exception as e:
            print(f"Error processing camera {camera_id}: {e}")
    
    def start_all_cameras(self):
        """Start processing all cameras in separate threads"""
        threads = []
        
        for camera in self.cameras:
            camera_id, name, rtsp_url, username, password, location = camera
            thread = threading.Thread(
                target=self.process_camera_stream,
                args=(camera_id, rtsp_url, username, password, location)
            )
            thread.daemon = True
            thread.start()
            threads.append(thread)
        
        return threads

# Initialize face detection system
face_system = FaceDetectionSystem()

@app.route('/')
def index():
    """Main page showing all camera feeds"""
    return render_template('live_view.html', cameras=face_system.cameras)

@app.route('/video_feed/<int:camera_id>')
def video_feed(camera_id):
    """Video feed for specific camera"""
    def generate():
        while True:
            try:
                # Get frame from Redis
                frame_data = face_system.redis_client.get(f"camera_{camera_id}_frame")
                if frame_data:
                    frame_bytes = base64.b64decode(frame_data)
                    yield (b'--frame\r\n'
                           b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')
                else:
                    # Send placeholder frame
                    placeholder = np.zeros((480, 640, 3), dtype=np.uint8)
                    cv2.putText(placeholder, "No Signal", (200, 240), 
                               cv2.FONT_HERSHEY_SIMPLEX, 2, (255, 255, 255), 3)
                    _, buffer = cv2.imencode('.jpg', placeholder)
                    yield (b'--frame\r\n'
                           b'Content-Type: image/jpeg\r\n\r\n' + buffer.tobytes() + b'\r\n')
                
                time.sleep(0.1)  # 10 FPS
            except Exception as e:
                print(f"Error in video feed: {e}")
                break
    
    return Response(generate(), mimetype='multipart/x-mixed-replace; boundary=frame')

@app.route('/api/recent_attendance')
def recent_attendance():
    """API endpoint for recent attendance data"""
    try:
        connection = pymysql.connect(**face_system.db_config)
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT a.id, a.student_id, a.attendance_type, a.detected_at, 
                       a.confidence_score, s.name, s.roll_number, c.name as camera_name
                FROM attendance a
                JOIN students s ON a.student_id = s.id
                JOIN cameras c ON a.camera_id = c.id
                ORDER BY a.detected_at DESC
                LIMIT 10
            """)
            
            attendance_data = cursor.fetchall()
        
        connection.close()
        
        return jsonify([{
            'id': row[0],
            'student_id': row[1],
            'attendance_type': row[2],
            'detected_at': row[3].isoformat(),
            'confidence_score': float(row[4]),
            'student_name': row[5],
            'roll_number': row[6],
            'camera_name': row[7]
        } for row in attendance_data])
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/refresh_faces')
def refresh_faces():
    """API endpoint to refresh face encodings"""
    face_system.load_face_encodings()
    return jsonify({'message': 'Face encodings refreshed successfully'})

@app.route('/api/refresh_cameras')
def refresh_cameras():
    """API endpoint to refresh camera configurations"""
    face_system.load_cameras()
    return jsonify({'message': 'Camera configurations refreshed successfully'})

if __name__ == '__main__':
    # Start camera processing threads
    camera_threads = face_system.start_all_cameras()
    
    # Start Flask app
    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)
