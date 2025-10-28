<?php
require_once __DIR__ . '/../config/database.php';

class Attendance {
    private $conn;
    private $table_name = "attendance";

    public $id;
    public $student_id;
    public $camera_id;
    public $attendance_type;
    public $detected_at;
    public $confidence_score;
    public $image_path;
    public $status;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create() {
        $query = "INSERT INTO " . $this->table_name . " 
                  SET student_id=:student_id, camera_id=:camera_id, 
                      attendance_type=:attendance_type, confidence_score=:confidence_score, 
                      image_path=:image_path";

        $stmt = $this->conn->prepare($query);

        $stmt->bindParam(":student_id", $this->student_id);
        $stmt->bindParam(":camera_id", $this->camera_id);
        $stmt->bindParam(":attendance_type", $this->attendance_type);
        $stmt->bindParam(":confidence_score", $this->confidence_score);
        $stmt->bindParam(":image_path", $this->image_path);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function read() {
        $query = "SELECT a.id, a.student_id, a.camera_id, a.attendance_type, 
                         a.detected_at, a.confidence_score, a.image_path, a.status,
                         s.name as student_name, s.roll_number, s.grade,
                         c.name as camera_name, c.location
                  FROM " . $this->table_name . " a
                  LEFT JOIN students s ON a.student_id = s.id
                  LEFT JOIN cameras c ON a.camera_id = c.id
                  ORDER BY a.detected_at DESC";

        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }

    public function readByDateRange($start_date, $end_date) {
        $query = "SELECT a.id, a.student_id, a.camera_id, a.attendance_type, 
                         a.detected_at, a.confidence_score, a.image_path, a.status,
                         s.name as student_name, s.roll_number, s.grade,
                         c.name as camera_name, c.location
                  FROM " . $this->table_name . " a
                  LEFT JOIN students s ON a.student_id = s.id
                  LEFT JOIN cameras c ON a.camera_id = c.id
                  WHERE DATE(a.detected_at) BETWEEN ? AND ?
                  ORDER BY a.detected_at DESC";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $start_date);
        $stmt->bindParam(2, $end_date);
        $stmt->execute();
        return $stmt;
    }

    public function readByStudent($student_id, $date = null) {
        $query = "SELECT a.id, a.student_id, a.camera_id, a.attendance_type, 
                         a.detected_at, a.confidence_score, a.image_path, a.status,
                         s.name as student_name, s.roll_number, s.grade,
                         c.name as camera_name, c.location
                  FROM " . $this->table_name . " a
                  LEFT JOIN students s ON a.student_id = s.id
                  LEFT JOIN cameras c ON a.camera_id = c.id
                  WHERE a.student_id = ?";
        
        if($date) {
            $query .= " AND DATE(a.detected_at) = ?";
        }
        
        $query .= " ORDER BY a.detected_at DESC";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $student_id);
        if($date) {
            $stmt->bindParam(2, $date);
        }
        $stmt->execute();
        return $stmt;
    }

    public function updateStatus($status) {
        $query = "UPDATE " . $this->table_name . " SET status = ? WHERE id = ?";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $status);
        $stmt->bindParam(2, $this->id);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function getTodayAttendance() {
        $query = "SELECT COUNT(*) as total_entries,
                         SUM(CASE WHEN attendance_type = 'entry' THEN 1 ELSE 0 END) as entries,
                         SUM(CASE WHEN attendance_type = 'exit' THEN 1 ELSE 0 END) as exits
                  FROM " . $this->table_name . " 
                  WHERE DATE(detected_at) = CURDATE()";

        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function getAttendanceStats($start_date, $end_date) {
        $query = "SELECT DATE(detected_at) as date,
                         COUNT(*) as total_records,
                         SUM(CASE WHEN attendance_type = 'entry' THEN 1 ELSE 0 END) as entries,
                         SUM(CASE WHEN attendance_type = 'exit' THEN 1 ELSE 0 END) as exits,
                         COUNT(DISTINCT student_id) as unique_students
                  FROM " . $this->table_name . " 
                  WHERE DATE(detected_at) BETWEEN ? AND ?
                  GROUP BY DATE(detected_at)
                  ORDER BY date DESC";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $start_date);
        $stmt->bindParam(2, $end_date);
        $stmt->execute();
        return $stmt;
    }

    public function getRecentAttendance($limit = 10) {
        $query = "SELECT a.id, a.student_id, a.camera_id, a.attendance_type, 
                         a.detected_at, a.confidence_score, a.image_path, a.status,
                         s.name as student_name, s.roll_number, s.grade,
                         c.name as camera_name, c.location
                  FROM " . $this->table_name . " a
                  LEFT JOIN students s ON a.student_id = s.id
                  LEFT JOIN cameras c ON a.camera_id = c.id
                  ORDER BY a.detected_at DESC
                  LIMIT ?";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $limit, PDO::PARAM_INT);
        $stmt->execute();
        return $stmt;
    }

    public function getAttendanceReports($start_date, $end_date) {
        $query = "SELECT a.id, a.student_id, a.camera_id, a.attendance_type, 
                         a.detected_at, a.confidence_score, a.image_path, a.status,
                         s.name as student_name, s.roll_number, s.grade,
                         c.name as camera_name, c.location
                  FROM " . $this->table_name . " a
                  LEFT JOIN students s ON a.student_id = s.id
                  LEFT JOIN cameras c ON a.camera_id = c.id
                  WHERE DATE(a.detected_at) BETWEEN ? AND ?
                  ORDER BY a.detected_at DESC";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $start_date);
        $stmt->bindParam(2, $end_date);
        $stmt->execute();
        return $stmt;
    }

    public function getStudentAttendanceToday($student_id) {
        $query = "SELECT 
                    SUM(CASE WHEN attendance_type = 'entry' THEN 1 ELSE 0 END) > 0 as `entry`,
                    SUM(CASE WHEN attendance_type = 'exit' THEN 1 ELSE 0 END) > 0 as `exit`
                  FROM " . $this->table_name . " 
                  WHERE student_id = ? AND DATE(detected_at) = CURDATE()";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $student_id);
        $stmt->execute();
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        return [
            'entry' => (bool)$result['entry'],
            'exit' => (bool)$result['exit']
        ];
    }
}
?>
