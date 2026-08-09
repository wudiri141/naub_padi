<?php
require __DIR__ . '/_bootstrap.php';
require __DIR__ . '/_structure.php';

$code = $_GET['code'] ?? null;

if ($code) {
    $faculty = null;
    foreach (naub_structure() as $entry) {
        if (strcasecmp($entry['code'], (string) $code) === 0) {
            $faculty = $entry;
            break;
        }
    }
    if (!$faculty) {
        json_error('Faculty not found', 404);
    }

    json_ok(['faculty' => [
        'code' => $faculty['code'],
        'name' => $faculty['name'],
        'description' => $faculty['description'],
        'departmentCount' => count($faculty['departments']),
        'departments' => $faculty['departments'],
    ], 'departments' => $faculty['departments']]);
}

json_ok([
    'faculties' => array_map(static function (array $faculty): array {
        return [
            'code' => $faculty['code'],
            'name' => $faculty['name'],
            'description' => $faculty['description'],
            'departmentCount' => count($faculty['departments']),
            'departments' => $faculty['departments'],
        ];
    }, naub_structure()),
]);
