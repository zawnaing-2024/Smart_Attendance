<?php
require_once '../config/database.php';

// If not logged in as admin, send to login
if (!Utils::isLoggedIn() || $_SESSION['user_type'] !== 'admin') {
    header('Location: ../login.php');
    exit();
}

// Redirect to dashboard by default
header('Location: dashboard.php');
exit();
?>


