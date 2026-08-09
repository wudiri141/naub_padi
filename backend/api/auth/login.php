<?php
require __DIR__ . '/../_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Method not allowed', 405);
}

try {
    $data = input();
    $email = trim((string)($data['email'] ?? ''));
    $password = (string)($data['password'] ?? '');

    if ($email === '') {
        json_error('Please enter your email.');
    }

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        json_error('Invalid email format.');
    }

    if ($password === '') {
        json_error('Please enter your password.');
    }

    $stmt = db()->prepare('SELECT id, full_name, email, password_hash, faculty_code, department_name, level FROM users WHERE email = :email LIMIT 1');
    $stmt->execute(['email' => $email]);
    $user = $stmt->fetch();
    if (!$user) {
        json_error('No account found with this email.', 404);
    }

    if (!password_verify($password, (string)$user['password_hash'])) {
        json_error('Incorrect password.', 401);
    }

    unset($user['password_hash']);
    $token = jwt_encode([
        'sub' => (int) $user['id'],
        'email' => $user['email'],
        'name' => $user['full_name'],
        'iat' => time(),
        'exp' => time() + 60 * 60 * 24 * 7,
    ]);

    json_ok(['user' => $user, 'token' => $token]);
} catch (Throwable $e) {
    json_error('Unable to log in. Please try again later.', 500);
}
