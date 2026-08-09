class QuestionPaperModel {
  const QuestionPaperModel({
    required this.id,
    required this.title,
    required this.facultyCode,
    required this.departmentName,
    required this.level,
    required this.examType,
    required this.sessionLabel,
    this.courseCode,
    this.filePath,
    this.fileName,
    this.fileMime,
    this.fileSize,
    this.uploadedBy,
    this.uploaderName,
    this.createdAt,
  });

  final int id;
  final String title;
  final String facultyCode;
  final String departmentName;
  final String level;
  final String examType;
  final String sessionLabel;
  final String? courseCode;
  final String? filePath;
  final String? fileName;
  final String? fileMime;
  final int? fileSize;
  final String? uploadedBy;
  final String? uploaderName;
  final DateTime? createdAt;

  factory QuestionPaperModel.fromJson(Map<String, dynamic> json) {
    return QuestionPaperModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      facultyCode: json['faculty_code']?.toString() ?? '',
      departmentName: json['department_name']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      examType: json['exam_type']?.toString() ?? '',
      sessionLabel: json['session_label']?.toString() ?? '',
      courseCode: json['course_code']?.toString(),
      filePath: json['file_path']?.toString(),
      fileName: json['file_name']?.toString(),
      fileMime: json['file_mime']?.toString(),
      fileSize: int.tryParse(json['file_size']?.toString() ?? ''),
      uploadedBy: json['uploaded_by']?.toString(),
      uploaderName: json['uploader_name']?.toString(),
      createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  String get displayCourseCode => (courseCode != null && courseCode!.trim().isNotEmpty) ? courseCode!.trim() : title;

  String get displayFileName => (fileName != null && fileName!.trim().isNotEmpty)
      ? fileName!.trim()
      : (filePath != null && filePath!.trim().isNotEmpty)
          ? filePath!.split('/').last
          : 'Question paper';

  bool get isPdf {
    final value = (filePath ?? fileName ?? '').toLowerCase();
    return value.endsWith('.pdf') || (fileMime?.toLowerCase().contains('pdf') == true);
  }

  bool get isImage {
    final value = (filePath ?? fileName ?? '').toLowerCase();
    return value.endsWith('.png') ||
        value.endsWith('.jpg') ||
        value.endsWith('.jpeg') ||
        value.endsWith('.webp') ||
        (fileMime?.toLowerCase().contains('image/') == true);
  }
}
