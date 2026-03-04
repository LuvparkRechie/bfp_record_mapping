<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    echo json_encode(['ok' => true]);
    exit;
}

require_once __DIR__ . '/db_conn.php';

// Configuration
define('SIGNATURE_UPLOAD_PATH', __DIR__ . '/uploads/signatures/');

try {
    // Get input data (supports both POST and DELETE methods)
    $input = [];
    
    if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
        // For DELETE method, read from php://input
        $raw = file_get_contents('php://input');
        if ($raw) {
            $input = json_decode($raw, true) ?? [];
        }
    } else {
        // For POST method, check POST data and then php://input
        $raw = file_get_contents('php://input');
        $json_data = json_decode($raw, true) ?? [];
        
        $input = array_merge($_POST, $json_data);
    }

    // Get parameters
    $file_path = $input['file_path'] ?? null;
    $file_name = $input['file_name'] ?? null;
    $user_id = $input['user_id'] ?? null;

    // Validate input
    if (!$file_path && !$file_name) {
        throw new Exception('Either file_path or file_name is required');
    }

    // Determine filename to delete
    $filename_to_delete = null;
    
    if ($file_path) {
        // Extract filename from full path
        $filename_to_delete = basename($file_path);
    } else if ($file_name) {
        $filename_to_delete = basename($file_name);
    }

    if (!$filename_to_delete) {
        throw new Exception('Invalid filename');
    }

    // Full path to the file
    $full_file_path = SIGNATURE_UPLOAD_PATH . $filename_to_delete;

    // Check if file exists
    if (!file_exists($full_file_path)) {
        echo json_encode([
            'success' => false,
            'message' => 'File not found: ' . $filename_to_delete
        ]);
        exit;
    }

    // Delete the file
    if (!unlink($full_file_path)) {
        throw new Exception('Failed to delete file');
    }

    // If user_id is provided, update database to remove signature_path
    if ($user_id) {
        try {
            // First check which table has user_id (users or inspection_reports)
            // Try users table first
            $checkUserStmt = $conn->prepare("SHOW TABLES LIKE 'users'");
            $checkUserStmt->execute();
            
            if ($checkUserStmt->rowCount() > 0) {
                $updateStmt = $conn->prepare("
                    UPDATE users 
                    SET signature_path = NULL,
                        updated_at = NOW()
                    WHERE id = ?
                ");
                $updateStmt->execute([$user_id]);
            } else {
                // Try inspection_reports table
                $updateStmt = $conn->prepare("
                    UPDATE inspection_reports 
                    SET owner_signature_path = NULL,
                        updated_at = NOW()
                    WHERE inspection_id = ?
                ");
                $updateStmt->execute([$user_id]);
            }
        } catch (PDOException $e) {
            // Log error but don't fail the response
            error_log('Failed to update database: ' . $e->getMessage());
        }
    }

    echo json_encode([
        'success' => true,
        'message' => 'Signature deleted successfully',
        'file_name' => $filename_to_delete,
        'file_path' => '/uploads/signatures/' . $filename_to_delete,
        'user_id' => $user_id
    ]);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>