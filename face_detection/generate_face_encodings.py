#!/usr/bin/env python3
"""
Face Encoding Generator for Smart Attendance System
This script processes uploaded face images and generates face encodings for the database.
"""

import os
import sys
import json
import face_recognition
import pymysql
from PIL import Image
import argparse

def get_db_connection():
    """Get database connection"""
    db_config = {
        'host': os.getenv('DB_HOST', 'localhost'),
        'user': os.getenv('DB_USER', 'attendance_user'),
        'password': os.getenv('DB_PASS', 'attendance_pass'),
        'database': os.getenv('DB_NAME', 'smart_attendance'),
        'charset': 'utf8mb4'
    }
    
    return pymysql.connect(**db_config)

def generate_face_encoding(image_path):
    """Generate face encoding from image"""
    try:
        # Load image
        image = face_recognition.load_image_file(image_path)
        
        # Find face locations
        face_locations = face_recognition.face_locations(image)
        
        if len(face_locations) == 0:
            return None, "No face found in image"
        
        if len(face_locations) > 1:
            return None, "Multiple faces found in image"
        
        # Generate face encoding
        face_encodings = face_recognition.face_encodings(image, face_locations)
        
        if len(face_encodings) == 0:
            return None, "Could not generate face encoding"
        
        return face_encodings[0].tolist(), "Success"
        
    except Exception as e:
        return None, f"Error processing image: {str(e)}"

def update_student_face_encoding(student_id, face_encoding):
    """Update student's face encoding in database"""
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            cursor.execute("""
                UPDATE students 
                SET face_encoding = %s 
                WHERE id = %s
            """, (json.dumps(face_encoding), student_id))
            
            connection.commit()
        
        connection.close()
        return True, "Face encoding updated successfully"
        
    except Exception as e:
        return False, f"Database error: {str(e)}"

def process_student_image(student_id, image_path):
    """Process a single student's image"""
    print(f"Processing student ID {student_id}...")
    
    # Generate face encoding
    face_encoding, message = generate_face_encoding(image_path)
    
    if face_encoding is None:
        print(f"  Error: {message}")
        return False
    
    # Update database
    success, db_message = update_student_face_encoding(student_id, face_encoding)
    
    if success:
        print(f"  Success: {db_message}")
        return True
    else:
        print(f"  Database Error: {db_message}")
        return False

def process_all_students():
    """Process all students with face images but no encodings"""
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT id, roll_number, name, face_image_path 
                FROM students 
                WHERE face_image_path IS NOT NULL 
                AND face_encoding IS NULL 
                AND is_active = 1
            """)
            
            students = cursor.fetchall()
        
        connection.close()
        
        if not students:
            print("No students found with face images but no encodings.")
            return
        
        print(f"Found {len(students)} students to process...")
        
        success_count = 0
        
        for student in students:
            student_id, roll_number, name, face_image_path = student
            
            # Check if image file exists
            full_image_path = f"../src/{face_image_path}"
            
            if not os.path.exists(full_image_path):
                print(f"  Error: Image file not found for {name} ({roll_number})")
                continue
            
            if process_student_image(student_id, full_image_path):
                success_count += 1
        
        print(f"\nProcessing complete: {success_count}/{len(students)} students processed successfully.")
        
    except Exception as e:
        print(f"Error processing students: {str(e)}")

def process_single_student(student_id):
    """Process a single student by ID"""
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT id, roll_number, name, face_image_path 
                FROM students 
                WHERE id = %s AND is_active = 1
            """, (student_id,))
            
            student = cursor.fetchone()
        
        connection.close()
        
        if not student:
            print(f"Student with ID {student_id} not found.")
            return
        
        student_id, roll_number, name, face_image_path = student
        
        if not face_image_path:
            print(f"Student {name} ({roll_number}) has no face image.")
            return
        
        # Check if image file exists
        full_image_path = f"../src/{face_image_path}"
        
        if not os.path.exists(full_image_path):
            print(f"Image file not found: {full_image_path}")
            return
        
        process_student_image(student_id, full_image_path)
        
    except Exception as e:
        print(f"Error processing student: {str(e)}")

def main():
    parser = argparse.ArgumentParser(description='Generate face encodings for Smart Attendance System')
    parser.add_argument('--student-id', type=int, help='Process specific student by ID')
    parser.add_argument('--all', action='store_true', help='Process all students with face images')
    
    args = parser.parse_args()
    
    if args.student_id:
        process_single_student(args.student_id)
    elif args.all:
        process_all_students()
    else:
        print("Please specify --student-id <id> or --all")
        print("Examples:")
        print("  python generate_face_encodings.py --student-id 1")
        print("  python generate_face_encodings.py --all")

if __name__ == "__main__":
    main()
