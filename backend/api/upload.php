<?php
@ini_set('upload_max_filesize', '50M');
@ini_set('post_max_size', '60M');
@ini_set('memory_limit', '256M');
@ini_set('max_execution_time', '300');
@ini_set('max_input_time', '300');

require __DIR__ . '/_bootstrap.php';
require __DIR__ . '/_structure.php';

const MAX_UPLOAD_BYTES = 52428800;
const MAX_POST_BYTES = 62914560;

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('Method not allowed', 405);
}

$contentLength = isset($_SERVER['CONTENT_LENGTH']) ? (int) $_SERVER['CONTENT_LENGTH'] : 0;
if ($contentLength > MAX_POST_BYTES) {
    json_error('File too large. Upload files up to 50 MB.', 413);
}

$data = input();
$faculty = trim((string)($data['faculty_code'] ?? $data['faculty'] ?? ''));
$department = trim((string)($data['department_name'] ?? $data['department'] ?? ''));
$level = trim((string)($data['level'] ?? ''));
$type = trim((string)($data['exam_type'] ?? $data['type'] ?? ''));
$session = trim((string)($data['session_label'] ?? $data['session'] ?? ''));
$courseCode = trim((string)($data['course_code'] ?? ''));
$courseTitle = trim((string)($data['course_title'] ?? ''));
$paperTitle = trim((string)($data['title'] ?? ''));
$userId = isset($data['user_id']) ? (int) $data['user_id'] : null;

if ($faculty === '' || $department === '' || $level === '' || $type === '' || $session === '') {
    json_error('Faculty, department, level, type, and session are required.');
}

$facultyDepartments = naub_departments_for($faculty);
if ($facultyDepartments === [] && !in_array($faculty, naub_faculty_codes(), true)) {
    json_error('Invalid faculty selection.', 400);
}
if (!in_array($department, $facultyDepartments, true)) {
    json_error('Invalid department selection.', 400);
}

$targetDir = null;
foreach (upload_root_candidates() as $candidateDir) {
    if (is_dir($candidateDir) || @mkdir($candidateDir, 0775, true)) {
        $targetDir = $candidateDir;
        break;
    }
}
if ($targetDir === null) {
    json_error('Unable to create the uploads directory.', 500);
}

$files = [];
if (!empty($_FILES['files'])) {
    $incoming = $_FILES['files'];
    if (is_array($incoming['name'])) {
        $count = count($incoming['name']);
        for ($i = 0; $i < $count; $i++) {
            $files[] = [
                'name' => $incoming['name'][$i] ?? '',
                'type' => $incoming['type'][$i] ?? '',
                'tmp_name' => $incoming['tmp_name'][$i] ?? '',
                'error' => $incoming['error'][$i] ?? UPLOAD_ERR_NO_FILE,
                'size' => $incoming['size'][$i] ?? 0,
            ];
        }
    }
} elseif (!empty($_FILES['file'])) {
    $files[] = $_FILES['file'];
}

if ($files === []) {
    $files[] = [
        'name' => $courseCode !== '' ? ($courseCode . '.pdf') : 'question-paper.pdf',
        'type' => 'application/pdf',
        'tmp_name' => null,
        'error' => UPLOAD_ERR_NO_FILE,
        'size' => 0,
    ];
}

$inserted = [];
$db = db();
$courseLookupTitle = $courseTitle !== '' ? $courseTitle : ($courseCode !== '' ? $courseCode : $paperTitle);
$courseLookupCode = $courseCode !== '' ? $courseCode : null;
$courseSelect = $db->prepare(
    'SELECT id
     FROM courses
     WHERE faculty_code = :faculty_code
       AND department_name = :department_name
       AND level = :level
       AND (
            (course_code IS NOT NULL AND course_code = :course_code)
            OR (course_code IS NULL AND course_title = :course_title)
       )
     LIMIT 1'
);
$courseInsert = $db->prepare(
    'INSERT INTO courses (faculty_code, department_name, course_code, course_title, level, semester_label, sort_order)
     VALUES (:faculty_code, :department_name, :course_code, :course_title, :level, NULL, 0)'
);
$courseUpdate = $db->prepare(
    "UPDATE courses
     SET course_code = COALESCE(NULLIF(:course_code, ''), course_code),
         course_title = :course_title,
         level = :level
     WHERE id = :id"
);
$paperStmt = $db->prepare(
    'INSERT INTO question_papers
        (title, faculty_code, department_name, level, exam_type, session_label, course_code, file_path, file_name, file_mime, file_size, uploaded_by)
     VALUES
        (:title, :faculty_code, :department_name, :level, :exam_type, :session_label, :course_code, :file_path, :file_name, :file_mime, :file_size, :uploaded_by)'
);
$uploadStmt = $db->prepare(
    'INSERT INTO uploads
        (user_id, faculty_code, department_name, course_code, course_title, level, exam_type, session_label, status)
     VALUES
        (:user_id, :faculty_code, :department_name, :course_code, :course_title, :level, :exam_type, :session_label, :status)'
);

