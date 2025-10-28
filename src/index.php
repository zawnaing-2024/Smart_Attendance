<?php
// Simple test page for Smart Attendance System
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Smart Attendance System</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
            margin-bottom: 30px;
        }
        .portal-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 30px;
        }
        .portal-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            border: 2px solid #e9ecef;
            text-align: center;
            transition: transform 0.2s;
        }
        .portal-card:hover {
            transform: translateY(-5px);
            border-color: #007bff;
        }
        .portal-card h3 {
            color: #007bff;
            margin-bottom: 15px;
        }
        .portal-card p {
            color: #666;
            margin-bottom: 20px;
        }
        .btn {
            display: inline-block;
            padding: 10px 20px;
            background: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            transition: background 0.2s;
        }
        .btn:hover {
            background: #0056b3;
        }
        .status {
            background: #d4edda;
            color: #155724;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Smart Attendance Management System</h1>
        
        <div class="status">
            <strong>System Status:</strong> All services are running successfully! 🟢
        </div>
        
        <div class="portal-grid">
            <div class="portal-card">
                <h3>Admin Portal</h3>
                <p>Manage teachers, students, cameras, and system settings</p>
                <a href="login.php?redirect=admin" class="btn">Access Admin Portal</a>
            </div>
            
            <div class="portal-card">
                <h3>Teacher Portal</h3>
                <p>View attendance reports and manage class data</p>
                <a href="login.php?redirect=teacher" class="btn">Access Teacher Portal</a>
            </div>
            
            <div class="portal-card">
                <h3>Live View Portal</h3>
                <p>Real-time face detection and attendance monitoring</p>
                <a href="http://localhost:5001" class="btn" target="_blank">View Live Feed</a>
            </div>
        </div>
        
        <div style="margin-top: 30px; text-align: center; color: #666;">
            <p><strong>System Features:</strong></p>
            <ul style="list-style: none; padding: 0;">
                <li>✅ Real-time face detection</li>
                <li>✅ Automated attendance tracking</li>
                <li>✅ SMS notifications to parents</li>
                <li>✅ Multi-portal access (Admin, Teacher, Live View)</li>
                <li>✅ CCTV camera integration</li>
                <li>✅ Docker containerized deployment</li>
            </ul>
        </div>
    </div>
</body>
</html>
