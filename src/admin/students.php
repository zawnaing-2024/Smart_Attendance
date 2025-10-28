<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../models/Student.php';
require_once __DIR__ . '/../models/Grade.php';

// Ensure authentication before any output
Utils::requireAdmin();

$database = new Database();
$db = $database->getConnection();
$student = new Student($db);
$gradeModel = new Grade($db);
$active_grades = $gradeModel->getActiveGrades();

// Handle form submissions
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['action'])) {
        switch ($_POST['action']) {
            case 'create':
                $student->roll_number = $_POST['roll_number'];
                $student->name = $_POST['name'];
                $student->grade = $_POST['grade'];
                $student->class = $_POST['class'];
                $student->parent_name = $_POST['parent_name'];
                $student->parent_phone = $_POST['parent_phone'];
                $student->parent_email = $_POST['parent_email'];
                
                // Handle face image upload
                if (isset($_FILES['face_image']) && $_FILES['face_image']['error'] == 0) {
                    $upload_dir = '../uploads/faces/';
                    if (!is_dir($upload_dir)) {
                        mkdir($upload_dir, 0777, true);
                    }
                    
                    $file_extension = pathinfo($_FILES['face_image']['name'], PATHINFO_EXTENSION);
                    $filename = $student->roll_number . '_' . time() . '.' . $file_extension;
                    $file_path = $upload_dir . $filename;
                    
                    if (move_uploaded_file($_FILES['face_image']['tmp_name'], $file_path)) {
                        $student->face_image_path = 'uploads/faces/' . $filename;
                    }
                }
                
                if ($student->create()) {
                    $success_message = "Student created successfully!";
                } else {
                    $error_message = "Failed to create student.";
                }
                break;
                
            case 'update':
                $student->id = $_POST['student_id'];
                $student->roll_number = $_POST['roll_number'];
                $student->name = $_POST['name'];
                $student->grade = $_POST['grade'];
                $student->class = $_POST['class'];
                $student->parent_name = $_POST['parent_name'];
                $student->parent_phone = $_POST['parent_phone'];
                $student->parent_email = $_POST['parent_email'];
                $student->is_active = isset($_POST['is_active']) ? 1 : 0;
                
                // Handle face image upload
                if (isset($_FILES['face_image']) && $_FILES['face_image']['error'] == 0) {
                    $upload_dir = '../uploads/faces/';
                    if (!is_dir($upload_dir)) {
                        mkdir($upload_dir, 0777, true);
                    }
                    
                    $file_extension = pathinfo($_FILES['face_image']['name'], PATHINFO_EXTENSION);
                    $filename = $student->roll_number . '_' . time() . '.' . $file_extension;
                    $file_path = $upload_dir . $filename;
                    
                    if (move_uploaded_file($_FILES['face_image']['tmp_name'], $file_path)) {
                        $student->face_image_path = 'uploads/faces/' . $filename;
                    }
                }
                
                if ($student->update()) {
                    $success_message = "Student updated successfully!";
                } else {
                    $error_message = "Failed to update student.";
                }
                break;
                
            case 'delete':
                $student->id = $_POST['student_id'];
                if ($student->delete()) {
                    $success_message = "Student deleted successfully!";
                } else {
                    $error_message = "Failed to delete student.";
                }
                break;
        }
    }
}

