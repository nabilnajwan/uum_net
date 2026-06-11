<?php
header("Content-Type: application/json");
include 'db.php';

$matric = $_POST['matric'];
$username = $_POST['username'];
$bio = $_POST['bio'];
$imageBase64 = isset($_POST['image']) ? $_POST['image'] : '';

$updateSql = "UPDATE users SET username='$username', bio='$bio'";
$dbFilePath = null;

if (!empty($imageBase64)) {
    // Decode the base64 string
    $imgData = base64_decode($imageBase64);
    
    // Generate a unique filename
    $fileName = "profile_" . $matric . "_" . time() . ".jpg";
    
    // Path where the file will be saved (assuming uploads is outside the api folder)
    $filePath = "../uploads/" . $fileName; 
    
    // Save file
    if(file_put_contents($filePath, $imgData)) {
        $dbFilePath = "uploads/" . $fileName; 
        $updateSql .= ", profile_pic='$dbFilePath'";
    }
}

$updateSql .= " WHERE matric_no='$matric'";

if ($conn->query($updateSql) === TRUE) {
    $response = ["status" => "success"];
    if ($dbFilePath) {
        $response["profile_pic"] = $dbFilePath;
    }
    echo json_encode($response);
} else {
    echo json_encode(["status" => "fail", "message" => "Database Error: " . $conn->error]);
}
?>