<?php
require __DIR__ . '/../_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Method not allowed', 405);
}

$data = input();
$fullName = trim((string)($data['full_name'] ?? ''));
$email = trim((string)($data['email'] ?? ''));
$password = (string)($data['password'] ?? '');
$faculty = trim((string)($data['faculty_code'] ?? ''));
$department = trim((string)($data['department_name'] ?? ''));
$level = trim((string)($data['level'] ?? ''));

if ($fullName === '' || $email === '' || $password === '') {
    json_error('Full name, email, and password are required.');
}

$hash = password_hash($password, PASSWORD_DEFAULT);
$stmt = db()->prepare('INSERT INTO users (full_name, email, password_hash, faculty_code, department_name, level) VALUES (:full_name, :email, :password_hash, :faculty_code, :department_name, :level)');
try {
    $stmt->execute([
        'full_name' => $fullName,
        'email' => $email,
        'password_hash' => $hash,
        'faculty_code' => $faculty !== '' ? $faculty : null,
        'department_name' => $department !== '' ? $department : null,
        'level' => $level !== '' ? $level : null,
    ]);
} catch (Throwable $e) {
    json_error('Unable to create account. Email may already exist.', 409);
}

$userId = (int) db()->lastInsertId();
json_ok([
    'user_id' => $userId,
    'message' => 'Registration successful. Please log in to continue.',
], 201);
