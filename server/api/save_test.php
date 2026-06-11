<?php
include 'db.php';

if ($_SERVER["REQUEST_METHOD"] == "POST") {

    // 1. Get Data
    $matric   = $_POST['matric']   ?? "Unknown";
    $telco    = $_POST['telco']    ?? "Unknown";
    $lat      = $_POST['lat']      ?? "0.0";
    $long     = $_POST['long']     ?? "0.0";
    $netType  = $_POST['netType']  ?? "Unknown";
    $ping     = $_POST['ping']     ?? "0";
    $dl       = $_POST['dl']       ?? "0.0";
    $ul       = $_POST['ul']       ?? "0.0";
    $dbm      = $_POST['dbm']      ?? "0";
    $locName  = $_POST['locName']  ?? "Unknown Area";
    // Ensure this matches the key sent from your Flutter app
    $activity = $_POST['activity'] ?? "General"; 

    date_default_timezone_set("Asia/Kuala_Lumpur");
    $date = date("Y-m-d");
    $time = date("H:i:s");

    // 2. Prepare Insert 
    // ADDED 'activity_type' to the column list and an extra '?' placeholder
    $stmt = $conn->prepare("INSERT INTO test_results (matric_no, latitude, longitude, network_type, telco_provider, ping_ms, download_speed, upload_speed, signal_dbm, location_name, activity_type, test_date, test_time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
    
    if ($stmt) {
        // 3. Bind Parameters 
        // Updated to 13 's' characters to account for the new $activity variable
        $stmt->bind_param("sssssssssssss", $matric, $lat, $long, $netType, $telco, $ping, $dl, $ul, $dbm, $locName, $activity, $date, $time);

        if ($stmt->execute()) {
            echo json_encode(["status" => "success"]);
        } else {
            echo json_encode(["status" => "error", "message" => $stmt->error]);
        }
        $stmt->close();
    } else {
        echo json_encode(["status" => "error", "message" => "Prepare failed: " . $conn->error]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Invalid Request"]);
}

$conn->close();
?>