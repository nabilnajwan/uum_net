<?php
include 'db.php';

// Fetch all results, newest first
$sql = "SELECT * FROM test_results ORDER BY id DESC";
$result = $conn->query($sql);

$response = array();

if ($result->num_rows > 0) {
    $data = array();
    while ($row = $result->fetch_assoc()) {
        array_push($data, $row);
    }
    $response['status'] = 'success';
    $response['data'] = $data;
} else {
    $response['status'] = 'no_data';
}

echo json_encode($response);
?>