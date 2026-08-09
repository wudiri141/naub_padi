class CourseModel {
  const CourseModel({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.facultyCode,
    required this.departmentName,
    required this.level,
    this.semesterLabel,
    this.courseKey,
  });

  final int id;
  final String courseCode;
  final String courseTitle;
  final String facultyCode;
  final String departmentName;
  final String level;
  final String? semesterLabel;
  final String? courseKey;

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      courseCode: json['course_code']?.toString() ?? '',
      courseTitle: json['course_title']?.toString() ?? json['title']?.toString() ?? '',
      facultyCode: json['faculty_code']?.toString() ?? '',
      departmentName: json['department_name']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      semesterLabel: json['semester_label']?.toString(),
      courseKey: json['course_key']?.toString(),
    );
  }

  String get displayCode => courseCode.isEmpty ? courseTitle : courseCode;

  String get lookupKey {
    if (courseKey != null && courseKey!.trim().isNotEmpty) {
      return courseKey!.trim();
    }
    if (courseCode.trim().isNotEmpty) {
      return courseCode.trim();
    }
    return courseTitle.trim();
  }
}
