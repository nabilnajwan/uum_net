<?php
header("Content-Type: application/json");
include 'db.php';

$location = $_POST['location'] ?? '';
$telco = $_POST['telco'] ?? '';

if (empty($location)) {
    echo json_encode(["status" => "fail", "message" => "Location required"]);
    exit();
}

// Get the average stats grouped by hour for the last 30 days
$sql = "SELECT 
            HOUR(test_time) as hour, 
            AVG(download_speed) as avg_dl,
            AVG(upload_speed) as avg_ul,
            AVG(ping_ms) as avg_ping,
            AVG(signal_dbm) as avg_dbm
        FROM test_results 
        WHERE location_name = '$location' AND telco_provider = '$telco'
        AND test_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        GROUP BY HOUR(test_time)
        ORDER BY hour ASC";

$result = $conn->query($sql);
$data = [];

while($row = $result->fetch_assoc()) {
    $data[] = [
        "hour" => (int)$row['hour'],
        "dl" => (float)$row['avg_dl'],
        "ul" => (float)$row['avg_ul'],
        "ping" => (float)$row['avg_ping'],
        "dbm" => (float)$row['avg_dbm']
    ];
}

echo json_encode(["status" => "success", "data" => $data]);
?>