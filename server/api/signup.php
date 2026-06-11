<?php
header("Content-Type: application/json");
include 'db.php';

// 1. Receive Data from App
$username = $_POST['username'];
$email = $_POST['email'];
$matric = $_POST['matric'];
$password = $_POST['password'];

// 2. Check if Matric already exists
$checkSql = "SELECT * FROM users WHERE matric_no='$matric'";
$checkResult = $conn->query($checkSql);

if ($checkResult->num_rows > 0) {
    echo json_encode(["status" => "fail", "message" => "Matric number already registered"]);
} else {
    // 3. Hash Password (Security)
    $hashed_pass = password_hash($password, PASSWORD_DEFAULT);
    
    // 4. Insert New User
    $sql = "INSERT INTO users (username, email, matric_no, password) VALUES ('$username', '$email', '$matric', '$hashed_pass')";
    
    if ($conn->query($sql) === TRUE) {
        echo json_encode(["status" => "success"]);
    } else {
        echo json_encode(["status" => "fail", "message" => "Database Error: " . $conn->error]);
    }
}
?>