<?php

declare(strict_types=1);

function naub_structure(): array
{
    return [
        [
            'code' => 'FAMSS',
            'name' => 'Faculty of Arts and Management',
            'description' => 'Arts and management programs.',
            'departments' => [
                'Arabic',
                'English',
                'Military History',
                'Management',
                'Transport and Logistics Management',
            ],
        ],
        [
            'code' => 'FSS',
            'name' => 'Faculty of Social Sciences',
            'description' => 'Social sciences programs.',
            'departments' => [
                'Accounting',
                'Economics',
                'Criminology and Security Studies',
                'Geography',
                'International Relations',
                'Peace Studies and Conflict Resolution',
                'Political Science',
                'Psychology',
                'Sociology',
            ],
        ],
        [
            'code' => 'FCOM',
            'name' => 'Faculty of Computing',
            'description' => 'Computing and information system programs.',
            'departments' => [
                'Computer Science',
                'Cyber Security',
                'Information System',
                'Information Technology',
                'Software Engineering',
            ],
        ],
        [
            'code' => 'FENG',
            'name' => 'Faculty of Engineering',
            'description' => 'Engineering programs.',
            'departments' => [
                'Civil Engineering',
                'Electrical and Electronic Engineering',
                'Mechanical Engineering',
            ],
        ],
        [
            'code' => 'FEVS',
            'name' => 'Faculty of Environmental Sciences',
            'description' => 'Environmental and built environment programs.',
            'departments' => [
                'Building',
                'Environmental Management',
                'Estate Management',
                'Survey and Geo-Informatics',
                'Urban and Regional Planning',
            ],
        ],
        [
            'code' => 'FNAS',
            'name' => 'Faculty of Natural and Applied Sciences',
            'description' => 'Natural science and applied science programs.',
            'departments' => [
                'Biology',
                'Chemistry',
                'Mathematics',
                'Physics',
            ],
        ],
    ];
}

function naub_faculty_codes(): array
{
    return array_map(static fn (array $faculty): string => $faculty['code'], naub_structure());
}

function naub_departments_for(string $facultyCode): array
{
    foreach (naub_structure() as $faculty) {
        if (strcasecmp($faculty['code'], $facultyCode) === 0) {
            return $faculty['departments'];
        }
    }

    return [];
}
