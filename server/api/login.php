<?php
header("Content-Type: application/json");
include 'db.php';

$matric = $_POST['matric'];
$password = $_POST['password'];

$sql = "SELECT * FROM users WHERE matric_no='$matric'";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    if (password_verify($password, $row['password'])) {
        echo json_encode([
            "status" => "success", 
            "username" => $row['username'],
            "matric" => $row['matric_no'],
            "bio" => $row['bio'],          
            "profile_pic" => $row['profile_pic'] 
        ]);
    } else {
        echo json_encode(["status" => "fail", "message" => "Wrong password"]);
    }
} else {
    echo json_encode(["status" => "fail", "message" => "User not found"]);
}
?>