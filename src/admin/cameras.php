<?php
require_once '../config/database.php';
require_once '../models/Camera.php';

// Ensure authentication before any output
Utils::requireAdmin();

$database = new Database();
$db = $database->getConnection();
$camera = new Camera($db);

// Handle form submissions
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['action'])) {
        switch ($_POST['action']) {
            case 'create':
                $camera->name = $_POST['name'];
                $camera->rtsp_url = $_POST['rtsp_url'];
                $camera->username = $_POST['username'];
                $camera->password = $_POST['password'];
                $camera->location = $_POST['location'];
                
                if ($camera->create()) {
                    $success_message = "Camera created successfully!";
                } else {
                    $error_message = "Failed to create camera.";
                }
                break;
                
            case 'update':
                $camera->id = $_POST['camera_id'];
                $camera->name = $_POST['name'];
                $camera->rtsp_url = $_POST['rtsp_url'];
                $camera->username = $_POST['username'];
                $camera->password = $_POST['password'];
                $camera->location = $_POST['location'];
                $camera->is_active = isset($_POST['is_active']) ? 1 : 0;
                
                if ($camera->update()) {
                    $success_message = "Camera updated successfully!";
                } else {
                    $error_message = "Failed to update camera.";
                }
                break;
                
            case 'delete':
                $camera->id = $_POST['camera_id'];
                if ($camera->delete()) {
                    $success_message = "Camera deleted successfully!";
                } else {
                    $error_message = "Failed to delete camera.";
                }
                break;
        }
    }
}

