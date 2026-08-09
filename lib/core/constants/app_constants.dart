import 'package:flutter/material.dart';

class AppConstants {
  const AppConstants._();

  static const String appName = 'NAUB Padi';
  static const String appSubtitle = 'Question Bank & Repository';
  static const String universityName = 'Nigerian Army University Biu';
  static const String apiBaseUrlEnvironmentKey = 'NAUB_API_BASE_URL';
  static const String fallbackApiBaseUrl = 'https://naubpadi.vtutopup.com.ng/api';

  static const double maxContentWidth = 1120;
  static const double screenHorizontalPadding = 16;
  static const double screenVerticalPadding = 16;
  static const double screenBottomPadding = 24;
  static const double cardBorderRadius = 20;
  static const double controlBorderRadius = 16;
  static const double buttonHeight = 48;
  static const double inputHeight = 52;

  static const int maxUploadFiles = 10;
  static const int maxUploadFileSizeMb = 50;

  static const List<String> defaultLevels = <String>['100L', '200L', '300L', '400L', '500L'];
  static const List<String> defaultExamTypes = <String>['CA', 'Mid Semester', 'End of Semester', 'Practical'];
  static const List<String> defaultSessions = <String>[
    '2018/2019',
    '2019/2020',
    '2020/2021',
    '2021/2022',
    '2022/2023',
    '2023/2024',
    '2024/2025',
    '2025/2026',
    '2025B/2026',
  ];

  static const List<String> defaultSearchShortcuts = <String>[
    'FAMSS',
    'FSS',
    'FCOM',
    'FENG',
    '2024/2025',
    'SWE318',
  ];

  static const List<String> allowedUploadExtensions = <String>['pdf', 'jpg', 'jpeg', 'png', 'webp'];

  static Color facultyAccent(String code) {
    switch (code.toUpperCase()) {
      case 'FAMSS':
        return const Color(0xFFC43A3A);
      case 'FSS':
        return const Color(0xFF2F7D8A);
      case 'FCOM':
        return const Color(0xFFD98234);
      case 'FENG':
        return const Color(0xFF4F6D9A);
      case 'FEVS':
        return const Color(0xFF4D9962);
      case 'FNAS':
        return const Color(0xFF8D5BAF);
      default:
        return const Color(0xFF8C6C29);
    }
  }
}
