<?php
require_once __DIR__ . '/../config/database.php';

class Admin {
    private $conn;
    private $table_name = "admin_users";

    public $id;
    public $username;
    public $password;
    public $email;
    public $full_name;
    public $is_active;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function login($username, $password) {
        $query = "SELECT id, username, password, email, full_name 
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