$cameras = $camera->read();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Camera Management - Smart Attendance</title>
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
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border: none;
            border-radius: 10px;
        }
        .table-responsive {
            border-radius: 15px;
            overflow: hidden;
        }
        .modal-content {
            border-radius: 15px;
            border: none;
        }
        .form-control, .form-select {
            border-radius: 10px;
            border: 2px solid #e9ecef;
        }
        .form-control:focus, .form-select:focus {
            border-color: #667eea;
            box-shadow: 0 0 0 0.2rem rgba(102, 126, 234, 0.25);
        }
        .camera-preview {
            width: 200px;
            height: 150px;
            border-radius: 10px;
            border: 2px solid #e9ecef;
            background: #f8f9fa;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #6c757d;
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
                            <a class="nav-link active" href="cameras.php">
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
                    <h1 class="h2">Camera Management</h1>
                    <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addCameraModal">
                        <i class="fas fa-plus me-2"></i>Add Camera
                    </button>
                </div>

                <?php if (isset($success_message)): ?>
                    <div class="alert alert-success alert-dismissible fade show" role="alert">
                        <?php echo $success_message; ?>
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                <?php endif; ?>

                <?php if (isset($error_message)): ?>
                    <div class="alert alert-danger alert-dismissible fade show" role="alert">
                        <?php echo $error_message; ?>
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                <?php endif; ?>

                <!-- Cameras Table -->
                <div class="card">
                    <div class="card-header">
                        <h5 class="card-title mb-0">Cameras List</h5>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-hover">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Name</th>
                                        <th>Location</th>
                                        <th>RTSP URL</th>
                                        <th>Username</th>
                                        <th>Status</th>
                                        <th>Preview</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php while ($row = $cameras->fetch(PDO::FETCH_ASSOC)): ?>
                                    <tr>
                                        <td><?php echo $row['id']; ?></td>
                                        <td><?php echo htmlspecialchars($row['name']); ?></td>
                                        <td><?php echo htmlspecialchars($row['location']); ?></td>
                                        <td>
                                            <small class="text-muted">
                                                <?php echo htmlspecialchars(substr($row['rtsp_url'], 0, 50)) . '...'; ?>
                                            </small>
                                        </td>
                                        <td><?php echo htmlspecialchars($row['username']); ?></td>
                                        <td>
                                            <span class="badge <?php echo $row['is_active'] ? 'bg-success' : 'bg-danger'; ?>">
                                                <?php echo $row['is_active'] ? 'Active' : 'Inactive'; ?>
                                            </span>
                                        </td>
                                        <td>
                                            <div class="camera-preview">
                                                <img src="http://localhost:5000/video_feed/<?php echo $row['id']; ?>" 
                                                     style="width: 100%; height: 100%; object-fit: cover; border-radius: 8px;" 
                                                     onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                                                <div style="display: none; flex-direction: column; align-items: center;">
                                                    <i class="fas fa-video fa-2x mb-2"></i>
                                                    <small>No Signal</small>
                                                </div>
                                            </div>
                                        </td>
                                        <td>
                                            <button class="btn btn-sm btn-outline-primary" onclick="editCamera(<?php echo htmlspecialchars(json_encode($row)); ?>)">
                                                <i class="fas fa-edit"></i>
                                            </button>
                                            <button class="btn btn-sm btn-outline-danger" onclick="deleteCamera(<?php echo $row['id']; ?>)">
                                                <i class="fas fa-trash"></i>
                                            </button>
                                        </td>
                                    </tr>
                                    <?php endwhile; ?>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <!-- Add Camera Modal -->
    <div class="modal fade" id="addCameraModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Add New Camera</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form method="POST">
                    <div class="modal-body">
                        <input type="hidden" name="action" value="create">
                        
                        <div class="row">
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="name" class="form-label">Camera Name</label>
                                    <input type="text" class="form-control" id="name" name="name" required>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="location" class="form-label">Location</label>
                                    <input type="text" class="form-control" id="location" name="location" required>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="rtsp_url" class="form-label">RTSP URL</label>
                                    <input type="text" class="form-control" id="rtsp_url" name="rtsp_url" 
                                           placeholder="rtsp://192.168.1.100:554/stream" required>
                                    <small class="form-text text-muted">Enter the RTSP stream URL</small>
                                </div>
                            </div>
                            
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="username" class="form-label">Username</label>
                                    <input type="text" class="form-control" id="username" name="username">
                                    <small class="form-text text-muted">Leave empty if no authentication required</small>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="password" class="form-label">Password</label>
                                    <input type="password" class="form-control" id="password" name="password">
                                </div>
                                
                                <div class="mb-3">
                                    <div class="alert alert-info">
                                        <h6><i class="fas fa-info-circle me-2"></i>RTSP URL Examples:</h6>
                                        <ul class="mb-0">
                                            <li><code>rtsp://192.168.1.100:554/stream</code></li>
                                            <li><code>rtsp://admin:password@192.168.1.100:554/stream</code></li>
                                            <li><code>rtsp://camera.local:554/live</code></li>
                                        </ul>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary">Add Camera</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Edit Camera Modal -->
    <div class="modal fade" id="editCameraModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Edit Camera</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form method="POST">
                    <div class="modal-body">
                        <input type="hidden" name="action" value="update">
                        <input type="hidden" name="camera_id" id="edit_camera_id">
                        
                        <div class="row">
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="edit_name" class="form-label">Camera Name</label>
                                    <input type="text" class="form-control" id="edit_name" name="name" required>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="edit_location" class="form-label">Location</label>
                                    <input type="text" class="form-control" id="edit_location" name="location" required>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="edit_rtsp_url" class="form-label">RTSP URL</label>
                                    <input type="text" class="form-control" id="edit_rtsp_url" name="rtsp_url" required>
                                </div>
                            </div>
                            
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="edit_username" class="form-label">Username</label>
                                    <input type="text" class="form-control" id="edit_username" name="username">
                                </div>
                                
                                <div class="mb-3">
                                    <label for="edit_password" class="form-label">Password</label>
                                    <input type="password" class="form-control" id="edit_password" name="password">
                                    <small class="form-text text-muted">Leave empty to keep current password</small>
                                </div>
                                
                                <div class="mb-3">
                                    <div class="form-check">
                                        <input class="form-check-input" type="checkbox" id="edit_is_active" name="is_active">
                                        <label class="form-check-label" for="edit_is_active">
                                            Active
                                        </label>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary">Update Camera</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div class="modal fade" id="deleteCameraModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Confirm Delete</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form method="POST">
                    <div class="modal-body">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="camera_id" id="delete_camera_id">
                        <p>Are you sure you want to delete this camera? This action cannot be undone.</p>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-danger">Delete Camera</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function editCamera(camera) {
            document.getElementById('edit_camera_id').value = camera.id;
            document.getElementById('edit_name').value = camera.name;
            document.getElementById('edit_location').value = camera.location;
            document.getElementById('edit_rtsp_url').value = camera.rtsp_url;
            document.getElementById('edit_username').value = camera.username;
            document.getElementById('edit_is_active').checked = camera.is_active == 1;
            
            new bootstrap.Modal(document.getElementById('editCameraModal')).show();
        }
        
        function deleteCamera(cameraId) {
            document.getElementById('delete_camera_id').value = cameraId;
            new bootstrap.Modal(document.getElementById('deleteCameraModal')).show();
        }
    </script>
</body>
</html>
