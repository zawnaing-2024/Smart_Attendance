<?php
require_once '../config/database.php';

// Ensure authentication before any output
Utils::requireAdmin();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Live View - Smart Attendance</title>
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
            background-color: #f8f9fa;
            min-height: 100vh;
        }
        .card {
            border: none;
            border-radius: 15px;
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.08);
        }
        .live-stream {
            border-radius: 15px;
            overflow: hidden;
        }
        .stream-container {
            position: relative;
            background: #000;
            border-radius: 15px;
            overflow: hidden;
        }
        .stream-placeholder {
            width: 100%;
            height: 400px;
            background: linear-gradient(45deg, #1a1a1a, #2d2d2d);
            display: flex;
            align-items: center;
            justify-content: center;
            color: #666;
            font-size: 1.2rem;
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
                        <small>Admin Portal</small>
                    </div>
                    
                    <ul class="nav flex-column">
                        <li class="nav-item">
                            <a class="nav-link" href="dashboard.php">
                                <i class="fas fa-tachometer-alt me-2"></i>Dashboard
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="grades.php">
                                <i class="fas fa-layer-group me-2"></i>Grades
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="teachers.php">
                                <i class="fas fa-chalkboard-teacher me-2"></i>Teachers
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="students.php">
                                <i class="fas fa-user-graduate me-2"></i>Students
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="cameras.php">
                                <i class="fas fa-video me-2"></i>Cameras
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="attendance.php">
                                <i class="fas fa-calendar-check me-2"></i>Attendance
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link active" href="live_view.php">
                                <i class="fas fa-eye me-2"></i>Live View
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="settings.php">
                                <i class="fas fa-cog me-2"></i>Settings
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
                    <h1 class="h2">Live Face Detection</h1>
                    <div class="btn-toolbar mb-2 mb-md-0">
                        <div class="btn-group me-2">
                            <a href="http://localhost:5001" target="_blank" class="btn btn-sm btn-primary">
                                <i class="fas fa-external-link-alt me-1"></i>Open Full Screen
                            </a>
                            <button id="refreshCamerasBtn" class="btn btn-sm btn-outline-secondary" type="button">
                                <i class="fas fa-sync-alt me-1"></i>Refresh Cameras
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Live Stream -->
                <div class="card">
                    <div class="card-header">
                        <h5 class="card-title mb-0">
                            <i class="fas fa-video me-2"></i>Real-time Face Detection Stream
                        </h5>
                    </div>
                    <div class="card-body">
                        <div class="stream-container">
                            <iframe src="http://localhost:5001" 
                                    width="100%" 
                                    height="500" 
                                    frameborder="0"
                                    style="border-radius: 15px;">
                            </iframe>
                        </div>
                        
                        <div class="mt-3">
                            <div class="row">
                                <div class="col-md-4">
                                    <div class="card text-center">
                                        <div class="card-body">
                                            <i class="fas fa-eye fa-2x text-primary mb-2"></i>
                                            <h6>Live Detection</h6>
                                            <small class="text-muted">Real-time face recognition</small>
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-4">
                                    <div class="card text-center">
                                        <div class="card-body">
                                            <i class="fas fa-user-check fa-2x text-success mb-2"></i>
                                            <h6>Student Recognition</h6>
                                            <small class="text-muted">Automatic student identification</small>
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-4">
                                    <div class="card text-center">
                                        <div class="card-body">
                                            <i class="fas fa-bell fa-2x text-warning mb-2"></i>
                                            <h6>SMS Alerts</h6>
                                            <small class="text-muted">Instant parent notifications</small>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Instructions -->
                <div class="card mt-4">
                    <div class="card-header">
                        <h5 class="card-title mb-0">
                            <i class="fas fa-info-circle me-2"></i>How It Works
                        </h5>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-md-6">
                                <h6>Face Detection Process:</h6>
                                <ol>
                                    <li>Camera captures live video feed</li>
                                    <li>AI analyzes faces in real-time</li>
                                    <li>Compares against student database</li>
                                    <li>Records attendance automatically</li>
                                    <li>Sends SMS to parents</li>
                                </ol>
                            </div>
                            <div class="col-md-6">
                                <h6>System Features:</h6>
                                <ul>
                                    <li>Real-time face recognition</li>
                                    <li>Entry/Exit detection</li>
                                    <li>Confidence scoring</li>
                                    <li>Automatic SMS notifications</li>
                                    <li>Attendance logging</li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        document.getElementById('refreshCamerasBtn')?.addEventListener('click', async () => {
            try {
                const res = await fetch('http://localhost:5001/api/refresh_cameras');
                if (res.ok) {
                    location.reload();
                } else {
                    alert('Failed to refresh cameras');
                }
            } catch (e) {
                alert('Live service is not reachable on port 5001');
            }
        });
    </script>
</body>
</html>
