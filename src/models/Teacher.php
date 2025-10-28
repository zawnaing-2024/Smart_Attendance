<?php
require_once __DIR__ . '/../config/database.php';

class Teacher {
    private $conn;
    private $table_name = "teachers";

    public $id;
    public $username;
    public $password;
    public $email;
    public $position;
    public $full_name;
    public $phone;
    public $grade_id;
    public $is_active;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create() {
        $query = "INSERT INTO " . $this->table_name . " 
                  SET username=:username, password=:password, email=:email, 
                      position=:position, full_name=:full_name, phone=:phone, grade_id=:grade_id";

        $stmt = $this->conn->prepare($query);

        $this->username = Utils::sanitize($this->username);
        $this->email = Utils::sanitize($this->email);
        $this->position = Utils::sanitize($this->position);
        $this->full_name = Utils::sanitize($this->full_name);
        $this->phone = Utils::sanitize($this->phone);
        $this->password = Utils::hashPassword($this->password);

        $stmt->bindParam(":username", $this->username);
        $stmt->bindParam(":password", $this->password);
        $stmt->bindParam(":email", $this->email);
        $stmt->bindParam(":position", $this->position);
        $stmt->bindParam(":full_name", $this->full_name);
        $stmt->bindParam(":phone", $this->phone);
        $stmt->bindParam(":grade_id", $this->grade_id);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function read() {
        $query = "SELECT t.id, t.username, t.email, t.position, t.full_name, t.phone, 
                         t.created_at, t.is_active, t.grade_id, g.name as grade_name
                  FROM " . $this->table_name . " t
                  LEFT JOIN grades g ON t.grade_id = g.id
                  ORDER BY t.created_at DESC";

        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }

    public function readOne() {
        $query = "SELECT id, username, email, position, full_name, phone, 
                         created_at, is_active 
                  FROM " . $this->table_name . " 
                  WHERE id = ? LIMIT 0,1";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->id);
        $stmt->execute();

        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if($row) {
            $this->username = $row['username'];
            $this->email = $row['email'];
            $this->position = $row['position'];
            $this->full_name = $row['full_name'];
            $this->phone = $row['phone'];
            $this->is_active = $row['is_active'];
            return true;
        }
        return false;
    }

    public function update() {
        $query = "UPDATE " . $this->table_name . " 
                  SET username=:username, email=:email, position=:position, 
                      full_name=:full_name, phone=:phone, grade_id=:grade_id, is_active=:is_active 
                  WHERE id=:id";

        $stmt = $this->conn->prepare($query);

        $this->username = Utils::sanitize($this->username);
        $this->email = Utils::sanitize($this->email);
        $this->position = Utils::sanitize($this->position);
        $this->full_name = Utils::sanitize($this->full_name);
        $this->phone = Utils::sanitize($this->phone);

        $stmt->bindParam(':username', $this->username);
        $stmt->bindParam(':email', $this->email);
        $stmt->bindParam(':position', $this->position);
        $stmt->bindParam(':full_name', $this->full_name);
        $stmt->bindParam(':phone', $this->phone);
        $stmt->bindParam(':grade_id', $this->grade_id);
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

    public function login($username, $password) {
        $query = "SELECT id, username, password, email, position, full_name 
                  FROM " . $this->table_name . " 
                  WHERE username = ? AND is_active = 1";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $username);
        $stmt->execute();

        if($stmt->rowCount() > 0) {
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            if(Utils::verifyPassword($password, $row['password'])) {
                $this->id = $row['id'];
                $this->username = $row['username'];
                $this->email = $row['email'];
                $this->position = $row['position'];
                $this->full_name = $row['full_name'];
                return true;
            }
        }
        return false;
    }

    public function changePassword($new_password) {
        $query = "UPDATE " . $this->table_name . " SET password = ? WHERE id = ?";
        $stmt = $this->conn->prepare($query);
        $hashed_password = Utils::hashPassword($new_password);
        $stmt->bindParam(1, $hashed_password);
        $stmt->bindParam(2, $this->id);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }
}
?>
