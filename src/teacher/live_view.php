<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../models/Camera.php';

Utils::requireTeacher();

$database = new Database();
$db = $database->getConnection();
$camera = new Camera($db);

$cameras = $camera->getActiveCameras();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Live View - Teacher Portal</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        .sidebar {
            min-height: 100vh;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .sidebar .nav-link {
            color: rgba(255, 255, 255, 0.8);
            padding: 12px 20px;
            border-radius: 8px;
            margin: 2px 0;
            transition: all 0.3s;
        }
        .sidebar .nav-link:hover,
        .sidebar .nav-link.active {
            color: white;
            background: rgba(255, 255, 255, 0.1);
            transform: translateX(5px);
        }
        .main-content {
            background-color: #1a1a1a;
            color: white;
            min-height: 100vh;
        }
        .camera-container {
            background: #2d2d2d;
            border-radius: 15px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
        }
        .camera-title {
            color: #00ff88;
            font-weight: bold;
            margin-bottom: 15px;
            text-align: center;
        }
        .video-stream {
            width: 100%;
            height: 300px;
            border-radius: 10px;
            border: 2px solid #444;
            background: #000;
        }
        .attendance-panel {
            background: #2d2d2d;
            border-radius: 15px;
            padding: 20px;
            margin-top: 20px;
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
        }
        .attendance-item {
            background: #3d3d3d;
            border-radius: 10px;
            padding: 15px;
            margin-bottom: 10px;
            border-left: 4px solid #00ff88;
        }
        .attendance-item.exit {
            border-left-color: #ff6b6b;
        }
        .student-name {
            font-weight: bold;
            color: #00ff88;
        }
        .roll-number {
            color: #888;
            font-size: 0.9em;
        }
        .timestamp {
            color: #aaa;
            font-size: 0.8em;
        }
        .confidence {
            color: #ffd700;
            font-weight: bold;
        }
        .status-indicator {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            display: inline-block;
            margin-right: 8px;
        }
        .status-online {
            background-color: #00ff88;
            box-shadow: 0 0 10px #00ff88;
        }
        .status-offline {
            background-color: #ff6b6b;
        }
        .stats-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 15px;
            padding: 20px;
            margin-bottom: 20px;
            text-align: center;
        }
        .stats-number {
            font-size: 2.5rem;
            font-weight: bold;
            margin-bottom: 5px;
        }
        .stats-label {
            font-size: 1rem;
            opacity: 0.9;
        }
    </style>
