CREATE DATABASE IF NOT EXISTS `vtutopup_naubpadi`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `vtutopup_naubpadi`;

CREATE TABLE IF NOT EXISTS `faculties` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(10) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_faculties_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `departments` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `faculty_code` VARCHAR(10) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_department_per_faculty` (`faculty_code`, `name`),
  KEY `idx_departments_faculty` (`faculty_code`),
  CONSTRAINT `fk_departments_faculty`
    FOREIGN KEY (`faculty_code`) REFERENCES `faculties` (`code`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `courses` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `faculty_code` VARCHAR(10) NOT NULL,
  `department_name` VARCHAR(255) NOT NULL,
  `course_code` VARCHAR(50) DEFAULT NULL,
  `course_title` VARCHAR(255) NOT NULL,
  `level` VARCHAR(10) DEFAULT NULL,
  `semester_label` VARCHAR(20) DEFAULT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_courses_faculty_department` (`faculty_code`, `department_name`),
  KEY `idx_courses_code` (`course_code`),
  CONSTRAINT `fk_courses_faculty`
    FOREIGN KEY (`faculty_code`) REFERENCES `faculties` (`code`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `users` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `full_name` VARCHAR(255) NOT NULL,
  `email` VARCHAR(255) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `faculty_code` VARCHAR(10) DEFAULT NULL,
  `department_name` VARCHAR(255) DEFAULT NULL,
  `level` VARCHAR(10) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_users_email` (`email`),
  KEY `idx_users_faculty_code` (`faculty_code`),
  CONSTRAINT `fk_users_faculty`
    FOREIGN KEY (`faculty_code`) REFERENCES `faculties` (`code`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `question_papers` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(255) NOT NULL,
  `faculty_code` VARCHAR(10) NOT NULL,
  `department_name` VARCHAR(255) NOT NULL,
  `level` VARCHAR(10) NOT NULL,
  `exam_type` VARCHAR(50) NOT NULL,
  `session_label` VARCHAR(20) NOT NULL,
  `course_code` VARCHAR(50) DEFAULT NULL,
  `file_path` VARCHAR(255) DEFAULT NULL,
  `file_name` VARCHAR(255) DEFAULT NULL,
  `file_mime` VARCHAR(100) DEFAULT NULL,
  `file_size` INT UNSIGNED DEFAULT NULL,
  `uploaded_by` INT UNSIGNED DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_papers_filter` (`faculty_code`, `department_name`, `level`, `exam_type`, `session_label`),
  KEY `idx_papers_course` (`course_code`),
  KEY `idx_papers_uploaded_by` (`uploaded_by`),
  CONSTRAINT `fk_papers_faculty`
    FOREIGN KEY (`faculty_code`) REFERENCES `faculties` (`code`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_papers_user`
    FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `uploads` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED DEFAULT NULL,
  `faculty_code` VARCHAR(10) NOT NULL,
  `department_name` VARCHAR(255) NOT NULL,
  `course_code` VARCHAR(50) DEFAULT NULL,
  `course_title` VARCHAR(255) DEFAULT NULL,
  `level` VARCHAR(10) NOT NULL,
  `exam_type` VARCHAR(50) NOT NULL,
  `session_label` VARCHAR(20) NOT NULL,
  `status` ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_uploads_user` (`user_id`),
  KEY `idx_uploads_status` (`status`),
  CONSTRAINT `fk_uploads_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `saved_papers` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `paper_id` INT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_saved_user_paper` (`user_id`, `paper_id`),
  KEY `idx_saved_user` (`user_id`),
  KEY `idx_saved_paper` (`paper_id`),
  CONSTRAINT `fk_saved_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_saved_paper`
    FOREIGN KEY (`paper_id`) REFERENCES `question_papers` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `notifications` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED DEFAULT NULL,
  `title` VARCHAR(255) NOT NULL,
  `body` VARCHAR(500) NOT NULL,
  `type` VARCHAR(50) NOT NULL DEFAULT 'announcement',
  `is_read` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_notifications_user` (`user_id`),
  KEY `idx_notifications_read` (`is_read`),
  CONSTRAINT `fk_notifications_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `faculties` (`code`, `name`, `description`, `sort_order`) VALUES
('FAMSS', 'Faculty of Arts and Management', 'Arts and management programs.', 1),
('FSS', 'Faculty of Social Sciences', 'Social sciences programs.', 2),
('FCOM', 'Faculty of Computing', 'Computing and information system programs.', 3),
('FENG', 'Faculty of Engineering', 'Engineering programs.', 4),
('FEVS', 'Faculty of Environmental Sciences', 'Environmental and built environment programs.', 5),
('FNAS', 'Faculty of Natural and Applied Sciences', 'Natural science and applied science programs.', 6)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `description` = VALUES(`description`), `sort_order` = VALUES(`sort_order`);

INSERT INTO `departments` (`faculty_code`, `name`, `sort_order`) VALUES
('FAMSS', 'Arabic', 1),
('FAMSS', 'English', 2),
('FAMSS', 'Military History', 3),
('FAMSS', 'Management', 4),
('FAMSS', 'Transport and Logistics Management', 5),
('FSS', 'Accounting', 1),
('FSS', 'Economics', 2),
('FSS', 'Criminology and Security Studies', 3),
('FSS', 'Geography', 4),
('FSS', 'International Relations', 5),
('FSS', 'Peace Studies and Conflict Resolution', 6),
('FSS', 'Political Science', 7),
('FSS', 'Psychology', 8),
('FSS', 'Sociology', 9),
('FCOM', 'Computer Science', 1),
('FCOM', 'Cyber Security', 2),
('FCOM', 'Information System', 3),
('FCOM', 'Information Technology', 4),
('FCOM', 'Software Engineering', 5),
('FENG', 'Civil Engineering', 1),
('FENG', 'Electrical and Electronic Engineering', 2),
('FENG', 'Mechanical Engineering', 3),
('FEVS', 'Building', 1),
('FEVS', 'Environmental Management', 2),
('FEVS', 'Estate Management', 3),
('FEVS', 'Survey and Geo-Informatics', 4),
('FEVS', 'Urban and Regional Planning', 5),
('FNAS', 'Biology', 1),
('FNAS', 'Chemistry', 2),
('FNAS', 'Mathematics', 3),
('FNAS', 'Physics', 4)
ON DUPLICATE KEY UPDATE `sort_order` = VALUES(`sort_order`);

INSERT INTO `courses` (`faculty_code`, `department_name`, `course_code`, `course_title`, `level`, `semester_label`, `sort_order`) VALUES
('FAMSS', 'Arabic', NULL, 'Introductory Arabic', '100L', 'First Semester', 1),
('FAMSS', 'English', NULL, 'Introduction to Literature', '100L', 'First Semester', 2),
('FAMSS', 'Military History', NULL, 'Military History of Africa', '200L', 'Second Semester', 3),
('FAMSS', 'Management', NULL, 'Principles of Management', '300L', 'First Semester', 4),
('FAMSS', 'Transport and Logistics Management', NULL, 'Transport Planning', '300L', 'Second Semester', 5),
('FSS', 'Accounting', NULL, 'Principles of Accounting', '100L', 'First Semester', 1),
('FSS', 'Economics', NULL, 'Microeconomics', '200L', 'First Semester', 2),
('FSS', 'Criminology and Security Studies', NULL, 'Introduction to Criminology', '200L', 'First Semester', 3),
('FSS', 'Geography', NULL, 'Physical Geography', '100L', 'Second Semester', 4),
('FSS', 'International Relations', NULL, 'Introduction to International Relations', '300L', 'First Semester', 5),
('FSS', 'Peace Studies and Conflict Resolution', NULL, 'Peace and Conflict Studies', '400L', 'First Semester', 6),
('FSS', 'Political Science', NULL, 'Political Theory', '200L', 'First Semester', 7),
('FSS', 'Psychology', NULL, 'General Psychology', '200L', 'Second Semester', 8),
('FSS', 'Sociology', NULL, 'Introduction to Sociology', '100L', 'Second Semester', 9),
('FCOM', 'Computer Science', NULL, 'Data Structures', '200L', 'Second Semester', 1),
('FCOM', 'Cyber Security', NULL, 'Ethical Hacking', '300L', 'First Semester', 2),
('FCOM', 'Information System', 'SWE218', 'Database Management Systems', '200L', 'Second Semester', 3),
('FCOM', 'Information Technology', NULL, 'Information Technology Fundamentals', '200L', 'First Semester', 4),
('FCOM', 'Software Engineering', 'SWE318', 'Software Requirements Engineering', '300L', 'Second Semester', 5),
('FENG', 'Civil Engineering', NULL, 'Structural Analysis', '300L', 'First Semester', 1),
('FENG', 'Electrical and Electronic Engineering', NULL, 'Circuit Theory', '200L', 'First Semester', 2),
('FENG', 'Mechanical Engineering', NULL, 'Thermodynamics', '300L', 'First Semester', 3),
('FEVS', 'Building', NULL, 'Building Materials', '100L', 'Second Semester', 1),
('FEVS', 'Environmental Management', NULL, 'Environmental Impact Assessment', '300L', 'First Semester', 2),
('FEVS', 'Estate Management', NULL, 'Estate Valuation', '200L', 'First Semester', 3),
('FEVS', 'Survey and Geo-Informatics', NULL, 'Surveying Principles', '300L', 'First Semester', 4),
('FEVS', 'Urban and Regional Planning', NULL, 'Urban Planning Principles', '200L', 'Second Semester', 5),
('FNAS', 'Biology', NULL, 'Cell Biology', '100L', 'First Semester', 1),
('FNAS', 'Chemistry', NULL, 'Organic Chemistry', '200L', 'First Semester', 2),
('FNAS', 'Mathematics', NULL, 'Linear Algebra', '200L', 'Second Semester', 3),
('FNAS', 'Physics', NULL, 'Mechanics', '100L', 'First Semester', 4)
ON DUPLICATE KEY UPDATE `course_title` = VALUES(`course_title`), `level` = VALUES(`level`), `semester_label` = VALUES(`semester_label`);

INSERT INTO `question_papers` (`title`, `faculty_code`, `department_name`, `level`, `exam_type`, `session_label`, `course_code`, `file_path`, `file_name`, `file_mime`, `file_size`) VALUES
('Sample Software Engineering CA Paper', 'FCOM', 'Software Engineering', '300L', 'CA', '2024/2025', 'SWE318', NULL, NULL, NULL, NULL),
('Sample Management Exam Paper', 'FAMSS', 'Management', '200L', 'End of Semester', '2023/2024', 'MGT214', NULL, NULL, NULL, NULL)
ON DUPLICATE KEY UPDATE `title` = VALUES(`title`);

INSERT INTO `uploads` (`user_id`, `faculty_code`, `department_name`, `course_code`, `course_title`, `level`, `exam_type`, `session_label`, `status`) VALUES
(NULL, 'FCOM', 'Software Engineering', 'SWE318', 'Software Requirements Engineering', '300L', 'CA', '2024/2025', 'approved'),
(NULL, 'FAMSS', 'Management', 'MGT214', 'Principles of Management', '200L', 'End of Semester', '2023/2024', 'pending')
ON DUPLICATE KEY UPDATE `status` = VALUES(`status`);

INSERT INTO `notifications` (`user_id`, `title`, `body`, `type`, `is_read`) VALUES
(NULL, 'New upload', 'A new question paper was uploaded to the repository.', 'upload', 0),
(NULL, 'Paper approved', 'Your uploaded paper has been approved.', 'approval', 0),
(NULL, 'Paper rejected', 'One of your papers was rejected by an admin.', 'rejection', 0),
(NULL, 'Announcement', 'Department heads can now add new sessions.', 'announcement', 0)
ON DUPLICATE KEY UPDATE `body` = VALUES(`body`), `type` = VALUES(`type`);
