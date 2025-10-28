<?php
require_once '../config/database.php';
require_once '../models/Teacher.php';
require_once '../models/Student.php';
require_once '../models/Camera.php';
require_once '../models/Attendance.php';

// Ensure authentication before any output
Utils::requireAdmin();

$database = new Database();
$db = $database->getConnection();

// Get statistics
$teacher = new Teacher($db);
$student = new Student($db);
$camera = new Camera($db);
$attendance = new Attendance($db);

// Count records
$teacher_count = $db->query("SELECT COUNT(*) as count FROM teachers WHERE is_active = 1")->fetch()['count'];
$student_count = $db->query("SELECT COUNT(*) as count FROM students WHERE is_active = 1")->fetch()['count'];
$camera_count = $db->query("SELECT COUNT(*) as count FROM cameras WHERE is_active = 1")->fetch()['count'];
$today_attendance = $attendance->getTodayAttendance();

// Get recent attendance
$recent_attendance = $attendance->getRecentAttendance(5);
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard - Smart Attendance</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/chart.js@3.9.1/dist/chart.min.css" rel="stylesheet">
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
            transition: transform 0.3s;
        }
        .card:hover {
            transform: translateY(-5px);
        }
        .stat-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .stat-card .card-body {
            padding: 2rem;
        }
        .stat-icon {
            font-size: 3rem;
            opacity: 0.8;
        }
        .navbar-brand {
            font-weight: 700;
            font-size: 1.5rem;
        }
        .table-responsive {
            border-radius: 15px;
            overflow: hidden;
        }
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border: none;
            border-radius: 10px;
            padding: 10px 20px;
        }
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }
    </style>