</head>
<body>

    <div class="container-fluid">
        <div class="row">
            <!-- Sidebar -->
            <nav class="col-md-3 col-lg-2 d-md-block sidebar">
                <div class="position-sticky pt-3">
                    <div class="text-center mb-4">
                        <h4><i class="fas fa-graduation-cap me-2"></i>Smart Attendance</h4>
                        <small>Teacher Portal</small>
                    </div>
                    
                    <ul class="nav flex-column">
                        <li class="nav-item">
                            <a class="nav-link" href="dashboard.php">
                                <i class="fas fa-tachometer-alt me-2"></i>Dashboard
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="attendance_reports.php">
                                <i class="fas fa-chart-bar me-2"></i>Reports
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="students.php">
                                <i class="fas fa-user-graduate me-2"></i>Students
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link active" href="live_view.php">
                                <i class="fas fa-eye me-2"></i>Live View
                            </a>
                        </li>
                        <li class="nav-item mt-4">
                            <a class="nav-link" href="../auth/logout.php">
                                <i class="fas fa-sign-out-alt me-2"></i>Logout
                            </a>
                        </li>
                    </ul>
                </div>
            </nav>

            <!-- Main content -->
            <main class="col-md-9 ms-sm-auto col-lg-10 px-md-4 main-content">
                <div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
                    <h1 class="h2"><i class="fas fa-eye me-2"></i>Live View Portal</h1>
                    <div>
                        <button class="btn btn-primary me-2" onclick="refreshData()">
                            <i class="fas fa-sync me-1"></i>Refresh
                        </button>
                        <button class="btn btn-success" onclick="toggleFullscreen()">
                            <i class="fas fa-expand me-1"></i>Fullscreen
                        </button>
                    </div>
                </div>

                <!-- Statistics -->
                <div class="row mb-4">
                    <div class="col-md-3">
                        <div class="stats-card">
                            <div class="stats-number" id="totalCameras"><?php echo count($cameras); ?></div>
                            <div class="stats-label">Active Cameras</div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="stats-card">
                            <div class="stats-number" id="todayEntries">0</div>
                            <div class="stats-label">Today's Entries</div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="stats-card">
                            <div class="stats-number" id="todayExits">0</div>
                            <div class="stats-label">Today's Exits</div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="stats-card">
                            <div class="stats-number" id="totalDetections">0</div>
                            <div class="stats-label">Total Detections</div>
                        </div>
                    </div>
                </div>

                <!-- Camera Feeds -->
                <div class="row">
                    <?php foreach ($cameras as $camera): ?>
                    <div class="col-lg-6 col-xl-4 mb-4">
                        <div class="camera-container">
                            <div class="camera-title">
                                <span class="status-indicator status-online"></span>
                                <?php echo htmlspecialchars($camera['name']); ?> - <?php echo htmlspecialchars($camera['location']); ?>
                            </div>
                            <img src="http://localhost:5001/video_feed/<?php echo $camera['id']; ?>" 
                                 class="video-stream" alt="Camera Feed" 
                                 onerror="this.src='data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjQwIiBoZWlnaHQ9IjQ4MCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSIjMDAwIi8+PHRleHQgeD0iNTAlIiB5PSI1MCUiIGZvbnQtZmFtaWx5PSJBcmlhbCIgZm9udC1zaXplPSIyNCIgZmlsbD0iI2ZmZiIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZHk9Ii4zZW0iPk5vIFNpZ25hbDwvdGV4dD48L3N2Zz4='">
                        </div>
                    </div>
                    <?php endforeach; ?>
                </div>

                <!-- Recent Attendance -->
                <div class="row">
                    <div class="col-12">
                        <div class="attendance-panel">
                            <h4><i class="fas fa-history me-2"></i>Recent Attendance</h4>
                            <div id="attendanceList">
                                <!-- Attendance items will be loaded here -->
                            </div>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Load recent attendance data
        function loadRecentAttendance() {
            fetch('http://localhost:5001/api/recent_attendance')
                .then(response => response.json())
                .then(data => {
                    const attendanceList = document.getElementById('attendanceList');
                    attendanceList.innerHTML = '';
                    
                    if (data.error) {
                        attendanceList.innerHTML = '<div class="text-center text-muted">Error loading attendance data</div>';
                        return;
                    }
                    
                    data.forEach(item => {
                        const attendanceItem = document.createElement('div');
                        attendanceItem.className = `attendance-item ${item.attendance_type}`;
                        
                        const timestamp = new Date(item.detected_at).toLocaleString();
                        const confidence = (item.confidence_score * 100).toFixed(1);
                        
                        attendanceItem.innerHTML = `
                            <div class="d-flex justify-content-between align-items-center">
                                <div>
                                    <div class="student-name">${item.student_name}</div>
                                    <div class="roll-number">Roll: ${item.roll_number}</div>
                                    <div class="timestamp">${timestamp}</div>
                                </div>
                                <div class="text-end">
                                    <div class="badge ${item.attendance_type === 'entry' ? 'bg-success' : 'bg-warning'}">
                                        ${item.attendance_type.toUpperCase()}
                                    </div>
                                    <div class="confidence">${confidence}%</div>
                                    <div class="text-muted small">${item.camera_name}</div>
                                </div>
                            </div>
                        `;
                        
                        attendanceList.appendChild(attendanceItem);
                    });
                    
                    // Update statistics
                    updateStatistics(data);
                })
                .catch(error => {
                    console.error('Error loading attendance:', error);
                    document.getElementById('attendanceList').innerHTML = 
                        '<div class="text-center text-muted">Error loading attendance data</div>';
                });
        }
        
        function updateStatistics(data) {
            const today = new Date().toDateString();
            let todayEntries = 0;
            let todayExits = 0;
            
            data.forEach(item => {
                const itemDate = new Date(item.detected_at).toDateString();
                if (itemDate === today) {
                    if (item.attendance_type === 'entry') {
                        todayEntries++;
                    } else if (item.attendance_type === 'exit') {
                        todayExits++;
                    }
                }
            });
            
            document.getElementById('todayEntries').textContent = todayEntries;
            document.getElementById('todayExits').textContent = todayExits;
            document.getElementById('totalDetections').textContent = data.length;
        }
        
        function refreshData() {
            loadRecentAttendance();
            // Refresh camera feeds
            const images = document.querySelectorAll('.video-stream');
            images.forEach(img => {
                const src = img.src;
                img.src = '';
                img.src = src;
            });
        }
        
        function toggleFullscreen() {
            if (!document.fullscreenElement) {
                document.documentElement.requestFullscreen();
            } else {
                document.exitFullscreen();
            }
        }
        
        // Load initial data
        loadRecentAttendance();
        
        // Refresh attendance data every 5 seconds
        setInterval(loadRecentAttendance, 5000);
        
        // Auto-refresh camera feeds every 30 seconds
        setInterval(() => {
            const images = document.querySelectorAll('.video-stream');
            images.forEach(img => {
                const src = img.src;
                img.src = '';
                img.src = src;
            });
        }, 30000);
    </script>
</body>
</html>