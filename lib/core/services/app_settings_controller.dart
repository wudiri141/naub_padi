import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/storage_service.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({StorageService? storageService}) : _storageService = storageService ?? StorageService.instance;

  final StorageService _storageService;

  ThemeMode _themeMode = ThemeMode.light;
  String? _jwtToken;
  int? _userId;
  String? _fullName;
  String? _profileEmail;
  String? _facultyCode;
  String? _departmentName;
  String? _level;
  bool _onboardingComplete = false;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  String? get jwtToken => _jwtToken;
  int? get userId => _userId;
  String? get fullName => _fullName;
  String? get profileEmail => _profileEmail;
  String? get facultyCode => _facultyCode;
  String? get departmentName => _departmentName;
  String? get level => _level;
  bool get onboardingComplete => _onboardingComplete;
  bool get loaded => _loaded;
  bool get isSignedIn => _jwtToken?.isNotEmpty == true && _userId != null;

  Future<void> load() async {
    final theme = await _storageService.loadThemeMode();
    final session = await _storageService.loadSession();
    final onboardingComplete = await _storageService.hasCompletedOnboarding();
    _themeMode = theme;
    _jwtToken = session.token;
    _userId = session.userId;
    _fullName = session.fullName;
    _profileEmail = session.email;
    _facultyCode = session.facultyCode;
    _departmentName = session.departmentName;
    _level = session.level;
    _onboardingComplete = onboardingComplete;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storageService.saveThemeMode(mode);
    notifyListeners();
  }

  Future<void> toggleTheme() {
    return setThemeMode(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> saveUser(UserModel user, {String? token}) async {
    _userId = user.id;
    _fullName = user.fullName;
    _profileEmail = user.email;
    _facultyCode = user.facultyCode;
    _departmentName = user.departmentName;
    _level = user.level;
    _jwtToken = token ?? _jwtToken;

    if (_jwtToken != null && _jwtToken!.isNotEmpty) {
      await _storageService.saveAuthSession(
        token: _jwtToken!,
        userId: user.id,
        fullName: user.fullName,
        email: user.email,
        facultyCode: user.facultyCode,
        departmentName: user.departmentName,
        level: user.level,
      );
    } else {
      await _storageService.updateProfile(
        fullName: user.fullName,
        email: user.email,
        facultyCode: user.facultyCode,
        departmentName: user.departmentName,
        level: user.level,
      );
    }

    notifyListeners();
  }

  Future<void> refreshSession() async {
    await load();
  }

  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    await _storageService.markOnboardingComplete();
    notifyListeners();
  }

  Future<void> clearSession() async {
    _jwtToken = null;
    _userId = null;
    _fullName = null;
    _profileEmail = null;
    _facultyCode = null;
    _departmentName = null;
    _level = null;
    await _storageService.clearAuthSession();
    notifyListeners();
  }
}