</head>
<body>
    <?php // Page content starts after auth and setup ?>

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
                            <a class="nav-link active" href="dashboard.php">
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
                            <a class="nav-link" href="live_view.php">
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
                    <h1 class="h2">Dashboard</h1>
                    <div class="btn-toolbar mb-2 mb-md-0">
                        <div class="btn-group me-2">
                            <button type="button" class="btn btn-sm btn-outline-secondary">
                                <i class="fas fa-download me-1"></i>Export
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Statistics Cards -->
                <div class="row mb-4">
                    <div class="col-xl-3 col-md-6 mb-4">
                        <div class="card stat-card">
                            <div class="card-body">
                                <div class="row no-gutters align-items-center">
                                    <div class="col mr-2">
                                        <div class="text-xs font-weight-bold text-uppercase mb-1">Teachers</div>
                                        <div class="h5 mb-0 font-weight-bold"><?php echo $teacher_count; ?></div>
                                    </div>
                                    <div class="col-auto">
                                        <i class="fas fa-chalkboard-teacher stat-icon"></i>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-xl-3 col-md-6 mb-4">
                        <div class="card stat-card">
                            <div class="card-body">
                                <div class="row no-gutters align-items-center">
                                    <div class="col mr-2">
                                        <div class="text-xs font-weight-bold text-uppercase mb-1">Students</div>
                                        <div class="h5 mb-0 font-weight-bold"><?php echo $student_count; ?></div>
                                    </div>
                                    <div class="col-auto">
                                        <i class="fas fa-user-graduate stat-icon"></i>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-xl-3 col-md-6 mb-4">
                        <div class="card stat-card">
                            <div class="card-body">
                                <div class="row no-gutters align-items-center">
                                    <div class="col mr-2">
                                        <div class="text-xs font-weight-bold text-uppercase mb-1">Cameras</div>
                                        <div class="h5 mb-0 font-weight-bold"><?php echo $camera_count; ?></div>
                                    </div>
                                    <div class="col-auto">
                                        <i class="fas fa-video stat-icon"></i>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-xl-3 col-md-6 mb-4">
                        <div class="card stat-card">
                            <div class="card-body">
                                <div class="row no-gutters align-items-center">
                                    <div class="col mr-2">
                                        <div class="text-xs font-weight-bold text-uppercase mb-1">Today's Attendance</div>
                                        <div class="h5 mb-0 font-weight-bold"><?php echo $today_attendance['total_entries'] ?? 0; ?></div>
                                    </div>
                                    <div class="col-auto">
                                        <i class="fas fa-calendar-check stat-icon"></i>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Charts Row -->
                <div class="row mb-4">
                    <div class="col-lg-8">
                        <div class="card">
                            <div class="card-header">
                                <h5 class="card-title mb-0">Attendance Overview</h5>
                            </div>
                            <div class="card-body">
                                <canvas id="attendanceChart" width="400" height="200"></canvas>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-4">
                        <div class="card">
                            <div class="card-header">
                                <h5 class="card-title mb-0">Today's Summary</h5>
                            </div>
                            <div class="card-body">
                                <div class="mb-3">
                                    <div class="d-flex justify-content-between">
                                        <span>Entries</span>
                                        <span class="badge bg-success"><?php echo $today_attendance['entries'] ?? 0; ?></span>
                                    </div>
                                </div>
                                <div class="mb-3">
                                    <div class="d-flex justify-content-between">
                                        <span>Exits</span>
                                        <span class="badge bg-warning"><?php echo $today_attendance['exits'] ?? 0; ?></span>
                                    </div>
                                </div>
                                <div class="mb-3">
                                    <div class="d-flex justify-content-between">
                                        <span>Total Records</span>
                                        <span class="badge bg-primary"><?php echo $today_attendance['total_entries'] ?? 0; ?></span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Recent Attendance -->
                <div class="row">
                    <div class="col-12">
                        <div class="card">
                            <div class="card-header">
                                <h5 class="card-title mb-0">Recent Attendance</h5>
                            </div>
                            <div class="card-body">
                                <div class="table-responsive">
                                    <table class="table table-hover">
                                        <thead>
                                            <tr>
                                                <th>Student</th>
                                                <th>Roll Number</th>
                                                <th>Type</th>
                                                <th>Camera</th>
                                                <th>Time</th>
                                                <th>Confidence</th>
                                                <th>Status</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <?php while ($row = $recent_attendance->fetch(PDO::FETCH_ASSOC)): ?>
                                            <tr>
                                                <td><?php echo htmlspecialchars($row['student_name']); ?></td>
                                                <td><?php echo htmlspecialchars($row['roll_number']); ?></td>
                                                <td>
                                                    <span class="badge <?php echo $row['attendance_type'] == 'entry' ? 'bg-success' : 'bg-warning'; ?>">
                                                        <?php echo ucfirst($row['attendance_type']); ?>
                                                    </span>
                                                </td>
                                                <td><?php echo htmlspecialchars($row['camera_name']); ?></td>
                                                <td><?php echo date('H:i:s', strtotime($row['detected_at'])); ?></td>
                                                <td><?php echo number_format($row['confidence_score'] * 100, 1); ?>%</td>
                                                <td>
                                                    <span class="badge <?php echo $row['status'] == 'confirmed' ? 'bg-success' : ($row['status'] == 'rejected' ? 'bg-danger' : 'bg-warning'); ?>">
                                                        <?php echo ucfirst($row['status']); ?>
                                                    </span>
                                                </td>
                                            </tr>
                                            <?php endwhile; ?>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.9.1/dist/chart.min.js"></script>
    <script>
        // Attendance Chart
        const ctx = document.getElementById('attendanceChart').getContext('2d');
        const attendanceChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                datasets: [{
                    label: 'Entries',
                    data: [12, 19, 3, 5, 2, 3, 8],
                    borderColor: 'rgb(75, 192, 192)',
                    tension: 0.1
                }, {
                    label: 'Exits',
                    data: [8, 15, 2, 4, 1, 2, 6],
                    borderColor: 'rgb(255, 99, 132)',
                    tension: 0.1
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    </script>
</body>
</html>
