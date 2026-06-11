<?php
$servername = "localhost";
$username = "nnjwarqk_admin";
$password = "TI*KT%&5*.1@";
$dbname = "nnjwarqk_uumnet";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>
