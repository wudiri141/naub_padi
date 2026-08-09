import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String _themeKey = 'theme_mode';
  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _fullNameKey = 'full_name';
  static const String _emailKey = 'profile_email';
  static const String _facultyKey = 'faculty_code';
  static const String _departmentKey = 'department_name';
  static const String _levelKey = 'level';
  static const String _onboardingCompleteKey = 'onboarding_complete';

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_themeKey) ?? 'light') == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<StoredSession> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    return StoredSession(
      token: prefs.getString(_tokenKey),
      userId: prefs.getInt(_userIdKey),
      fullName: prefs.getString(_fullNameKey),
      email: prefs.getString(_emailKey),
      facultyCode: prefs.getString(_facultyKey),
      departmentName: prefs.getString(_departmentKey),
      level: prefs.getString(_levelKey),
    );
  }

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  Future<void> saveAuthSession({
    required String token,
    required int userId,
    required String fullName,
    required String email,
    String? facultyCode,
    String? departmentName,
    String? level,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_fullNameKey, fullName);
    await prefs.setString(_emailKey, email);

    if (facultyCode != null && facultyCode.isNotEmpty) {
      await prefs.setString(_facultyKey, facultyCode);
    } else {
      await prefs.remove(_facultyKey);
    }

    if (departmentName != null && departmentName.isNotEmpty) {
      await prefs.setString(_departmentKey, departmentName);
    } else {
      await prefs.remove(_departmentKey);
    }

    if (level != null && level.isNotEmpty) {
      await prefs.setString(_levelKey, level);
    } else {
      await prefs.remove(_levelKey);
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String email,
    String? facultyCode,
    String? departmentName,
    String? level,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fullNameKey, fullName);
    await prefs.setString(_emailKey, email);

    if (facultyCode != null && facultyCode.isNotEmpty) {
      await prefs.setString(_facultyKey, facultyCode);
    } else {
      await prefs.remove(_facultyKey);
    }

    if (departmentName != null && departmentName.isNotEmpty) {
      await prefs.setString(_departmentKey, departmentName);
    } else {
      await prefs.remove(_departmentKey);
    }

    if (level != null && level.isNotEmpty) {
      await prefs.setString(_levelKey, level);
    } else {
      await prefs.remove(_levelKey);
    }
  }

  Future<void> clearAuthSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_fullNameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_facultyKey);
    await prefs.remove(_departmentKey);
    await prefs.remove(_levelKey);
  }
}

class StoredSession {
  const StoredSession({
    required this.token,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.facultyCode,
    required this.departmentName,
    required this.level,
  });

  final String? token;
  final int? userId;
  final String? fullName;
  final String? email;
  final String? facultyCode;
  final String? departmentName;
  final String? level;
}
