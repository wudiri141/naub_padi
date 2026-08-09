<?php
require __DIR__ . '/_bootstrap.php';

$sql = 'SELECT p.id, p.title, p.faculty_code, p.department_name, p.level, p.exam_type, p.session_label, p.course_code, p.file_path, p.file_name, p.created_at
        FROM question_papers p
        WHERE p.is_active = 1';
$params = [];

foreach (['faculty' => 'faculty_code', 'department' => 'department_name', 'level' => 'level', 'type' => 'exam_type', 'session' => 'session_label', 'course_code' => 'course_code'] as $queryKey => $column) {
    if (!empty($_GET[$queryKey])) {
        $sql .= " AND p.$column = :$queryKey";
        $params[$queryKey] = $_GET[$queryKey];
    }
}

$sql .= ' ORDER BY p.created_at DESC LIMIT 200';
$stmt = db()->prepare($sql);
$stmt->execute($params);

json_ok(['papers' => $stmt->fetchAll()]);
