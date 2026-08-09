import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import 'api_service.dart';

class UploadService {
  UploadService._({ApiService? apiService}) : _apiService = apiService ?? ApiService.instance;

  static final UploadService instance = UploadService._();

  final ApiService _apiService;

  Future<Map<String, dynamic>> uploadQuestionPaper({
    required String facultyCode,
    required String department,
    required String level,
    required String examType,
    required String session,
    String? courseCode,
    String? courseTitle,
    String? title,
    int? userId,
    List<PlatformFile>? files,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
  }) {
    return _apiService.uploadQuestionPaper(
      facultyCode: facultyCode,
      department: department,
      level: level,
      examType: examType,
      session: session,
      courseCode: courseCode,
      courseTitle: courseTitle,
      title: title,
      userId: userId,
      files: files,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );
  }
}
