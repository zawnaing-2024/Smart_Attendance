<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../models/Attendance.php';
require_once __DIR__ . '/../models/Student.php';
require_once __DIR__ . '/../models/Camera.php';

Utils::requireTeacher();

$database = new Database();
$db = $database->getConnection();
$attendance = new Attendance($db);
$student = new Student($db);
$camera = new Camera($db);

// Get date range for reports
$start_date = isset($_GET['start_date']) ? $_GET['start_date'] : date('Y-m-01');
$end_date = isset($_GET['end_date']) ? $_GET['end_date'] : date('Y-m-d');

// Get attendance reports
$attendance_reports = $attendance->getAttendanceReports($start_date, $end_date);
$attendance_stats = $attendance->getAttendanceStats($start_date, $end_date);
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Attendance Reports - Teacher Portal</title>
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
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border: none;
            border-radius: 10px;
        }
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }
        .table-responsive {
            border-radius: 15px;
            overflow: hidden;
        }
        .form-control, .form-select {
            border-radius: 10px;
            border: 2px solid #e9ecef;
        }
        .form-control:focus, .form-select:focus {
            border-color: #667eea;
            box-shadow: 0 0 0 0.2rem rgba(102, 126, 234, 0.25);
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
                            <a class="nav-link active" href="attendance_reports.php">
                                <i class="fas fa-chart-bar me-2"></i>Reports
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="students.php">
                                <i class="fas fa-user-graduate me-2"></i>Students
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="live_view.php">
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
                    <h1 class="h2">Attendance Reports</h1>
                    <div class="btn-toolbar mb-2 mb-md-0">
                        <div class="btn-group me-2">
                            <button type="button" class="btn btn-sm btn-outline-secondary">
                                <i class="fas fa-download me-1"></i>Export Report
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Date Range Filter -->
                <div class="row mb-4">
                    <div class="col-12">
                        <div class="card">
                            <div class="card-header">
                                <h5 class="card-title mb-0">Filter Reports</h5>
                            </div>
                            <div class="card-body">
                                <form method="GET" class="row g-3">
                                    <div class="col-md-4">
                                        <label for="start_date" class="form-label">Start Date</label>
                                        <input type="date" class="form-control" id="start_date" name="start_date" 
                                               value="<?php echo $start_date; ?>">
                                    </div>
                                    <div class="col-md-4">
                                        <label for="end_date" class="form-label">End Date</label>
                                        <input type="date" class="form-control" id="end_date" name="end_date" 
                                               value="<?php echo $end_date; ?>">
                                    </div>
                                    <div class="col-md-4 d-flex align-items-end">
                                        <button type="submit" class="btn btn-primary">
                                            <i class="fas fa-filter me-2"></i>Apply Filter
                                        </button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Charts Row -->
                <div class="row mb-4">
                    <div class="col-lg-8">
                        <div class="card">
                            <div class="card-header">
                                <h5 class="card-title mb-0">Attendance Trend</h5>
                            </div>
                            <div class="card-body">
                                <canvas id="attendanceChart" width="400" height="200"></canvas>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-4">
                        <div class="card">
                            <div class="card-header">
                                <h5 class="card-title mb-0">Summary Statistics</h5>
                            </div>
                            <div class="card-body">
                                <div class="mb-3">
                                    <div class="d-flex justify-content-between">
                                        <span>Total Entries</span>
                                        <span class="badge bg-success">
                                            <?php 
                                            $total_entries = 0;
                                            while ($row = $attendance_stats->fetch(PDO::FETCH_ASSOC)) {
                                                $total_entries += $row['entries'];
                                            }
                                            echo $total_entries;
                                            ?>
                                        </span>
                                    </div>
                                </div>
                                <div class="mb-3">
                                    <div class="d-flex justify-content-between">
                                        <span>Total Exits</span>
                                        <span class="badge bg-warning">
                                            <?php 
                                            $total_exits = 0;
                                            $attendance_stats->execute(); // Reset cursor
                                            while ($row = $attendance_stats->fetch(PDO::FETCH_ASSOC)) {
                                                $total_exits += $row['exits'];
                                            }
                                            echo $total_exits;
                                            ?>
                                        </span>
                                    </div>
                                </div>
                                <div class="mb-3">
                                    <div class="d-flex justify-content-between">
                                        <span>Unique Students</span>
                                        <span class="badge bg-primary">
                                            <?php 
                                            $unique_students = 0;
                                            $attendance_stats->execute(); // Reset cursor
                                            while ($row = $attendance_stats->fetch(PDO::FETCH_ASSOC)) {
                                                $unique_students = max($unique_students, $row['unique_students']);
                                            }
                                            echo $unique_students;
                                            ?>
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Detailed Reports -->
                <div class="row">
                    <div class="col-12">
                        <div class="card">
                            <div class="card-header">
                                <h5 class="card-title mb-0">Detailed Attendance Records</h5>
                            </div>
                            <div class="card-body">
                                <div class="table-responsive">
                                    <table class="table table-hover">
                                        <thead>
                                            <tr>
                                                <th>Date</th>
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
                                            <?php while ($row = $attendance_reports->fetch(PDO::FETCH_ASSOC)): ?>
                                            <tr>
                                                <td><?php echo date('Y-m-d', strtotime($row['detected_at'])); ?></td>
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
        
        // Get attendance data from PHP
        const attendanceData = <?php 
            $attendance_stats->execute(); // Reset cursor
            $chart_data = [];
            while ($row = $attendance_stats->fetch(PDO::FETCH_ASSOC)) {
                $chart_data[] = [
                    'date' => $row['date'],
                    'entries' => $row['entries'],
                    'exits' => $row['exits']
                ];
            }
            echo json_encode($chart_data);
        ?>;
        
        const labels = attendanceData.map(item => item.date);
        const entriesData = attendanceData.map(item => item.entries);
        const exitsData = attendanceData.map(item => item.exits);
        
        const attendanceChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: labels,
                datasets: [{
                    label: 'Entries',
                    data: entriesData,
                    borderColor: 'rgb(75, 192, 192)',
                    backgroundColor: 'rgba(75, 192, 192, 0.2)',
                    tension: 0.1
                }, {
                    label: 'Exits',
                    data: exitsData,
                    borderColor: 'rgb(255, 99, 132)',
                    backgroundColor: 'rgba(255, 99, 132, 0.2)',
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
