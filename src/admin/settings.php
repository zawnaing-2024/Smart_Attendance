<?php
require_once '../config/database.php';
require_once '../models/DetectionSchedule.php';
require_once '../models/Camera.php';

// Ensure authentication before any output
Utils::requireAdmin();

$database = new Database();
$db = $database->getConnection();
$detection_schedule = new DetectionSchedule($db);
$camera = new Camera($db);

// Handle form submissions
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['action'])) {
        switch ($_POST['action']) {
            case 'update_sms_config':
                $provider = Utils::sanitize($_POST['provider']);
                $api_key = Utils::sanitize($_POST['api_key']);
                $api_secret = Utils::sanitize($_POST['api_secret']);
                $sender_id = Utils::sanitize($_POST['sender_id']);
                $is_active = isset($_POST['is_active']) ? 1 : 0;
                
                try {
                    $stmt = $db->prepare("
                        INSERT INTO sms_config (provider, api_key, api_secret, sender_id, is_active) 
                        VALUES (?, ?, ?, ?, ?)
                        ON DUPLICATE KEY UPDATE 
                        api_key = VALUES(api_key),
                        api_secret = VALUES(api_secret),
                        sender_id = VALUES(sender_id),
                        is_active = VALUES(is_active)
                    ");
                    $stmt->execute([$provider, $api_key, $api_secret, $sender_id, $is_active]);
                    $success_message = "SMS configuration updated successfully!";
                } catch (Exception $e) {
                    $error_message = "Failed to update SMS configuration: " . $e->getMessage();
                }
                break;
                
            case 'update_system_settings':
                $attendance_threshold = floatval($_POST['attendance_threshold']);
                $sms_enabled = isset($_POST['sms_enabled']) ? 'true' : 'false';
                $auto_confirm_attendance = isset($_POST['auto_confirm_attendance']) ? 'true' : 'false';
                $attendance_timeout = intval($_POST['attendance_timeout']);
                $detection_enabled = isset($_POST['detection_enabled']) ? 'true' : 'false';
                $live_view_always_on = isset($_POST['live_view_always_on']) ? 'true' : 'false';
                
                try {
                    $settings = [
                        'attendance_threshold' => $attendance_threshold,
                        'sms_enabled' => $sms_enabled,
                        'auto_confirm_attendance' => $auto_confirm_attendance,
                        'attendance_timeout' => $attendance_timeout,
                        'detection_enabled' => $detection_enabled,
                        'live_view_always_on' => $live_view_always_on
                    ];
                    
                    foreach ($settings as $key => $value) {
                        $stmt = $db->prepare("
                            INSERT INTO system_settings (setting_key, setting_value) 
                            VALUES (?, ?)
                            ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)
                        ");
                        $stmt->execute([$key, $value]);
                    }
                    
                    $success_message = "System settings updated successfully!";
                } catch (Exception $e) {
                    $error_message = "Failed to update system settings: " . $e->getMessage();
                }
                break;
                
            case 'update_detection_schedule':
                $camera_id = intval($_POST['camera_id']);
                $day_of_week = Utils::sanitize($_POST['day_of_week']);
                $start_time = $_POST['start_time'];
                $end_time = $_POST['end_time'];
                $is_active = isset($_POST['is_active']) ? 1 : 0;
                
                try {
                    $detection_schedule->camera_id = $camera_id;
                    $detection_schedule->day_of_week = $day_of_week;
                    $detection_schedule->start_time = $start_time;
                    $detection_schedule->end_time = $end_time;
                    $detection_schedule->is_active = $is_active;
                    
                    if ($detection_schedule->create()) {
                        $success_message = "Detection schedule updated successfully!";
                    } else {
                        $error_message = "Failed to update detection schedule.";
                    }
                } catch (Exception $e) {
                    $error_message = "Failed to update detection schedule: " . $e->getMessage();
                }
                break;
                
            case 'delete_detection_schedule':
                $schedule_id = intval($_POST['schedule_id']);
                
                try {
                    $detection_schedule->id = $schedule_id;
                    if ($detection_schedule->delete()) {
                        $success_message = "Detection schedule deleted successfully!";
                    } else {
                        $error_message = "Failed to delete detection schedule.";
                    }
                } catch (Exception $e) {
                    $error_message = "Failed to delete detection schedule: " . $e->getMessage();
                }
                break;
        }
    }
}

// Get current SMS configuration
$sms_config = null;
try {
    $stmt = $db->query("SELECT * FROM sms_config WHERE is_active = 1 LIMIT 1");
    $sms_config = $stmt->fetch(PDO::FETCH_ASSOC);
} catch (Exception $e) {
    // SMS config not found
}

