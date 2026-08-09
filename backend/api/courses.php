<?php
require __DIR__ . '/_bootstrap.php';
require __DIR__ . '/_structure.php';

$facultyCode = trim((string)($_GET['faculty_code'] ?? ''));
$departmentName = trim((string)($_GET['department_name'] ?? ''));
$level = trim((string)($_GET['level'] ?? ''));

$sql = 'SELECT id, course_code, course_title, faculty_code, department_name, level FROM courses WHERE 1=1';
$params = [];
if ($facultyCode !== '') { $sql .= ' AND faculty_code = :faculty_code'; $params['faculty_code'] = $facultyCode; }
if ($departmentName !== '') { $sql .= ' AND department_name = :department_name'; $params['department_name'] = $departmentName; }
if ($level !== '') { $sql .= ' AND level = :level'; $params['level'] = $level; }
$sql .= ' ORDER BY course_title';

$stmt = db()->prepare($sql);
$stmt->execute($params);
$allowedDepartments = [];
foreach (naub_structure() as $faculty) {
    foreach ($faculty['departments'] as $department) {
        $allowedDepartments[strtolower($faculty['code'] . '|' . $department)] = true;
    }
}

$courses = array_values(array_filter($stmt->fetchAll(), static function (array $course) use ($allowedDepartments): bool {
    $key = strtolower(trim((string)($course['faculty_code'] ?? '')) . '|' . trim((string)($course['department_name'] ?? '')));
    return isset($allowedDepartments[$key]);
}));

$courses = array_map(static function (array $course): array {
    $courseCode = trim((string)($course['course_code'] ?? ''));
    $courseTitle = trim((string)($course['course_title'] ?? ''));

    $course['course_key'] = $courseCode !== '' ? $courseCode : $courseTitle;
    return $course;
}, $courses);

json_ok(['courses' => $courses]);
