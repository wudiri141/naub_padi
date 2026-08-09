import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../core/constants/app_constants.dart';
import '../models/bootstrap_data.dart';
import '../models/course_model.dart';
import '../models/department_model.dart';
import '../models/faculty_model.dart';
import '../models/question_paper_model.dart';
import '../models/user_model.dart';

class ApiService {
  ApiService._()
      : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(minutes: 5),
            receiveTimeout: const Duration(minutes: 5),
          ),
        );

  static final ApiService instance = ApiService._();

  static String get _baseUrl => const String.fromEnvironment(
        AppConstants.apiBaseUrlEnvironmentKey,
        defaultValue: AppConstants.fallbackApiBaseUrl,
      );

  final Dio _dio;
  Future<BootstrapData>? _bootstrapFuture;

  Future<BootstrapData> bootstrap() {
    _bootstrapFuture ??= _fetchBootstrap();
    return _bootstrapFuture!;
  }

  Future<List<FacultyModel>> faculties({String? code}) async {
    final response = await _getMap('/faculties.php', queryParameters: {
      if (code != null && code.isNotEmpty) 'code': code,
    });

    if (response['faculties'] is List) {
      return (response['faculties'] as List<dynamic>).map((entry) => FacultyModel.fromJson(Map<String, dynamic>.from(entry as Map))).toList();
    }

    if (response['faculty'] is Map<String, dynamic>) {
      return [FacultyModel.fromJson(Map<String, dynamic>.from(response['faculty'] as Map))];
    }

    return const <FacultyModel>[];
  }

  Future<List<DepartmentModel>> departments({String? facultyCode}) async {
    final response = await _getMap('/departments.php', queryParameters: {
      if (facultyCode != null && facultyCode.isNotEmpty) 'faculty_code': facultyCode,
    });

    final list = response['departments'] as List<dynamic>? ?? const <dynamic>[];
    return list.map((entry) => DepartmentModel.fromJson(Map<String, dynamic>.from(entry as Map))).toList();
  }

  Future<List<CourseModel>> courses({String? facultyCode, String? departmentName, String? level}) async {
    try {
      final response = await _getMap('/courses.php', queryParameters: {
        if (facultyCode != null && facultyCode.isNotEmpty) 'faculty_code': facultyCode,
        if (departmentName != null && departmentName.isNotEmpty) 'department_name': departmentName,
        if (level != null && level.isNotEmpty) 'level': level,
      });

      final list = response['courses'] as List<dynamic>? ?? const <dynamic>[];
      final parsed = _dedupeCourses(
        list.map((entry) => CourseModel.fromJson(Map<String, dynamic>.from(entry as Map))).toList(),
      );
      if (parsed.isNotEmpty) {
        return parsed;
      }
    } catch (_) {
      // Fall through to papers-derived courses.
    }

    return _coursesFromPapers(
      facultyCode: facultyCode,
      departmentName: departmentName,
      level: level,
    );
  }

  Future<List<QuestionPaperModel>> questionPapers({
    String? faculty,
    String? department,
    String? level,
    String? type,
    String? session,
    String? courseCode,
    String? query,
  }) async {
    final response = await _getMap('/papers.php', queryParameters: {
      if (faculty != null && faculty.isNotEmpty) 'faculty': faculty,
      if (department != null && department.isNotEmpty) 'department': department,
      if (level != null && level.isNotEmpty) 'level': level,
      if (type != null && type.isNotEmpty) 'type': type,
      if (session != null && session.isNotEmpty) 'session': session,
      if (courseCode != null && courseCode.isNotEmpty) 'course_code': courseCode,
      if (query != null && query.isNotEmpty) 'q': query,
    });
    final list = response['papers'] as List<dynamic>? ?? const <dynamic>[];
    final papers = list.map((entry) => QuestionPaperModel.fromJson(Map<String, dynamic>.from(entry as Map))).toList();
    return _filterQuestionPapers(
      papers,
      faculty: faculty,
      department: department,
      level: level,
      type: type,
      session: session,
      courseCode: courseCode,
      query: query,
    );
  }

  Future<List<QuestionPaperModel>> savedPapers({required int userId}) async {
    final response = await _getMap('/saved.php', queryParameters: {'user_id': '$userId'});
    final list = response['papers'] as List<dynamic>? ?? const <dynamic>[];
    return list.map((entry) => QuestionPaperModel.fromJson(Map<String, dynamic>.from(entry as Map))).toList();
  }

  Future<UserModel> profile({String? email, int? userId}) async {
    final response = await _getMap('/profile.php?debug=1', queryParameters: {
      if (email != null && email.isNotEmpty) 'email': email,
      if (userId != null) 'user_id': '$userId',
    });

    final profile = response['profile'];
    if (profile is Map) {
      return UserModel.fromJson(Map<String, dynamic>.from(profile));
    }

    throw ApiException('Profile not found', 404);
  }

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    return _postMap('/login.php', data: {'email': email, 'password': password});
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? facultyCode,
    String? departmentName,
    String? level,
  }) async {
    return _postMap(
      '/register.php',
      data: {
        'full_name': fullName,
        'email': email,
        'password': password,
        if (facultyCode != null && facultyCode.isNotEmpty) 'faculty_code': facultyCode,
        if (departmentName != null && departmentName.isNotEmpty) 'department_name': departmentName,
        if (level != null && level.isNotEmpty) 'level': level,
      },
    );
  }

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
  }) async {
    final payload = <String, dynamic>{
      'faculty_code': facultyCode,
      'department_name': department,
      'level': level,
      'exam_type': examType,
      'session_label': session,
      if (courseCode != null && courseCode.isNotEmpty) 'course_code': courseCode,
      if (courseTitle != null && courseTitle.isNotEmpty) 'course_title': courseTitle,
      if (title != null && title.isNotEmpty) 'title': title,
      if (userId case final id?) 'user_id': id,
    };

    if (files != null && files.isNotEmpty) {
      final multipartFiles = <MultipartFile>[];
      for (final file in files) {
        if (file.path == null || file.path!.isEmpty) {
          throw ApiException('${file.name} could not be prepared for upload. Please choose it again.', 400);
        }
        multipartFiles.add(await MultipartFile.fromFile(file.path!, filename: file.name));
      }
      if (multipartFiles.isEmpty) {
        throw ApiException('Choose at least one valid PDF or image file to upload.', 400);
      }
      payload['files'] = multipartFiles;
    }

    final response = await _dio.post(
      '/upload.php?debug=1',
      data: FormData.fromMap(payload),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      options: Options(
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
    return _ensureMap(response);
  }

  List<CourseModel> _dedupeCourses(List<CourseModel> courses) {
    final deduped = <String, CourseModel>{};
    for (final course in courses) {
      final key = _normalize(course.lookupKey);
      if (key.isEmpty) {
        continue;
      }

      final existing = deduped[key];
      if (existing == null) {
        deduped[key] = course;
        continue;
      }

      final existingHasCode = existing.courseCode.trim().isNotEmpty;
      final nextHasCode = course.courseCode.trim().isNotEmpty;
      if (!existingHasCode && nextHasCode) {
        deduped[key] = course;
      }
    }

    return deduped.values.toList(growable: false);
  }

  Future<List<CourseModel>> _coursesFromPapers({
    String? facultyCode,
    String? departmentName,
    String? level,
  }) async {
    final papers = await questionPapers(
      faculty: facultyCode,
      department: departmentName,
      level: level,
    );

    final deduped = <String, CourseModel>{};
    for (final paper in papers) {
      final keySource = paper.courseCode?.trim().isNotEmpty == true ? paper.courseCode!.trim() : paper.displayCourseCode.trim();
      final key = _normalize(keySource);
      if (key.isEmpty) {
        continue;
      }

      deduped.putIfAbsent(
        key,
        () => CourseModel(
          id: paper.id,
          courseCode: paper.courseCode?.trim() ?? '',
          courseTitle: paper.courseCode?.trim().isNotEmpty == true ? paper.displayCourseCode : paper.title,
          facultyCode: paper.facultyCode,
          departmentName: paper.departmentName,
          level: paper.level,
          courseKey: keySource,
        ),
      );
    }

    return deduped.values.toList(growable: false);
  }

  Future<Map<String, dynamic>> bookmark({required int userId, required int paperId, bool remove = false}) async {
    return _postMap(
      '/bookmark.php',
      data: {
        'user_id': userId,
        'paper_id': paperId,
        'action': remove ? 'remove' : 'toggle',
      },
    );
  }

  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String fullName,
    String? facultyCode,
    String? departmentName,
    String? level,
  }) async {
    return _postMap(
      '/profile.php?debug=1',
      data: {
        'user_id': userId,
        'full_name': fullName,
        'faculty_code': facultyCode ?? '',
        'department_name': departmentName ?? '',
        'level': level ?? '',
      },
    );
  }

  Future<BootstrapData> _fetchBootstrap() async {
    try {
      final response = await _getMap('/bootstrap.php');
      return BootstrapData.fromJson(response);
    } catch (_) {
      return BootstrapData.fallback();
    }
  }

  Future<Map<String, dynamic>> _getMap(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    return _ensureMap(response);
  }

  Future<Map<String, dynamic>> _postMap(String path, {Map<String, dynamic>? data}) async {
    final response = await _dio.post(path, data: data);
    return _ensureMap(response);
  }

  Map<String, dynamic> _ensureMap(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data['success'] == true) {
        return data;
      }
      throw ApiException(data['message']?.toString() ?? 'Request failed', response.statusCode ?? 0);
    }
    if (data is Map) {
      final mapped = Map<String, dynamic>.from(data);
      if (mapped['success'] == true) {
        return mapped;
      }
      throw ApiException(mapped['message']?.toString() ?? 'Request failed', response.statusCode ?? 0);
    }
    if (data is String) {
      Map<String, dynamic>? mapped;
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          mapped = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        // Fall through to the generic user-facing error below.
      }
      if (mapped != null) {
        if (mapped['success'] == true) {
          return mapped;
        }
        throw ApiException(mapped['message']?.toString() ?? 'Request failed', response.statusCode ?? 0);
      }
    }
    throw ApiException('Unexpected API response', response.statusCode ?? 0);
  }

  List<QuestionPaperModel> _filterQuestionPapers(
    List<QuestionPaperModel> papers, {
    String? faculty,
    String? department,
    String? level,
    String? type,
    String? session,
    String? courseCode,
    String? query,
  }) {
    final searchQuery = _normalize(query);

    return papers.where((paper) {
      if (!_matchesExact(paper.facultyCode, faculty)) {
        return false;
      }
      if (!_matchesExact(paper.departmentName, department)) {
        return false;
      }
      if (!_matchesExact(paper.level, level)) {
        return false;
      }
      if (!_matchesExact(paper.examType, type)) {
        return false;
      }
      if (!_matchesExact(paper.sessionLabel, session)) {
        return false;
      }
      if (!_matchesCourseCode(paper.courseCode, courseCode)) {
        return false;
      }
      if (searchQuery.isNotEmpty && !_matchesQuery(paper, searchQuery)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  bool _matchesExact(String actual, String? expected) {
    if (expected == null || expected.trim().isEmpty) {
      return true;
    }
    return _normalize(actual) == _normalize(expected);
  }

  bool _matchesCourseCode(String? actual, String? expected) {
    if (expected == null || expected.trim().isEmpty) {
      return true;
    }
    final normalizedExpected = _normalize(expected);
    final normalizedActual = _normalize(actual);
    if (normalizedActual == normalizedExpected) {
      return true;
    }
    return false;
  }

  bool _matchesQuery(QuestionPaperModel paper, String query) {
    final haystack = <String>[
      paper.title,
      paper.facultyCode,
      paper.departmentName,
      paper.level,
      paper.examType,
      paper.sessionLabel,
      paper.displayCourseCode,
      paper.courseCode ?? '',
      paper.fileName ?? '',
      paper.displayFileName,
      paper.uploaderName ?? '',
    ].map(_normalize).join(' ');

    return haystack.contains(query);
  }

  String _normalize(String? value) {
    final text = value?.trim().toLowerCase() ?? '';
    if (text.isEmpty) {
      return '';
    }
    return text.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}

class ApiException implements Exception {
  ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
