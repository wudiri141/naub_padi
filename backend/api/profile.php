<?php
require __DIR__ . '/_bootstrap.php';
require __DIR__ . '/_structure.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $email = trim((string)($_GET['email'] ?? ''));
    $userId = isset($_GET['user_id']) ? (int) $_GET['user_id'] : null;

    if ($email === '' && !$userId) {
        json_error('Email or user_id is required.', 400);
    }

    if ($email !== '') {
        $stmt = db()->prepare('SELECT id, full_name, email, faculty_code, department_name, level, created_at, updated_at FROM users WHERE email = :email LIMIT 1');
        $stmt->execute(['email' => $email]);
    } else {
        $stmt = db()->prepare('SELECT id, full_name, email, faculty_code, department_name, level, created_at, updated_at FROM users WHERE id = :id LIMIT 1');
        $stmt->execute(['id' => $userId]);
    }

    $user = $stmt->fetch();
    if (!$user) {
        json_error('Profile not found', 404);
    }

    json_ok(['profile' => $user]);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' || $_SERVER['REQUEST_METHOD'] === 'PUT') {
    try {
        $data = input();
        $userId = isset($data['user_id']) ? (int) $data['user_id'] : 0;
        if ($userId <= 0) {
            json_error('Unable to save changes. Please sign in again.', 400);
        }

        $fields = [
            'full_name' => trim((string)($data['full_name'] ?? '')),
            'faculty_code' => trim((string)($data['faculty_code'] ?? '')),
            'department_name' => trim((string)($data['department_name'] ?? '')),
            'level' => trim((string)($data['level'] ?? '')),
        ];

        $facultyCode = $fields['faculty_code'];
        $departmentName = $fields['department_name'];
        if ($facultyCode !== '') {
            $departmentOptions = naub_departments_for($facultyCode);
            if ($departmentOptions === [] && !in_array($facultyCode, naub_faculty_codes(), true)) {
                json_error('Invalid faculty selection.', 400);
            }

            if ($departmentName !== '' && !in_array($departmentName, $departmentOptions, true)) {
                json_error('Invalid department selection.', 400);
            }
        }

        $check = db()->prepare('SELECT id FROM users WHERE id = :id LIMIT 1');
        $check->execute(['id' => $userId]);
        if (!$check->fetch()) {
            json_error('No profile found for this account.', 404);
        }

        $stmt = db()->prepare('UPDATE users SET full_name = :full_name, faculty_code = :faculty_code, department_name = :department_name, level = :level WHERE id = :id');
        $stmt->execute([
            'id' => $userId,
            'full_name' => $fields['full_name'],
            'faculty_code' => $fields['faculty_code'] !== '' ? $fields['faculty_code'] : null,
            'department_name' => $fields['department_name'] !== '' ? $fields['department_name'] : null,
            'level' => $fields['level'] !== '' ? $fields['level'] : null,
        ]);

        json_ok(['updated' => true, 'message' => 'Profile updated successfully.']);
    } catch (Throwable $e) {
        json_error('Unable to save changes. Please try again later.', 500);
    }
}

json_error('Method not allowed', 405);