foreach ($files as $file) {
    $fileName = null;
    $fileMime = null;
    $fileSize = null;
    $uploadPath = null;

    if ($courseLookupTitle !== '') {
        $courseSelect->execute([
            'faculty_code' => $faculty,
            'department_name' => $department,
            'level' => $level,
            'course_code' => $courseLookupCode ?? '',
            'course_title' => $courseLookupTitle,
        ]);
        $course = $courseSelect->fetch();

        if ($course) {
            $courseUpdate->execute([
                'id' => (int) $course['id'],
                'course_code' => $courseLookupCode ?? '',
                'course_title' => $courseLookupTitle,
                'level' => $level,
            ]);
        } else {
            $courseInsert->execute([
                'faculty_code' => $faculty,
                'department_name' => $department,
                'course_code' => $courseLookupCode,
                'course_title' => $courseLookupTitle,
                'level' => $level,
            ]);
        }
    }

    $uploadError = (int)($file['error'] ?? UPLOAD_ERR_NO_FILE);
    if ($uploadError !== UPLOAD_ERR_OK && $uploadError !== UPLOAD_ERR_NO_FILE) {
        switch ($uploadError) {
            case UPLOAD_ERR_INI_SIZE:
            case UPLOAD_ERR_FORM_SIZE:
                $message = 'File too large. Upload files up to 50 MB.';
                break;
            case UPLOAD_ERR_PARTIAL:
                $message = 'Upload failed because the file was only partially received. Please try again.';
                break;
            default:
                $message = 'Upload failed. Please try again.';
        }
        json_error($message, $uploadError === UPLOAD_ERR_INI_SIZE || $uploadError === UPLOAD_ERR_FORM_SIZE ? 413 : 400);
    }

    if (($file['size'] ?? 0) > MAX_UPLOAD_BYTES) {
        json_error('File too large. Upload files up to 50 MB.', 413);
    }

    if ($uploadError === UPLOAD_ERR_OK && !empty($file['tmp_name'])) {
        $detectedMime = mime_content_type((string)$file['tmp_name']) ?: (string)($file['type'] ?? '');
        $allowed = [
            'application/pdf',
            'image/jpeg',
            'image/png',
            'image/webp',
        ];
        if (!in_array($detectedMime, $allowed, true)) {
            json_error('Only PDF and image files can be uploaded.', 400);
        }

        $safeName = preg_replace('/[^A-Za-z0-9._-]+/', '_', basename((string)$file['name'])) ?: 'paper';
        $storedName = sprintf('%s_%s', date('YmdHis'), $safeName);
        $destination = rtrim($targetDir, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . $storedName;
        if (!move_uploaded_file((string)$file['tmp_name'], $destination)) {
            json_error('Failed to store uploaded file.', 500);
        }

        $uploadPath = 'uploads/' . $storedName;
        $fileName = (string)($file['name'] ?? null);
        $fileMime = $detectedMime;
        $fileSize = (int)($file['size'] ?? 0);
    }

    $title = $paperTitle;
    if ($title === '') {
        $title = trim(sprintf('%s %s %s %s', $faculty, $department, $level, $session));
    }
    if ($title === '' && $courseCode !== '') {
        $title = $courseCode;
    }

    $paperStmt->execute([
        'title' => $title,
        'faculty_code' => $faculty,
        'department_name' => $department,
        'level' => $level,
        'exam_type' => $type,
        'session_label' => $session,
        'course_code' => $courseCode !== '' ? $courseCode : null,
        'file_path' => $uploadPath,
        'file_name' => $fileName,
        'file_mime' => $fileMime,
        'file_size' => $fileSize,
        'uploaded_by' => $userId,
    ]);

    $paperId = (int) $db->lastInsertId();
    $uploadStmt->execute([
        'user_id' => $userId,
        'faculty_code' => $faculty,
        'department_name' => $department,
        'course_code' => $courseCode !== '' ? $courseCode : null,
        'course_title' => $courseTitle !== '' ? $courseTitle : $title,
        'level' => $level,
        'exam_type' => $type,
        'session_label' => $session,
        'status' => 'pending',
    ]);

    $inserted[] = [
        'id' => $paperId,
        'title' => $title,
        'faculty_code' => $faculty,
        'department_name' => $department,
        'level' => $level,
        'exam_type' => $type,
        'session_label' => $session,
        'course_code' => $courseCode !== '' ? $courseCode : null,
        'file_path' => $uploadPath,
    ];
}

json_ok([
    'count' => count($inserted),
    'paper' => $inserted[0] ?? null,
    'papers' => $inserted,
], 201);