// Get system settings
$system_settings = [];
try {
    $stmt = $db->query("SELECT setting_key, setting_value FROM system_settings");
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $system_settings[$row['setting_key']] = $row['setting_value'];
    }
} catch (Exception $e) {
    // Settings not found
}

// Get detection schedules
$detection_schedules = [];
try {
    $detection_schedules = $detection_schedule->read()->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) {
    // Schedules not found
}

// Get cameras
$cameras = [];
try {
    $cameras = $camera->read()->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) {
    // Cameras not found
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Settings - Smart Attendance</title>
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
        .form-control, .form-select {
            border-radius: 10px;
            border: 2px solid #e9ecef;
        }
        .form-control:focus, .form-select:focus {
            border-color: #667eea;
            box-shadow: 0 0 0 0.2rem rgba(102, 126, 234, 0.25);
        }
        .settings-section {
            margin-bottom: 2rem;
        }
        .api-status {
            padding: 10px 15px;
            border-radius: 10px;
            margin-bottom: 15px;
        }
        .api-status.active {
            background-color: #d4edda;
            border: 1px solid #c3e6cb;
            color: #155724;
        }
        .api-status.inactive {
            background-color: #f8d7da;
            border: 1px solid #f5c6cb;
            color: #721c24;
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
                            <a class="nav-link" href="live_view.php">
                                <i class="fas fa-eye me-2"></i>Live View
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link active" href="settings.php">
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
                    <h1 class="h2">System Settings</h1>
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

                <!-- SMS Configuration -->
                <div class="settings-section">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="card-title mb-0">
                                <i class="fas fa-sms me-2"></i>SMS API Configuration
                            </h5>
                        </div>
                        <div class="card-body">
                            <?php if ($sms_config): ?>
                                <div class="api-status active">
                                    <i class="fas fa-check-circle me-2"></i>
                                    SMS API is configured and active
                                </div>
                            <?php else: ?>
                                <div class="api-status inactive">
                                    <i class="fas fa-exclamation-triangle me-2"></i>
                                    SMS API is not configured
                                </div>
                            <?php endif; ?>
                            
                            <form method="POST">
                                <input type="hidden" name="action" value="update_sms_config">
                                
                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="mb-3">
                                            <label for="provider" class="form-label">SMS Provider</label>
                                            <select class="form-select" id="provider" name="provider" required>
                                                <option value="">Select Provider</option>
                                                <option value="twilio" <?php echo ($sms_config && $sms_config['provider'] == 'twilio') ? 'selected' : ''; ?>>Twilio</option>
                                                <option value="nexmo" <?php echo ($sms_config && $sms_config['provider'] == 'nexmo') ? 'selected' : ''; ?>>Nexmo (Vonage)</option>
                                                <option value="textlocal" <?php echo ($sms_config && $sms_config['provider'] == 'textlocal') ? 'selected' : ''; ?>>TextLocal</option>
                                            </select>
                                        </div>
                                        
                                        <div class="mb-3">
                                            <label for="api_key" class="form-label">API Key</label>
                                            <input type="text" class="form-control" id="api_key" name="api_key" 
                                                   value="<?php echo $sms_config ? htmlspecialchars($sms_config['api_key']) : ''; ?>" required>
                                        </div>
                                    </div>
                                    
                                    <div class="col-md-6">
                                        <div class="mb-3">
                                            <label for="api_secret" class="form-label">API Secret</label>
                                            <input type="password" class="form-control" id="api_secret" name="api_secret" 
                                                   value="<?php echo $sms_config ? htmlspecialchars($sms_config['api_secret']) : ''; ?>" required>
                                        </div>
                                        
                                        <div class="mb-3">
                                            <label for="sender_id" class="form-label">Sender ID</label>
                                            <input type="text" class="form-control" id="sender_id" name="sender_id" 
                                                   value="<?php echo $sms_config ? htmlspecialchars($sms_config['sender_id']) : ''; ?>" required>
                                            <small class="form-text text-muted">Phone number or alphanumeric sender ID</small>
                                        </div>
                                    </div>
                                </div>
                                
                                <div class="mb-3">
                                    <div class="form-check">
                                        <input class="form-check-input" type="checkbox" id="is_active" name="is_active" 
                                               <?php echo ($sms_config && $sms_config['is_active']) ? 'checked' : ''; ?>>
                                        <label class="form-check-label" for="is_active">
                                            Enable SMS notifications
                                        </label>
                                    </div>
                                </div>
                                
                                <button type="submit" class="btn btn-primary">
                                    <i class="fas fa-save me-2"></i>Save SMS Configuration
                                </button>
                            </form>
                        </div>
                    </div>
                </div>

                <!-- System Settings -->
                <div class="settings-section">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="card-title mb-0">
                                <i class="fas fa-cogs me-2"></i>System Settings
                            </h5>
                        </div>
                        <div class="card-body">
                            <form method="POST">
                                <input type="hidden" name="action" value="update_system_settings">
                                
                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="mb-3">
                                            <label for="attendance_threshold" class="form-label">Face Recognition Threshold</label>
                                            <input type="number" class="form-control" id="attendance_threshold" name="attendance_threshold" 
                                                   value="<?php echo $system_settings['attendance_threshold'] ?? '0.6'; ?>" 
                                                   min="0.1" max="1.0" step="0.1" required>
                                            <small class="form-text text-muted">Lower values = more sensitive recognition (0.1-1.0)</small>
                                        </div>
                                        
                                        <div class="mb-3">
                                            <label for="attendance_timeout" class="form-label">Attendance Timeout (minutes)</label>
                                            <input type="number" class="form-control" id="attendance_timeout" name="attendance_timeout" 
                                                   value="<?php echo $system_settings['attendance_timeout'] ?? '30'; ?>" 
                                                   min="1" max="1440" required>
                                            <small class="form-text text-muted">Minimum time between attendance records for same student</small>
                                        </div>
                                    </div>
                                    
                                    <div class="col-md-6">
                                        <div class="mb-3">
                                            <div class="form-check">
                                                <input class="form-check-input" type="checkbox" id="sms_enabled" name="sms_enabled" 
                                                       <?php echo ($system_settings['sms_enabled'] ?? 'false') == 'true' ? 'checked' : ''; ?>>
                                                <label class="form-check-label" for="sms_enabled">
                                                    Enable SMS notifications globally
                                                </label>
                                            </div>
                                        </div>
                                        
                                        <div class="mb-3">
                                            <div class="form-check">
                                                <input class="form-check-input" type="checkbox" id="auto_confirm_attendance" name="auto_confirm_attendance" 
                                                       <?php echo ($system_settings['auto_confirm_attendance'] ?? 'true') == 'true' ? 'checked' : ''; ?>>
                                                <label class="form-check-label" for="auto_confirm_attendance">
                                                    Auto-confirm attendance records
                                                </label>
                                            </div>
                                        </div>
                                        
                                        <div class="mb-3">
                                            <div class="form-check">
                                                <input class="form-check-input" type="checkbox" id="detection_enabled" name="detection_enabled" 
                                                       <?php echo ($system_settings['detection_enabled'] ?? 'true') == 'true' ? 'checked' : ''; ?>>
                                                <label class="form-check-label" for="detection_enabled">
                                                    Enable face detection system
                                                </label>
                                            </div>
                                        </div>
                                        
                                        <div class="mb-3">
                                            <div class="form-check">
                                                <input class="form-check-input" type="checkbox" id="live_view_always_on" name="live_view_always_on" 
                                                       <?php echo ($system_settings['live_view_always_on'] ?? 'true') == 'true' ? 'checked' : ''; ?>>
                                                <label class="form-check-label" for="live_view_always_on">
                                                    Keep camera live view always visible
                                                </label>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                
                                <button type="submit" class="btn btn-primary">
                                    <i class="fas fa-save me-2"></i>Save System Settings
                                </button>
                            </form>
                        </div>
                    </div>
                </div>

                <!-- Face Detection Schedule -->
                <div class="settings-section">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="card-title mb-0">
                                <i class="fas fa-clock me-2"></i>Face Detection Schedule
                            </h5>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-6">
                                    <h6>Add Detection Schedule</h6>
                                    <form method="POST">
                                        <input type="hidden" name="action" value="update_detection_schedule">
                                        
                                        <div class="mb-3">
                                            <label for="camera_id" class="form-label">Camera</label>
                                            <select class="form-select" id="camera_id" name="camera_id" required>
                                                <option value="">Select Camera</option>
                                                <?php foreach ($cameras as $camera_option): ?>
                                                    <option value="<?php echo $camera_option['id']; ?>">
                                                        <?php echo htmlspecialchars($camera_option['name'] . ' (' . $camera_option['location'] . ')'); ?>
                                                    </option>
                                                <?php endforeach; ?>
                                            </select>
                                        </div>
                                        
                                        <div class="mb-3">
                                            <label for="day_of_week" class="form-label">Day of Week</label>
                                            <select class="form-select" id="day_of_week" name="day_of_week" required>
                                                <option value="">Select Day</option>
                                                <option value="monday">Monday</option>
                                                <option value="tuesday">Tuesday</option>
                                                <option value="wednesday">Wednesday</option>
                                                <option value="thursday">Thursday</option>
                                                <option value="friday">Friday</option>
                                                <option value="saturday">Saturday</option>
                                                <option value="sunday">Sunday</option>
                                            </select>
                                        </div>
                                        
                                        <div class="row">
                                            <div class="col-md-6">
                                                <div class="mb-3">
                                                    <label for="start_time" class="form-label">Start Time</label>
                                                    <input type="time" class="form-control" id="start_time" name="start_time" required>
                                                </div>
                                            </div>
                                            <div class="col-md-6">
                                                <div class="mb-3">
                                                    <label for="end_time" class="form-label">End Time</label>
                                                    <input type="time" class="form-control" id="end_time" name="end_time" required>
                                                </div>
                                            </div>
                                        </div>
                                        
                                        <div class="mb-3">
                                            <div class="form-check">
                                                <input class="form-check-input" type="checkbox" id="is_active" name="is_active" checked>
                                                <label class="form-check-label" for="is_active">
                                                    Active
                                                </label>
                                            </div>
                                        </div>
                                        
                                        <button type="submit" class="btn btn-primary">
                                            <i class="fas fa-plus me-2"></i>Add Schedule
                                        </button>
                                    </form>
                                </div>
                                
                                <div class="col-md-6">
                                    <h6>Current Schedules</h6>
                                    <div class="table-responsive">
                                        <table class="table table-sm">
                                            <thead>
                                                <tr>
                                                    <th>Camera</th>
                                                    <th>Day</th>
                                                    <th>Time</th>
                                                    <th>Status</th>
                                                    <th>Action</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <?php foreach ($detection_schedules as $schedule): ?>
                                                <tr>
                                                    <td><?php echo htmlspecialchars($schedule['camera_name'] ?? 'Unknown'); ?></td>
                                                    <td><?php echo ucfirst($schedule['day_of_week']); ?></td>
                                                    <td><?php echo $schedule['start_time'] . ' - ' . $schedule['end_time']; ?></td>
                                                    <td>
                                                        <span class="badge <?php echo $schedule['is_active'] ? 'bg-success' : 'bg-danger'; ?>">
                                                            <?php echo $schedule['is_active'] ? 'Active' : 'Inactive'; ?>
                                                        </span>
                                                    </td>
                                                    <td>
                                                        <form method="POST" style="display: inline;">
                                                            <input type="hidden" name="action" value="delete_detection_schedule">
                                                            <input type="hidden" name="schedule_id" value="<?php echo $schedule['id']; ?>">
                                                            <button type="submit" class="btn btn-sm btn-outline-danger" 
                                                                    onclick="return confirm('Are you sure you want to delete this schedule?')">
                                                                <i class="fas fa-trash"></i>
                                                            </button>
                                                        </form>
                                                    </td>
                                                </tr>
                                                <?php endforeach; ?>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- SMS Provider Information -->
                <div class="settings-section">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="card-title mb-0">
                                <i class="fas fa-info-circle me-2"></i>SMS Provider Information
                            </h5>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-4">
                                    <h6>Twilio</h6>
                                    <ul class="list-unstyled">
                                        <li><strong>API Key:</strong> Account SID</li>
                                        <li><strong>API Secret:</strong> Auth Token</li>
                                        <li><strong>Sender ID:</strong> Twilio Phone Number</li>
                                        <li><small class="text-muted">Website: twilio.com</small></li>
                                    </ul>
                                </div>
                                <div class="col-md-4">
                                    <h6>Nexmo (Vonage)</h6>
                                    <ul class="list-unstyled">
                                        <li><strong>API Key:</strong> API Key</li>
                                        <li><strong>API Secret:</strong> API Secret</li>
                                        <li><strong>Sender ID:</strong> From Number</li>
                                        <li><small class="text-muted">Website: vonage.com</small></li>
                                    </ul>
                                </div>
                                <div class="col-md-4">
                                    <h6>TextLocal</h6>
                                    <ul class="list-unstyled">
                                        <li><strong>API Key:</strong> API Key</li>
                                        <li><strong>API Secret:</strong> Not Required</li>
                                        <li><strong>Sender ID:</strong> Sender Name</li>
                                        <li><small class="text-muted">Website: textlocal.com</small></li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
