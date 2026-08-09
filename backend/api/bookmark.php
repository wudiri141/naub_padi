<?php
require __DIR__ . '/_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $userId = isset($_GET['user_id']) ? (int) $_GET['user_id'] : 0;
    if ($userId <= 0) {
        json_error('user_id is required.', 400);
    }

    $stmt = db()->prepare(
        'SELECT p.*
         FROM saved_papers s
         INNER JOIN question_papers p ON p.id = s.paper_id
         WHERE s.user_id = :user_id
         ORDER BY s.created_at DESC'
    );
    $stmt->execute(['user_id' => $userId]);
    json_ok(['papers' => $stmt->fetchAll()]);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = input();
    $userId = isset($data['user_id']) ? (int) $data['user_id'] : 0;
    $paperId = isset($data['paper_id']) ? (int) $data['paper_id'] : 0;
    $action = strtolower(trim((string)($data['action'] ?? 'toggle')));

    if ($userId <= 0 || $paperId <= 0) {
        json_error('user_id and paper_id are required.', 400);
    }

    if ($action === 'remove') {
        $stmt = db()->prepare('DELETE FROM saved_papers WHERE user_id = :user_id AND paper_id = :paper_id');
        $stmt->execute(['user_id' => $userId, 'paper_id' => $paperId]);
        json_ok(['saved' => false]);
    }

    $stmt = db()->prepare('INSERT IGNORE INTO saved_papers (user_id, paper_id) VALUES (:user_id, :paper_id)');
    $stmt->execute(['user_id' => $userId, 'paper_id' => $paperId]);
    json_ok(['saved' => true]);
}

json_error('Method not allowed', 405);
