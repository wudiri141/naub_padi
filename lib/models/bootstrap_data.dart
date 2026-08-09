import '../core/constants/app_constants.dart';
import 'faculty_model.dart';
import 'level_model.dart';

class BootstrapData {
  const BootstrapData({
    required this.faculties,
    required this.levels,
    required this.examTypes,
    required this.sessions,
  });

  final List<FacultyModel> faculties;
  final List<LevelModel> levels;
  final List<String> examTypes;
  final List<String> sessions;

  factory BootstrapData.fromJson(Map<String, dynamic> json) {
    final faculties = (json['faculties'] as List<dynamic>?)?.map((entry) => FacultyModel.fromJson(Map<String, dynamic>.from(entry as Map))).toList() ?? <FacultyModel>[];
    final levels = (json['levelOptions'] as List<dynamic>?)?.map((entry) => LevelModel.fromValue(entry.toString())).toList() ?? AppConstants.defaultLevels.map(LevelModel.fromValue).toList();
    final examTypes = (json['examTypeOptions'] as List<dynamic>?)?.map((entry) => entry.toString()).toList() ?? AppConstants.defaultExamTypes;
    final sessions = (json['sessionOptions'] as List<dynamic>?)?.map((entry) => entry.toString()).toList() ?? AppConstants.defaultSessions;

    return BootstrapData(
      faculties: faculties,
      levels: levels,
      examTypes: examTypes,
      sessions: sessions,
    );
  }

  factory BootstrapData.fallback() {
    return BootstrapData(
      faculties: const [
        FacultyModel(
          code: 'FAMSS',
          name: 'Faculty of Arts and Management',
          departmentCount: 5,
          description: 'Arts and management programs.',
          departments: [
            'Arabic',
            'English',
            'Military History',
            'Management',
            'Transport and Logistics Management',
          ],
        ),
        FacultyModel(
          code: 'FSS',
          name: 'Faculty of Social Sciences',
          departmentCount: 9,
          description: 'Social sciences programs.',
          departments: [
            'Accounting',
            'Economics',
            'Geography',
            'Criminology and Security Studies',
            'International Relations',
            'Peace Studies and Conflict Resolution',
            'Political Science',
            'Psychology',
            'Sociology',
          ],
        ),
        FacultyModel(
          code: 'FCOM',
          name: 'Faculty of Computing',
          departmentCount: 5,
          description: 'Computing and information system programs.',
          departments: [
            'Computer Science',
            'Cyber Security',
            'Information System',
            'Information Technology',
            'Software Engineering',
          ],
        ),
        FacultyModel(
          code: 'FENG',
          name: 'Faculty of Engineering',
          departmentCount: 3,
          description: 'Engineering programs.',
          departments: [
            'Civil Engineering',
            'Electrical and Electronic Engineering',
            'Mechanical Engineering',
          ],
        ),
        FacultyModel(
          code: 'FEVS',
          name: 'Faculty of Environmental Sciences',
          departmentCount: 5,
          description: 'Environmental and built environment programs.',
          departments: [
            'Building',
            'Environmental Management',
            'Estate Management',
            'Survey and Geo-Informatics',
            'Urban and Regional Planning',
          ],
        ),
        FacultyModel(
          code: 'FNAS',
          name: 'Faculty of Natural and Applied Sciences',
          departmentCount: 4,
          description: 'Natural science and applied science programs.',
          departments: [
            'Biology',
            'Chemistry',
            'Mathematics',
            'Physics',
          ],
        ),
      ],
      levels: AppConstants.defaultLevels.map(LevelModel.fromValue).toList(),
      examTypes: AppConstants.defaultExamTypes,
      sessions: AppConstants.defaultSessions,
    );
  }

  FacultyModel? facultyByCode(String? code) {
    if (code == null || code.trim().isEmpty) {
      return null;
    }

    for (final faculty in faculties) {
      if (faculty.code.toUpperCase() == code.trim().toUpperCase()) {
        return faculty;
      }
    }

    return null;
  }

  String? facultyNameForCode(String? code) => facultyByCode(code)?.name;

  List<String> departmentsForFacultyCode(String? code) {
    return facultyByCode(code)?.departments ?? const <String>[];
  }
}