$students = $student->read();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Management - Smart Attendance</title>
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
        .face-preview {
            width: 100px;
            height: 100px;
            object-fit: cover;
            border-radius: 10px;
            border: 2px solid #e9ecef;
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
                            <a class="nav-link active" href="students.php">
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
                    <h1 class="h2">Student Management</h1>
                    <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addStudentModal">
                        <i class="fas fa-plus me-2"></i>Add Student
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

                <!-- Students Table -->
                <div class="card">
                    <div class="card-header">
                        <h5 class="card-title mb-0">Students List</h5>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-hover">
                                <thead>
                                    <tr>
                                        <th>Roll Number</th>
                                        <th>Name</th>
                                        <th>Grade</th>
                                        <th>Class</th>
                                        <th>Parent</th>
                                        <th>Phone</th>
                                        <th>Face Image</th>
                                        <th>Status</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php while ($row = $students->fetch(PDO::FETCH_ASSOC)): ?>
                                    <tr>
                                        <td><?php echo htmlspecialchars($row['roll_number']); ?></td>
                                        <td><?php echo htmlspecialchars($row['name']); ?></td>
                                        <td><?php echo htmlspecialchars($row['grade']); ?></td>
                                        <td><?php echo htmlspecialchars($row['class']); ?></td>
                                        <td><?php echo htmlspecialchars($row['parent_name']); ?></td>
                                        <td><?php echo htmlspecialchars($row['parent_phone']); ?></td>
                                        <td>
                                            <?php if ($row['face_image_path']): ?>
                                                <img src="../<?php echo htmlspecialchars($row['face_image_path']); ?>" 
                                                     class="face-preview" alt="Face Image">
                                            <?php else: ?>
                                                <span class="text-muted">No Image</span>
                                            <?php endif; ?>
                                        </td>
                                        <td>
                                            <span class="badge <?php echo $row['is_active'] ? 'bg-success' : 'bg-danger'; ?>">
                                                <?php echo $row['is_active'] ? 'Active' : 'Inactive'; ?>
                                            </span>
                                        </td>
                                        <td>
                                            <button class="btn btn-sm btn-outline-primary" onclick="editStudent(<?php echo htmlspecialchars(json_encode($row)); ?>)">
                                                <i class="fas fa-edit"></i>
                                            </button>
                                            <button class="btn btn-sm btn-outline-danger" onclick="deleteStudent(<?php echo $row['id']; ?>)">
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

    <!-- Add Student Modal -->
    <div class="modal fade" id="addStudentModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Add New Student</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form method="POST" enctype="multipart/form-data">
                    <div class="modal-body">
                        <input type="hidden" name="action" value="create">
                        
                        <div class="row">
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="roll_number" class="form-label">Roll Number</label>
                                    <input type="text" class="form-control" id="roll_number" name="roll_number" required>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="name" class="form-label">Student Name</label>
                                    <input type="text" class="form-control" id="name" name="name" required>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="grade" class="form-label">Grade</label>
                                    <select class="form-select" id="grade" name="grade" required>
                                        <option value="">Select Grade</option>
<?php foreach ($active_grades as $g): ?>
                                        <option value="<?php echo htmlspecialchars($g['name']); ?>">
                                            <?php echo htmlspecialchars($g['name'] . ' (Level ' . $g['level'] . ')'); ?>
                                        </option>
<?php endforeach; ?>
                                    </select>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="class" class="form-label">Class</label>
                                    <input type="text" class="form-control" id="class" name="class">
                                </div>
                            </div>
                            
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="parent_name" class="form-label">Parent Name</label>
                                    <input type="text" class="form-control" id="parent_name" name="parent_name" required>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="parent_phone" class="form-label">Parent Phone</label>
                                    <input type="text" class="form-control" id="parent_phone" name="parent_phone" required>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="parent_email" class="form-label">Parent Email</label>
                                    <input type="email" class="form-control" id="parent_email" name="parent_email">
                                </div>
                                
                                <div class="mb-3">
                                    <label for="face_image" class="form-label">Face Image</label>
                                    <input type="file" class="form-control" id="face_image" name="face_image" accept="image/*">
                                    <small class="form-text text-muted">Upload a clear face photo for recognition</small>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary">Add Student</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Edit Student Modal -->
    <div class="modal fade" id="editStudentModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Edit Student</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form method="POST" enctype="multipart/form-data">
                    <div class="modal-body">
                        <input type="hidden" name="action" value="update">
                        <input type="hidden" name="student_id" id="edit_student_id">
                        
                        <div class="row">
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="edit_roll_number" class="form-label">Roll Number</label>
                                    <input type="text" class="form-control" id="edit_roll_number" name="roll_number" required>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="edit_name" class="form-label">Student Name</label>
                                    <input type="text" class="form-control" id="edit_name" name="name" required>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="edit_grade" class="form-label">Grade</label>
                                    <select class="form-select" id="edit_grade" name="grade" required>
                                        <option value="">Select Grade</option>
<?php foreach ($active_grades as $g): ?>
                                        <option value="<?php echo htmlspecialchars($g['name']); ?>">
                                            <?php echo htmlspecialchars($g['name'] . ' (Level ' . $g['level'] . ')'); ?>
                                        </option>
<?php endforeach; ?>
                                    </select>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="edit_class" class="form-label">Class</label>
                                    <input type="text" class="form-control" id="edit_class" name="class">
                                </div>
                            </div>
                            
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="edit_parent_name" class="form-label">Parent Name</label>
                                    <input type="text" class="form-control" id="edit_parent_name" name="parent_name" required>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="edit_parent_phone" class="form-label">Parent Phone</label>
                                    <input type="text" class="form-control" id="edit_parent_phone" name="parent_phone" required>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="edit_parent_email" class="form-label">Parent Email</label>
                                    <input type="email" class="form-control" id="edit_parent_email" name="parent_email">
                                </div>
                                
                                <div class="mb-3">
                                    <label for="edit_face_image" class="form-label">Face Image</label>
                                    <input type="file" class="form-control" id="edit_face_image" name="face_image" accept="image/*">
                                    <small class="form-text text-muted">Leave empty to keep current image</small>
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
                        <button type="submit" class="btn btn-primary">Update Student</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div class="modal fade" id="deleteStudentModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Confirm Delete</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form method="POST">
                    <div class="modal-body">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="student_id" id="delete_student_id">
                        <p>Are you sure you want to delete this student? This action cannot be undone.</p>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-danger">Delete Student</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function editStudent(student) {
            document.getElementById('edit_student_id').value = student.id;
            document.getElementById('edit_roll_number').value = student.roll_number;
            document.getElementById('edit_name').value = student.name;
            document.getElementById('edit_grade').value = student.grade;
            document.getElementById('edit_class').value = student.class;
            document.getElementById('edit_parent_name').value = student.parent_name;
            document.getElementById('edit_parent_phone').value = student.parent_phone;
            document.getElementById('edit_parent_email').value = student.parent_email;
            document.getElementById('edit_is_active').checked = student.is_active == 1;
            
            new bootstrap.Modal(document.getElementById('editStudentModal')).show();
        }
        
        function deleteStudent(studentId) {
            document.getElementById('delete_student_id').value = studentId;
            new bootstrap.Modal(document.getElementById('deleteStudentModal')).show();
        }
    </script>
</body>
</html>
