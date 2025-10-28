<?php
// Start session before any output
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}
// Database configuration
class Database {
    private $host;
    private $db_name;
    private $username;
    private $password;
    private $conn;

    public function __construct() {
        $this->host = getenv('DB_HOST') ?: ($_ENV['DB_HOST'] ?? 'db');
        $this->db_name = getenv('DB_NAME') ?: ($_ENV['DB_NAME'] ?? 'smart_attendance');
        $this->username = getenv('DB_USER') ?: ($_ENV['DB_USER'] ?? 'attendance_user');
        $this->password = getenv('DB_PASS') ?: ($_ENV['DB_PASS'] ?? 'attendance_pass');
    }

    public function getConnection() {
        $this->conn = null;
        try {
            $this->conn = new PDO(
                "mysql:host=" . $this->host . ";dbname=" . $this->db_name,
                $this->username,
                $this->password,
                array(PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION)
            );
        } catch(PDOException $exception) {
            // Avoid sending output that would break headers
            // error_log can be used for diagnostics
            error_log('DB Connection error: ' . $exception->getMessage());
        }
        return $this->conn;
    }
}

// Utility functions
class Utils {
    public static function sanitize($data) {
        return htmlspecialchars(strip_tags(trim($data)));
    }
    
    public static function generateToken() {
        return bin2hex(random_bytes(32));
    }
    
    public static function hashPassword($password) {
        return password_hash($password, PASSWORD_DEFAULT);
    }
    
    public static function verifyPassword($password, $hash) {
        return password_verify($password, $hash);
    }
    
    public static function formatDate($date) {
        return date('Y-m-d H:i:s', strtotime($date));
    }
    
    public static function isLoggedIn() {
        return isset($_SESSION['user_id']) && !empty($_SESSION['user_id']);
    }
    
    public static function requireLogin() {
        if (!self::isLoggedIn()) {
            header('Location: /login.php');
            exit();
        }
    }
    
    public static function requireAdmin() {
        self::requireLogin();
        if ($_SESSION['user_type'] !== 'admin') {
            header('Location: /unauthorized.php');
            exit();
        }
    }
    
    public static function requireTeacher() {
        self::requireLogin();
        if ($_SESSION['user_type'] !== 'teacher') {
            header('Location: /unauthorized.php');
            exit();
        }
    }
}

// Error reporting for development
// error_reporting(E_ALL);
// ini_set('display_errors', 1);
?>
