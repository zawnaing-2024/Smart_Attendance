<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../models/Admin.php';
require_once __DIR__ . '/../models/Teacher.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $username = Utils::sanitize($_POST['username']);
    $password = $_POST['password'];
    $user_type = Utils::sanitize($_POST['user_type']);
    
    $database = new Database();
    $db = $database->getConnection();
    
    $login_success = false;
    $user_data = null;
    
    if ($user_type === 'admin') {
        $admin = new Admin($db);
        if ($admin->login($username, $password)) {
            $login_success = true;
            $user_data = [
                'id' => $admin->id,
                'username' => $admin->username,
                'email' => $admin->email,
                'full_name' => $admin->full_name,
                'user_type' => 'admin'
            ];
        }
    } elseif ($user_type === 'teacher') {
        $teacher = new Teacher($db);
        if ($teacher->login($username, $password)) {
            $login_success = true;
            $user_data = [
                'id' => $teacher->id,
                'username' => $teacher->username,
                'email' => $teacher->email,
                'full_name' => $teacher->full_name,
                'position' => $teacher->position,
                'grade_id' => $teacher->grade_id,
                'user_type' => 'teacher'
            ];
        }
    }
    
    if ($login_success && $user_data) {
        $_SESSION['user_id'] = $user_data['id'];
        $_SESSION['username'] = $user_data['username'];
        $_SESSION['full_name'] = $user_data['full_name'];
        $_SESSION['user_type'] = $user_data['user_type'];
        $_SESSION['email'] = $user_data['email'];
        
        if (isset($user_data['position'])) {
            $_SESSION['position'] = $user_data['position'];
        }
        
        if (isset($user_data['grade_id'])) {
            $_SESSION['grade_id'] = $user_data['grade_id'];
        }
        
        // Redirect based on user type
        if ($user_type === 'admin') {
            header('Location: /admin/dashboard.php');
        } else {
            header('Location: /teacher/dashboard.php');
        }
        exit();
    } else {
        header('Location: ../login.php?error=Invalid credentials');
        exit();
    }
} else {
    header('Location: ../login.php?error=Invalid request');
    exit();
}
?>
