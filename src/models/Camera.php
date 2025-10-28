<?php
require_once __DIR__ . '/../config/database.php';

class Camera {
    private $conn;
    private $table_name = "cameras";

    public $id;
    public $name;
    public $rtsp_url;
    public $username;
    public $password;
    public $location;
    public $is_active;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create() {
        $query = "INSERT INTO " . $this->table_name . " 
                  SET name=:name, rtsp_url=:rtsp_url, username=:username, 
                      password=:password, location=:location";

        $stmt = $this->conn->prepare($query);

        $this->name = Utils::sanitize($this->name);
        $this->rtsp_url = Utils::sanitize($this->rtsp_url);
        $this->username = Utils::sanitize($this->username);
        $this->password = Utils::sanitize($this->password);
        $this->location = Utils::sanitize($this->location);

        $stmt->bindParam(":name", $this->name);
        $stmt->bindParam(":rtsp_url", $this->rtsp_url);
        $stmt->bindParam(":username", $this->username);
        $stmt->bindParam(":password", $this->password);
        $stmt->bindParam(":location", $this->location);

        if($stmt->execute()) {
            return true;
        }
        return false;
    }

    public function read() {
        $query = "SELECT id, name, rtsp_url, username, location, is_active, created_at 
                  FROM " . $this->table_name . " 
                  ORDER BY created_at DESC";

        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt;
    }

    public function readOne() {
        $query = "SELECT id, name, rtsp_url, username, password, location, is_active 
                  FROM " . $this->table_name . " 
                  WHERE id = ? LIMIT 0,1";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->id);
        $stmt->execute();

        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if($row) {
            $this->name = $row['name'];
            $this->rtsp_url = $row['rtsp_url'];
            $this->username = $row['username'];
            $this->password = $row['password'];
            $this->location = $row['location'];
            $this->is_active = $row['is_active'];
            return true;
        }
        return false;
    }

    public function update() {
        $query = "UPDATE " . $this->table_name . " 
                  SET name=:name, rtsp_url=:rtsp_url, username=:username, 
                      password=:password, location=:location, is_active=:is_active 
                  WHERE id=:id";

        $stmt = $this->conn->prepare($query);

        $this->name = Utils::sanitize($this->name);
        $this->rtsp_url = Utils::sanitize($this->rtsp_url);
        $this->username = Utils::sanitize($this->username);
        $this->password = Utils::sanitize($this->password);
        $this->location = Utils::sanitize($this->location);

        $stmt->bindParam(':name', $this->name);
        $stmt->bindParam(':rtsp_url', $this->rtsp_url);
        $stmt->bindParam(':username', $this->username);
        $stmt->bindParam(':password', $this->password);
        $stmt->bindParam(':location', $this->location);
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

    public function getActiveCameras() {
        $query = "SELECT id, name, rtsp_url, username, password, location 
                  FROM " . $this->table_name . " 
                  WHERE is_active = 1";

        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
?>
