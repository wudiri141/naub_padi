<?php
require __DIR__ . '/_bootstrap.php';

$userId = isset($_GET['user_id']) ? (int) $_GET['user_id'] : 0;

$sql = 'SELECT id, user_id, title, body, type, is_read, created_at FROM notifications';
$params = [];
if ($userId > 0) {
    $sql .= ' WHERE user_id IS NULL OR user_id = :user_id';
    $params['user_id'] = $userId;
}
$sql .= ' ORDER BY created_at DESC LIMIT 100';

$stmt = db()->prepare($sql);
$stmt->execute($params);
json_ok(['notifications' => $stmt->fetchAll()]);
