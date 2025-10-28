<?php
require_once __DIR__ . '/../config/database.php';
Utils::requireTeacher();
header('Location: dashboard.php');
exit();
?>
