<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../models/Student.php';
require_once __DIR__ . '/../models/Attendance.php';
require_once __DIR__ . '/../models/Grade.php';

Utils::requireTeacher();

$database = new Database();
$db = $database->getConnection();
$student = new Student($db);
$attendance = new Attendance($db);
$grade = new Grade($db);

// Get teacher's assigned grade
$teacher_grade_id = $_SESSION['grade_id'] ?? null;
$teacher_grade_name = null;
if ($teacher_grade_id) {
    $grade->id = $teacher_grade_id;
    if ($grade->readOne()) {
        $teacher_grade_name = $grade->name;
    }
}

// Handle form submissions
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['action'])) {
        switch ($_POST['action']) {
            case 'create':
                $student->roll_number = $_POST['roll_number'];
                $student->name = $_POST['name'];
                $student->grade = $teacher_grade_name; // Use teacher's grade
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
                $student->grade = $teacher_grade_name; // Use teacher's grade
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

// Get students list (filtered by teacher's grade if assigned)
if ($teacher_grade_name) {
    $students = $student->readByGrade($teacher_grade_name);
} else {
    $students = $student->read();
}

// Get attendance summary for each student
$attendance_summary = [];
while ($row = $students->fetch(PDO::FETCH_ASSOC)) {
    $student_id = $row['id'];
    $today_attendance = $attendance->getStudentAttendanceToday($student_id);
    $attendance_summary[$student_id] = $today_attendance;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Students - Teacher Portal</title>
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
        .student-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            object-fit: cover;
        }
        .attendance-status {
            font-size: 0.8rem;
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
                            <a class="nav-link active" href="students.php">
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
                    <h1 class="h2">Students<?php if ($teacher_grade_name): ?> - <?php echo htmlspecialchars($teacher_grade_name); ?><?php endif; ?></h1>
                    <div class="btn-toolbar mb-2 mb-md-0">
                        <div class="btn-group me-2">
                            <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addStudentModal">
                                <i class="fas fa-plus me-1"></i>Add Student
                            </button>
                            <button type="button" class="btn btn-sm btn-outline-secondary">
                                <i class="fas fa-download me-1"></i>Export List
                            </button>
                        </div>
                    </div>
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

                <!-- Students List -->
                <div class="row">
                    <div class="col-12">
                        <div class="card">
                            <div class="card-header">
                                <h5 class="card-title mb-0">Student Directory</h5>
                            </div>
                            <div class="card-body">
                                <div class="table-responsive">
                                    <table class="table table-hover">
                                        <thead>
                                            <tr>
                                                <th>Photo</th>
                                                <th>Name</th>
                                                <th>Roll Number</th>
                                                <th>Grade</th>
                                                <th>Class</th>
                                                <th>Parent Contact</th>
                                                <th>Today's Status</th>
                                                <th>Actions</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <?php 
                                            $students->execute(); // Reset cursor
                                            while ($row = $students->fetch(PDO::FETCH_ASSOC)): 
                                                $student_id = $row['id'];
                                                $today_status = $attendance_summary[$student_id] ?? ['entry' => false, 'exit' => false];
                                            ?>
                                            <tr>
                                                <td>
                                                    <?php if ($row['face_image_path']): ?>
                                                        <img src="../<?php echo htmlspecialchars($row['face_image_path']); ?>" 
                                                             class="student-avatar" 
                                                             alt="Student Photo">
                                                    <?php else: ?>
                                                        <div class="student-avatar bg-secondary d-flex align-items-center justify-content-center">
                                                            <i class="fas fa-user text-white"></i>
                                                        </div>
                                                    <?php endif; ?>
                                                </td>
                                                <td>
                                                    <strong><?php echo htmlspecialchars($row['name']); ?></strong>
                                                </td>
                                                <td><?php echo htmlspecialchars($row['roll_number']); ?></td>
                                                <td>
                                                    <span class="badge bg-primary"><?php echo htmlspecialchars($row['grade']); ?></span>
                                                </td>
                                                <td><?php echo htmlspecialchars($row['class']); ?></td>
                                                <td>
                                                    <div class="attendance-status">
                                                        <div><i class="fas fa-user me-1"></i><?php echo htmlspecialchars($row['parent_name']); ?></div>
                                                        <div><i class="fas fa-phone me-1"></i><?php echo htmlspecialchars($row['parent_phone']); ?></div>
                                                    </div>
                                                </td>
                                                <td>
                                                    <?php if ($today_status['entry'] && $today_status['exit']): ?>
                                                        <span class="badge bg-success">Complete</span>
                                                    <?php elseif ($today_status['entry']): ?>
                                                        <span class="badge bg-warning">Present</span>
                                                    <?php else: ?>
                                                        <span class="badge bg-danger">Absent</span>
                                                    <?php endif; ?>
                                                </td>
                                                <td>
                                                    <div class="btn-group" role="group">
                                                        <button class="btn btn-sm btn-outline-primary" onclick="viewStudentDetails(<?php echo htmlspecialchars(json_encode($row)); ?>)" title="View Details">
                                                            <i class="fas fa-eye"></i>
                                                        </button>
                                                        <button class="btn btn-sm btn-outline-warning" onclick="editStudent(<?php echo htmlspecialchars(json_encode($row)); ?>)" title="Edit Student">
                                                            <i class="fas fa-edit"></i>
                                                        </button>
                                                        <button class="btn btn-sm btn-outline-danger" onclick="deleteStudent(<?php echo $student_id; ?>, '<?php echo htmlspecialchars($row['name']); ?>')" title="Delete Student">
                                                            <i class="fas fa-trash"></i>
                                                        </button>
                                                        <button class="btn btn-sm btn-outline-info" onclick="viewAttendanceHistory(<?php echo $student_id; ?>)" title="Attendance History">
                                                            <i class="fas fa-history"></i>
                                                        </button>
                                                    </div>
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

                <!-- Student Statistics -->
                <div class="row mt-4">
                    <div class="col-md-3">
                        <div class="card text-center">
                            <div class="card-body">
                                <h5 class="card-title text-primary">
                                    <?php 
                                    $total_students = $db->query("SELECT COUNT(*) as count FROM students WHERE is_active = 1")->fetch()['count'];
                                    echo $total_students;
                                    ?>
                                </h5>
                                <p class="card-text">Total Students</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="card text-center">
                            <div class="card-body">
                                <h5 class="card-title text-success">
                                    <?php 
                                    $present_today = 0;
                                    foreach ($attendance_summary as $status) {
                                        if ($status['entry']) $present_today++;
                                    }
                                    echo $present_today;
                                    ?>
                                </h5>
                                <p class="card-text">Present Today</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="card text-center">
                            <div class="card-body">
                                <h5 class="card-title text-danger">
                                    <?php echo $total_students - $present_today; ?>
                                </h5>
                                <p class="card-text">Absent Today</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="card text-center">
                            <div class="card-body">
                                <h5 class="card-title text-info">
                                    <?php 
                                    $completed_today = 0;
                                    foreach ($attendance_summary as $status) {
                                        if ($status['entry'] && $status['exit']) $completed_today++;
                                    }
                                    echo $completed_today;
                                    ?>
                                </h5>
                                <p class="card-text">Complete Today</p>
                            </div>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <!-- Student Details Modal -->
    <div class="modal fade" id="studentDetailsModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Student Details</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body" id="studentDetailsContent">
                    <!-- Content will be populated by JavaScript -->
                </div>
            </div>
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
                                    <label for="class" class="form-label">Class</label>
                                    <input type="text" class="form-control" id="class" name="class" required>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="parent_name" class="form-label">Parent Name</label>
                                    <input type="text" class="form-control" id="parent_name" name="parent_name" required>
                                </div>
                                <div class="mb-3">
                                    <label for="parent_phone" class="form-label">Parent Phone</label>
                                    <input type="tel" class="form-control" id="parent_phone" name="parent_phone" required>
                                </div>
                                <div class="mb-3">
                                    <label for="parent_email" class="form-label">Parent Email</label>
                                    <input type="email" class="form-control" id="parent_email" name="parent_email">
                                </div>
                            </div>
                        </div>
                        <div class="mb-3">
                            <label for="face_image" class="form-label">Student Photo</label>
                            <input type="file" class="form-control" id="face_image" name="face_image" accept="image/*">
                            <div class="form-text">Upload a clear photo of the student's face for face recognition.</div>
                        </div>
                        <div class="alert alert-info">
                            <i class="fas fa-info-circle me-2"></i>
                            <strong>Grade:</strong> <?php echo htmlspecialchars($teacher_grade_name ?: 'Not assigned'); ?>
                            <br><small>Students will be automatically assigned to your grade.</small>
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
                                    <label for="edit_class" class="form-label">Class</label>
                                    <input type="text" class="form-control" id="edit_class" name="class" required>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label for="edit_parent_name" class="form-label">Parent Name</label>
                                    <input type="text" class="form-control" id="edit_parent_name" name="parent_name" required>
                                </div>
                                <div class="mb-3">
                                    <label for="edit_parent_phone" class="form-label">Parent Phone</label>
                                    <input type="tel" class="form-control" id="edit_parent_phone" name="parent_phone" required>
                                </div>
                                <div class="mb-3">
                                    <label for="edit_parent_email" class="form-label">Parent Email</label>
                                    <input type="email" class="form-control" id="edit_parent_email" name="parent_email">
                                </div>
                            </div>
                        </div>
                        <div class="mb-3">
                            <label for="edit_face_image" class="form-label">Student Photo</label>
                            <input type="file" class="form-control" id="edit_face_image" name="face_image" accept="image/*">
                            <div class="form-text">Upload a new photo to replace the current one.</div>
                        </div>
                        <div class="mb-3">
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" id="edit_is_active" name="is_active">
                                <label class="form-check-label" for="edit_is_active">
                                    Active Student
                                </label>
                            </div>
                        </div>
                        <div class="alert alert-info">
                            <i class="fas fa-info-circle me-2"></i>
                            <strong>Grade:</strong> <?php echo htmlspecialchars($teacher_grade_name ?: 'Not assigned'); ?>
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
                <div class="modal-body">
                    <p>Are you sure you want to delete student <strong id="delete_student_name"></strong>?</p>
                    <p class="text-danger"><i class="fas fa-exclamation-triangle me-2"></i>This action cannot be undone.</p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <form method="POST" style="display: inline;">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="student_id" id="delete_student_id">
                        <button type="submit" class="btn btn-danger">Delete Student</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- Attendance History Modal -->
    <div class="modal fade" id="attendanceHistoryModal" tabindex="-1">
        <div class="modal-dialog modal-xl">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Attendance History</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body" id="attendanceHistoryContent">
                    <!-- Content will be populated by JavaScript -->
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function viewStudentDetails(student) {
            const content = `
                <div class="row">
                    <div class="col-md-4 text-center">
                        ${student.face_image_path ? 
                            `<img src="../${student.face_image_path}" class="img-fluid rounded" alt="Student Photo">` :
                            `<div class="bg-secondary rounded d-flex align-items-center justify-content-center" style="height: 200px;">
                                <i class="fas fa-user fa-5x text-white"></i>
                            </div>`
                        }
                    </div>
                    <div class="col-md-8">
                        <h4>${student.name}</h4>
                        <table class="table table-borderless">
                            <tr><td><strong>Roll Number:</strong></td><td>${student.roll_number}</td></tr>
                            <tr><td><strong>Grade:</strong></td><td><span class="badge bg-primary">${student.grade}</span></td></tr>
                            <tr><td><strong>Class:</strong></td><td>${student.class}</td></tr>
                            <tr><td><strong>Parent Name:</strong></td><td>${student.parent_name}</td></tr>
                            <tr><td><strong>Parent Phone:</strong></td><td>${student.parent_phone}</td></tr>
                            <tr><td><strong>Parent Email:</strong></td><td>${student.parent_email}</td></tr>
                            <tr><td><strong>Status:</strong></td><td><span class="badge ${student.is_active ? 'bg-success' : 'bg-danger'}">${student.is_active ? 'Active' : 'Inactive'}</span></td></tr>
                        </table>
                    </div>
                </div>
            `;
            document.getElementById('studentDetailsContent').innerHTML = content;
            new bootstrap.Modal(document.getElementById('studentDetailsModal')).show();
        }

        function editStudent(student) {
            document.getElementById('edit_student_id').value = student.id;
            document.getElementById('edit_roll_number').value = student.roll_number;
            document.getElementById('edit_name').value = student.name;
            document.getElementById('edit_class').value = student.class;
            document.getElementById('edit_parent_name').value = student.parent_name;
            document.getElementById('edit_parent_phone').value = student.parent_phone;
            document.getElementById('edit_parent_email').value = student.parent_email;
            document.getElementById('edit_is_active').checked = student.is_active == 1;
            
            new bootstrap.Modal(document.getElementById('editStudentModal')).show();
        }

        function deleteStudent(studentId, studentName) {
            document.getElementById('delete_student_id').value = studentId;
            document.getElementById('delete_student_name').textContent = studentName;
            new bootstrap.Modal(document.getElementById('deleteStudentModal')).show();
        }

        function viewAttendanceHistory(studentId) {
            // This would typically fetch data via AJAX
            const content = `
                <div class="alert alert-info">
                    <i class="fas fa-info-circle me-2"></i>
                    Attendance history feature will be implemented in the next version.
                    This will show detailed attendance records for the selected student.
                </div>
            `;
            document.getElementById('attendanceHistoryContent').innerHTML = content;
            new bootstrap.Modal(document.getElementById('attendanceHistoryModal')).show();
        }
    </script>
</body>
</html>
