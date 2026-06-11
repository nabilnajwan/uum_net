<?php
// We just need to accept the incoming data stream to measure speed.
// We don't save the dummy file to save disk space.
file_get_contents('php://input');
echo "OK";
?>