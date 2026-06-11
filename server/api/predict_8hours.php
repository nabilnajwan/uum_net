<?php
header("Content-Type: application/json");
include 'db.php';

$lat = $_POST['lat'] ?? 0.0;
$lng = $_POST['long'] ?? 0.0;
$telco = $_POST['telco'] ?? 'UUM WiFi';

// 1. Get current hour
date_default_timezone_set("Asia/Kuala_Lumpur");
$currentHour = (int)date('H');

// 2. Query to find averages grouped by hour for the last 7 days within a 300m radius (0.3 km)
// Using Haversine formula for distance
$sql = "SELECT 
            HOUR(test_time) as hour, 
            AVG(signal_dbm) as avg_dbm, 
            AVG(download_speed) as avg_dl,
            COUNT(*) as data_points
        FROM test_results 
        WHERE telco_provider = '$telco' 
        AND test_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
        AND ( 6371 * acos( cos( radians($lat) ) * cos( radians( latitude ) ) * cos( radians( longitude ) - radians($lng) ) + sin( radians($lat) ) * sin( radians( latitude ) ) ) ) < 0.3
        GROUP BY HOUR(test_time)";

$result = $conn->query($sql);

// Store historical data in an array
$historicalData = [];
if ($result && $result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $historicalData[$row['hour']] = $row;
    }
}

// 3. Generate the next 8 hours prediction
$predictions = [];
for ($i = 1; $i <= 8; $i++) {
    $targetHour = ($currentHour + $i) % 24;
    
    // Format hour for display (e.g., 14 -> 2:00 PM)
    $displayTime = date("g:00 A", strtotime("$targetHour:00"));

    if (isset($historicalData[$targetHour])) {
        // We have historical data for this hour!
        $predictions[] = [
            "time" => $displayTime,
            "expected_dl" => round($historicalData[$targetHour]['avg_dl'], 1),
            "expected_dbm" => round($historicalData[$targetHour]['avg_dbm']),
            "confidence" => "High (" . $historicalData[$targetHour]['data_points'] . " past records)"
        ];
    } else {
        // No exact data for this hour in the last 7 days. 
        // We predict based on overall average or mark as unknown
        $predictions[] = [
            "time" => $displayTime,
            "expected_dl" => "Unknown",
            "expected_dbm" => "Unknown",
            "confidence" => "Need more data"
        ];
    }
}

echo json_encode([
    "status" => "success",
    "predictions" => $predictions
]);
?>