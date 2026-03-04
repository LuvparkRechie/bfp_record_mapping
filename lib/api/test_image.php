<?php
$file = 'uploads/signatures/insp_signature_rechiearnado.png';
$file_path = __DIR__ . '/' . $file;

if (file_exists($file_path)) {
    header('Content-Type: image/png');
    header('Content-Length: ' . filesize($file_path));
    readfile($file_path);
} else {
    echo "File not found: $file_path";
}
?>