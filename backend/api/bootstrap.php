<?php
require __DIR__ . '/_bootstrap.php';
require __DIR__ . '/_structure.php';

$faculties = naub_structure();

json_ok([
    'faculties' => array_map(static function (array $faculty): array {
        return [
            'code' => $faculty['code'],
            'name' => $faculty['name'],
            'description' => $faculty['description'],
            'departmentCount' => count($faculty['departments']),
            'departments' => $faculty['departments'],
        ];
    }, $faculties),
    'levelOptions' => ['100L', '200L', '300L', '400L', '500L'],
    'examTypeOptions' => ['CA', 'Mid Semester', 'End of Semester', 'Practical'],
    'sessionOptions' => ['2018/2019', '2019/2020', '2020/2021', '2021/2022', '2022/2023', '2023/2024', '2024/2025', '2025/2026', '2025B/2026'],
]);
