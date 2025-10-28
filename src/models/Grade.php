<?php
require_once __DIR__ . '/../config/database.php';

class Grade {
    private $conn;
    private $table_name = "grades";

    public $id;
    public $name;
    public $description;
    public $level;
    public $is_active;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create() {
        $query = "INSERT INTO " . $this->table_name . " 
                  SET name=:name, description=:description, level=:level";

        $stmt = $this->conn->prepare($query);

        $this->name = Utils::sanitize($this->name);
        $this->description = Utils::sanitize($this->description);
        $this->level = Utils::sanitize($this->level);

        $stmt->bindParam(":name", $this->name);
        $stmt->bindParam(":description", $this->description);
        $stmt->bindParam(":level", $this->level);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function read() {
        $query = "SELECT id, name, description, level, created_at, is_active 
                  FROM " . $this->table_name . " 
                  ORDER BY level ASC, name ASC";

        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }

    public function readOne() {
        $query = "SELECT id, name, description, level, created_at, is_active 
                  FROM " . $this->table_name . " 
                  WHERE id = ? LIMIT 0,1";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->id);
        $stmt->execute();

        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if($row) {
            $this->name = $row['name'];
            $this->description = $row['description'];
            $this->level = $row['level'];
            $this->is_active = $row['is_active'];
            return true;
        }
        return false;
    }

    public function update() {
        $query = "UPDATE " . $this->table_name . " 
                  SET name=:name, description=:description, level=:level, is_active=:is_active 
                  WHERE id=:id";

        $stmt = $this->conn->prepare($query);

        $this->name = Utils::sanitize($this->name);
        $this->description = Utils::sanitize($this->description);
        $this->level = Utils::sanitize($this->level);

        $stmt->bindParam(':name', $this->name);
        $stmt->bindParam(':description', $this->description);
        $stmt->bindParam(':level', $this->level);
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

    public function getActiveGrades() {
        $query = "SELECT id, name, description, level 
                  FROM " . $this->table_name . " 
                  WHERE is_active = 1 
                  ORDER BY level ASC, name ASC";

        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getTeachersByGrade($grade_id) {
        $query = "SELECT t.id, t.username, t.full_name, t.email, t.position, t.phone 
                  FROM teachers t 
                  WHERE t.grade_id = ? AND t.is_active = 1 
                  ORDER BY t.full_name ASC";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $grade_id);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
?>
