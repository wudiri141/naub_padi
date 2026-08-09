<?php

declare(strict_types=1);

/*
 * Streams an uploaded question-paper file.
 *
 * The normal API bootstrap sets Content-Type to JSON. This endpoint must
 * override that header because it returns the actual binary file.
 */
require __DIR__ . '/_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    header('Allow: GET, OPTIONS');
    http_response_code(405);
    exit('Method not allowed');
}

$id = filter_input(INPUT_GET, 'id', FILTER_VALIDATE_INT);

if (!$id || $id < 1) {
    http_response_code(400);
    exit('Invalid file id');
}

$stmt = db()->prepare(
    'SELECT file_path, file_name, file_mime
     FROM question_papers
     WHERE id = :id AND is_active = 1
     LIMIT 1'
);
$stmt->execute(['id' => $id]);
$paper = $stmt->fetch();

if (!$paper || empty($paper['file_path'])) {
    http_response_code(404);
    exit('File not found');
}

$relativePath = normalize_upload_relative_path((string) $paper['file_path']);

// Files must be stored below the application uploads directory.
// Reject traversal and absolute paths to prevent arbitrary file reads.
if (
    $relativePath === '' ||
    str_contains($relativePath, '..') ||
    str_starts_with($relativePath, '/') ||
    preg_match('/^[A-Za-z]:[\\\/]/', $relativePath)
) {
    http_response_code(404);
    exit('File not found');
}

if ($relativePath === '') {
    http_response_code(404);
    exit('File not found');
}

$filePath = false;
$uploadsRoot = false;

foreach (upload_root_candidates() as $candidateRoot) {
    $candidateRootReal = realpath($candidateRoot);
    if ($candidateRootReal === false) {
        continue;
    }

    $candidatePath = realpath($candidateRootReal . DIRECTORY_SEPARATOR . $relativePath);
    if ($candidatePath === false) {
        continue;
    }

    $candidatePrefix = rtrim($candidateRootReal, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;
    if ($candidatePath !== $candidateRootReal && !str_starts_with($candidatePath, $candidatePrefix)) {
        continue;
    }

    $uploadsRoot = $candidateRootReal;
    $filePath = $candidatePath;
    break;
}

if ($uploadsRoot === false || $filePath === false) {
    http_response_code(404);
    exit('File not found');
}

if (!is_file($filePath) || !is_readable($filePath)) {
    http_response_code(404);
    exit('File not found');
}

$mime = trim((string) ($paper['file_mime'] ?? ''));
if ($mime === '' || $mime === 'application/octet-stream') {
    $detectedMime = function_exists('mime_content_type') ? mime_content_type($filePath) : false;
    if (is_string($detectedMime) && $detectedMime !== '') {
        $mime = $detectedMime;
    }
}

if ($mime === '') {
    $mime = 'application/octet-stream';
}

$fileName = trim((string) ($paper['file_name'] ?? ''));
if ($fileName === '') {
    $fileName = basename($filePath);
}

// Remove CR/LF so a database value cannot inject response headers.
$fileName = str_replace(["\r", "\n", '"'], ['', '', "'"], $fileName);

header_remove('Content-Type');
header('Content-Type: ' . $mime);
header('Content-Length: ' . (string) filesize($filePath));
header('Content-Disposition: inline; filename="' . $fileName . '"');
header('Cache-Control: public, max-age=3600');
header('X-Content-Type-Options: nosniff');

$handle = fopen($filePath, 'rb');
if ($handle === false) {
    http_response_code(404);
    exit('File not found');
}

while (!feof($handle)) {
    $chunk = fread($handle, 1024 * 1024);
    if ($chunk === false) {
        break;
    }
    echo $chunk;
    flush();
}

fclose($handle);
exit;
