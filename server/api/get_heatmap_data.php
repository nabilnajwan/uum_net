<?php
include_once("db.php");

// 1. Default to UUM WiFi, "All" option is removed
$telco = $_GET['telco'] ?? 'UUM WiFi';
$safe_telco = $conn->real_escape_string($telco);

// 2. Group by location and proximity (rounding to 4 decimals groups points within ~11 meters)
// This gives us the average stats and the total response count for that spot.
$sql = "SELECT 
            location_name,
            ROUND(latitude, 4) as cluster_lat,
            ROUND(longitude, 4) as cluster_lng,
            AVG(latitude) as lat, 
            AVG(longitude) as lng, 
            AVG(signal_dbm) as avg_dbm, 
            AVG(download_speed) as avg_dl, 
            AVG(upload_speed) as avg_ul, 
            AVG(ping_ms) as avg_ping,
            COUNT(*) as response_count
        FROM test_results 
        WHERE telco_provider = '$safe_telco'
        GROUP BY location_name, cluster_lat, cluster_lng";

$result = $conn->query($sql);
$response = array();

if ($result && $result->num_rows > 0) {
    $points = array();
    while ($row = $result->fetch_assoc()) {
        $point = array();
        $point['location_name']  = $row['location_name'];
        $point['lat']            = floatval($row['lat']);
        $point['lng']            = floatval($row['lng']);
        $point['dbm']            = intval($row['avg_dbm']);
        $point['dl']             = floatval($row['avg_dl']);
        $point['ul']             = floatval($row['avg_ul']);
        $point['ping']           = intval($row['avg_ping']);
        $point['response_count'] = intval($row['response_count']);
        
        array_push($points, $point);
    }
    $response['status'] = 'success';
    $response['data'] = $points;
} else {
    $response['status'] = 'no_data';
    $response['data'] = [];
}

echo json_encode($response);
?>