<?php
require_once __DIR__ . '/../config/database.php';

class Student {
    private $conn;
    private $table_name = "students";

    public $id;
    public $roll_number;
    public $name;
    public $grade;
    public $class;
    public $parent_name;
    public $parent_phone;
    public $parent_email;
    public $face_encoding;
    public $face_image_path;
    public $is_active;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create() {
        $query = "INSERT INTO " . $this->table_name . " 
                  SET roll_number=:roll_number, name=:name, grade=:grade, 
                      class=:class, parent_name=:parent_name, parent_phone=:parent_phone, 
                      parent_email=:parent_email, face_image_path=:face_image_path";

        $stmt = $this->conn->prepare($query);

        $this->roll_number = Utils::sanitize($this->roll_number);
        $this->name = Utils::sanitize($this->name);
        $this->grade = Utils::sanitize($this->grade);
        $this->class = Utils::sanitize($this->class);
        $this->parent_name = Utils::sanitize($this->parent_name);
        $this->parent_phone = Utils::sanitize($this->parent_phone);
        $this->parent_email = Utils::sanitize($this->parent_email);
        $this->face_image_path = Utils::sanitize($this->face_image_path);

        $stmt->bindParam(":roll_number", $this->roll_number);
        $stmt->bindParam(":name", $this->name);
        $stmt->bindParam(":grade", $this->grade);
        $stmt->bindParam(":class", $this->class);
        $stmt->bindParam(":parent_name", $this->parent_name);
        $stmt->bindParam(":parent_phone", $this->parent_phone);
        $stmt->bindParam(":parent_email", $this->parent_email);
        $stmt->bindParam(":face_image_path", $this->face_image_path);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function read() {
        $query = "SELECT id, roll_number, name, grade, class, parent_name, 
                         parent_phone, parent_email, face_image_path, 
                         created_at, is_active 
                  FROM " . $this->table_name . " 
                  ORDER BY roll_number ASC";

        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }

    public function readByGrade($grade_name) {
        $query = "SELECT id, roll_number, name, grade, class, parent_name, 
                         parent_phone, parent_email, face_image_path, 
                         created_at, is_active 
                  FROM " . $this->table_name . " 
                  WHERE grade = ? AND is_active = 1
                  ORDER BY roll_number ASC";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $grade_name);
        $stmt->execute();
        return $stmt;
    }

    public function readOne() {
        $query = "SELECT id, roll_number, name, grade, class, parent_name, 
                         parent_phone, parent_email, face_encoding, face_image_path, 
                         created_at, is_active 
                  FROM " . $this->table_name . " 
                  WHERE id = ? LIMIT 0,1";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->id);
        $stmt->execute();

        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if($row) {
            $this->roll_number = $row['roll_number'];
            $this->name = $row['name'];
            $this->grade = $row['grade'];
            $this->class = $row['class'];
            $this->parent_name = $row['parent_name'];
            $this->parent_phone = $row['parent_phone'];
            $this->parent_email = $row['parent_email'];
            $this->face_encoding = $row['face_encoding'];
            $this->face_image_path = $row['face_image_path'];
            $this->is_active = $row['is_active'];
            return true;
        }
        return false;
    }

    public function update() {
        $query = "UPDATE " . $this->table_name . " 
                  SET roll_number=:roll_number, name=:name, grade=:grade, 
                      class=:class, parent_name=:parent_name, parent_phone=:parent_phone, 
                      parent_email=:parent_email, face_image_path=:face_image_path, 
                      is_active=:is_active 
                  WHERE id=:id";

        $stmt = $this->conn->prepare($query);

        $this->roll_number = Utils::sanitize($this->roll_number);
        $this->name = Utils::sanitize($this->name);
        $this->grade = Utils::sanitize($this->grade);
        $this->class = Utils::sanitize($this->class);
        $this->parent_name = Utils::sanitize($this->parent_name);
        $this->parent_phone = Utils::sanitize($this->parent_phone);
        $this->parent_email = Utils::sanitize($this->parent_email);
        $this->face_image_path = Utils::sanitize($this->face_image_path);

        $stmt->bindParam(':roll_number', $this->roll_number);
        $stmt->bindParam(':name', $this->name);
        $stmt->bindParam(':grade', $this->grade);
        $stmt->bindParam(':class', $this->class);
        $stmt->bindParam(':parent_name', $this->parent_name);
        $stmt->bindParam(':parent_phone', $this->parent_phone);
        $stmt->bindParam(':parent_email', $this->parent_email);
        $stmt->bindParam(':face_image_path', $this->face_image_path);
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

    public function updateFaceEncoding($face_encoding) {
        $query = "UPDATE " . $this->table_name . " SET face_encoding = ? WHERE id = ?";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $face_encoding);
        $stmt->bindParam(2, $this->id);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function getByRollNumber($roll_number) {
        $query = "SELECT id, roll_number, name, grade, class, parent_name, 
                         parent_phone, parent_email, face_encoding, face_image_path 
                  FROM " . $this->table_name . " 
                  WHERE roll_number = ? AND is_active = 1";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $roll_number);
        $stmt->execute();

        if($stmt->rowCount() > 0) {
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            $this->id = $row['id'];
            $this->roll_number = $row['roll_number'];
            $this->name = $row['name'];
            $this->grade = $row['grade'];
            $this->class = $row['class'];
            $this->parent_name = $row['parent_name'];
            $this->parent_phone = $row['parent_phone'];
            $this->parent_email = $row['parent_email'];
            $this->face_encoding = $row['face_encoding'];
            $this->face_image_path = $row['face_image_path'];
            return true;
        }
        return false;
    }

    public function getAllFaceEncodings() {
        $query = "SELECT id, roll_number, name, face_encoding 
                  FROM " . $this->table_name . " 
                  WHERE face_encoding IS NOT NULL AND is_active = 1";

        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
?>
