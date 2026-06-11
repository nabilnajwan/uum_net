<?php
header("Content-Type: application/json");
include 'db.php';

$matric = $_POST['matric'] ?? '';

if (empty($matric)) {
    echo json_encode(["status" => "fail", "message" => "Matric required"]);
    exit();
}

// Logic: Group by activity and hour to find where/when the user gets the best results
$sql = "SELECT 
            activity_type, 
            location_name,
            HOUR(test_time) as best_hour, 
            AVG(download_speed) as avg_speed
        FROM test_results 
        WHERE matric_no = '$matric' AND location_name != 'Unknown Area'
        GROUP BY activity_type, location_name, HOUR(test_time)
        ORDER BY avg_speed DESC 
        LIMIT 5";

$result = $conn->query($sql);
$patterns = [];

while($row = $result->fetch_assoc()) {
    // Format hour for display
    $h = $row['best_hour'];
    $displayTime = date("g:00 A", strtotime("$h:00"));
    $row['display_time'] = $displayTime;
    $patterns[] = $row;
}

echo json_encode(["status" => "success", "data" => $patterns]);
?>