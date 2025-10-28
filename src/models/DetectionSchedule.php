<?php
require_once __DIR__ . '/../config/database.php';

class DetectionSchedule {
    private $conn;
    private $table_name = "detection_schedule";

    public $id;
    public $camera_id;
    public $day_of_week;
    public $start_time;
    public $end_time;
    public $is_active;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create() {
        $query = "INSERT INTO " . $this->table_name . "
                  SET camera_id=:camera_id, day_of_week=:day_of_week, 
                      start_time=:start_time, end_time=:end_time, is_active=:is_active";

        $stmt = $this->conn->prepare($query);

        $this->camera_id = htmlspecialchars(strip_tags($this->camera_id));
        $this->day_of_week = Utils::sanitize($this->day_of_week);
        $this->start_time = htmlspecialchars(strip_tags($this->start_time));
        $this->end_time = htmlspecialchars(strip_tags($this->end_time));
        $this->is_active = htmlspecialchars(strip_tags($this->is_active));

        $stmt->bindParam(":camera_id", $this->camera_id);
        $stmt->bindParam(":day_of_week", $this->day_of_week);
        $stmt->bindParam(":start_time", $this->start_time);
        $stmt->bindParam(":end_time", $this->end_time);
        $stmt->bindParam(":is_active", $this->is_active);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function read() {
        $query = "SELECT ds.id, ds.camera_id, ds.day_of_week, ds.start_time, ds.end_time, 
                         ds.is_active, ds.created_at, c.name as camera_name
                  FROM " . $this->table_name . " ds
                  LEFT JOIN cameras c ON ds.camera_id = c.id
                  ORDER BY ds.camera_id, ds.day_of_week";

        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }

    public function readByCamera($camera_id) {
        $query = "SELECT id, camera_id, day_of_week, start_time, end_time, is_active
                  FROM " . $this->table_name . "
                  WHERE camera_id = ?
                  ORDER BY day_of_week";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $camera_id);
        $stmt->execute();
        return $stmt;
    }

    public function readOne() {
        $query = "SELECT id, camera_id, day_of_week, start_time, end_time, is_active
                  FROM " . $this->table_name . "
                  WHERE id = ? LIMIT 0,1";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->id);
        $stmt->execute();

        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if($row) {
            $this->camera_id = $row['camera_id'];
            $this->day_of_week = $row['day_of_week'];
            $this->start_time = $row['start_time'];
            $this->end_time = $row['end_time'];
            $this->is_active = $row['is_active'];
            return true;
        }
        return false;
    }

    public function update() {
        $query = "UPDATE " . $this->table_name . "
                  SET camera_id=:camera_id, day_of_week=:day_of_week, 
                      start_time=:start_time, end_time=:end_time, is_active=:is_active
                  WHERE id=:id";

        $stmt = $this->conn->prepare($query);

        $this->camera_id = htmlspecialchars(strip_tags($this->camera_id));
        $this->day_of_week = Utils::sanitize($this->day_of_week);
        $this->start_time = htmlspecialchars(strip_tags($this->start_time));
        $this->end_time = htmlspecialchars(strip_tags($this->end_time));
        $this->is_active = htmlspecialchars(strip_tags($this->is_active));

        $stmt->bindParam(':camera_id', $this->camera_id);
        $stmt->bindParam(':day_of_week', $this->day_of_week);
        $stmt->bindParam(':start_time', $this->start_time);
        $stmt->bindParam(':end_time', $this->end_time);
        $stmt->bindParam(':is_active', $this->is_active);
        $stmt->bindParam(':id', $this->id);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function delete() {
        $query = "DELETE FROM " . $this->table_name . " WHERE id = ?";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->id);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function deleteByCamera($camera_id) {
        $query = "DELETE FROM " . $this->table_name . " WHERE camera_id = ?";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $camera_id);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function isDetectionActive($camera_id) {
        $current_day = strtolower(date('l')); // Get current day name
        $current_time = date('H:i:s');
        
        $query = "SELECT COUNT(*) as count FROM " . $this->table_name . "
                  WHERE camera_id = ? AND day_of_week = ? AND is_active = 1
                  AND ? BETWEEN start_time AND end_time";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $camera_id);
        $stmt->bindParam(2, $current_day);
        $stmt->bindParam(3, $current_time);
        $stmt->execute();

        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row['count'] > 0;
    }

    public function getActiveSchedules() {
        $query = "SELECT ds.camera_id, ds.day_of_week, ds.start_time, ds.end_time, c.name as camera_name
                  FROM " . $this->table_name . " ds
                  LEFT JOIN cameras c ON ds.camera_id = c.id
                  WHERE ds.is_active = 1
                  ORDER BY ds.camera_id, ds.day_of_week";

        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
?>
