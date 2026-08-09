<?php
require __DIR__ . '/_bootstrap.php';
require __DIR__ . '/_structure.php';

$facultyCode = trim((string)($_GET['faculty_code'] ?? $_GET['faculty'] ?? ''));

$departments = [];
foreach (naub_structure() as $faculty) {
    if ($facultyCode !== '' && strcasecmp($faculty['code'], $facultyCode) !== 0) {
        continue;
    }

    foreach ($faculty['departments'] as $index => $department) {
        $departments[] = [
            'faculty_code' => $faculty['code'],
            'name' => $department,
            'sort_order' => $index + 1,
        ];
    }
}

json_ok(['departments' => $departments]);
