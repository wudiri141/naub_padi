<?php

declare(strict_types=1);

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

const DB_HOST = 'localhost';
const DB_NAME = 'vtutopup_naubpadi';
const DB_USER = 'vtutopup_naubpadi';
const DB_PASS = 'Adamusani141@121';
const JWT_SECRET = 'naub-padi-change-this-secret-in-production';

function db(): PDO
{
    static $pdo = null;
    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $dsn = sprintf('mysql:host=%s;dbname=%s;charset=utf8mb4', DB_HOST, DB_NAME);
    $pdo = new PDO($dsn, DB_USER, DB_PASS, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);

    return $pdo;
}

function json_ok(array $data = [], int $status = 200): void
{
    http_response_code($status);
    echo json_encode(['success' => true] + $data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function json_error(string $message, int $status = 400, array $extra = []): void
{
    http_response_code($status);
    echo json_encode(['success' => false, 'message' => $message] + $extra, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function input(): array
{
    $raw = file_get_contents('php://input');
    if ($raw === false || $raw === '') {
        return $_POST;
    }

    $decoded = json_decode($raw, true);
    if (is_array($decoded)) {
        return $decoded;
    }

    return $_POST;
}

function slugify(string $value): string
{
    $value = strtolower(trim($value));
    $value = preg_replace('/[^a-z0-9]+/', '-', $value) ?? $value;
    return trim($value, '-');
}

function base64url_encode(string $input): string
{
    return rtrim(strtr(base64_encode($input), '+/', '-_'), '=');
}

function jwt_encode(array $payload): string
{
    $header = ['typ' => 'JWT', 'alg' => 'HS256'];
    $segments = [
        base64url_encode(json_encode($header, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)),
        base64url_encode(json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)),
    ];
    $signature = hash_hmac('sha256', implode('.', $segments), JWT_SECRET, true);
    $segments[] = base64url_encode($signature);
    return implode('.', $segments);
}

function upload_root_candidates(): array
{
    $parentDir = basename(dirname(__DIR__));

    if ($parentDir === 'backend') {
        return [
            __DIR__ . '/../../uploads',
            __DIR__ . '/../uploads',
        ];
    }

    return [
        __DIR__ . '/../uploads',
        __DIR__ . '/../../uploads',
    ];
}

function normalize_upload_relative_path(string $path): string
{
    $path = ltrim(str_replace('\\', '/', trim($path)), '/');
    if ($path === '') {
        return '';
    }

    if (str_starts_with($path, 'uploads/')) {
        return substr($path, strlen('uploads/'));
    }

    return $path;
}
