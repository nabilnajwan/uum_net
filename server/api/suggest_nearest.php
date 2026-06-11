<?php
header("Content-Type: application/json");
include 'db.php';

$lat = $_POST['lat'] ?? 0.0;
$lng = $_POST['long'] ?? 0.0;
$telco = $_POST['telco'] ?? 'UUM WiFi';

// Find the closest location with an EXCELLENT connection across all 4 metrics within a 3km radius
// ADDED: AND test_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) to only get recent data
$sql = "SELECT 
            location_name, 
            download_speed, 
            signal_dbm,
            ( 6371 * acos( cos( radians($lat) ) * cos( radians( latitude ) ) * cos( radians( longitude ) - radians($lng) ) + sin( radians($lat) ) * sin( radians( latitude ) ) ) ) AS distance 
        FROM test_results 
        WHERE telco_provider = '$telco' 
        AND download_speed >= 6    -- 1. Good Download Speed
        AND upload_speed >= 5       -- 2. Good Upload Speed
        AND ping_ms <= 180           -- 3. Low Ping (Fast Response)
        AND signal_dbm >= -100       -- 4. Strong Signal (Closer to 0 is better)
        AND test_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) 
        HAVING distance > 0.05 AND distance < 3 
        ORDER BY distance ASC 
        LIMIT 1";

$result = $conn->query($sql);

if ($result && $result->num_rows > 0) {
    $row = $result->fetch_assoc();
    echo json_encode([
        "status" => "success",
        "found" => true,
        "location" => $row['location_name'],
        "distance_km" => round($row['distance'], 2),
        "speed" => round($row['download_speed'], 1)
    ]);
} else {
    echo json_encode([
        "status" => "success", 
        "found" => false,
        "message" => "No better locations found nearby."
    ]);
}
?>