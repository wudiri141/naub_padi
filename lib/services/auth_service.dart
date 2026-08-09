import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  AuthService._({
    ApiService? apiService,
    StorageService? storageService,
  })  : _apiService = apiService ?? ApiService.instance,
        _storageService = storageService ?? StorageService.instance;

  static final AuthService instance = AuthService._();

  final ApiService _apiService;
  final StorageService _storageService;

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.login(email: email, password: password);
    final token = response['token']?.toString() ?? '';
    final userData = response['user'];
    if (userData is! Map) {
      throw ApiException('Unable to log in. Please try again later.', 500);
    }

    final user = UserModel.fromJson(Map<String, dynamic>.from(userData));
    return AuthResult(user: user, token: token);
  }

  Future<AuthResult> signUp({
    required String fullName,
    required String email,
    required String password,
    String? facultyCode,
    String? departmentName,
    String? level,
  }) async {
    final response = await _apiService.register(
      fullName: fullName,
      email: email,
      password: password,
      facultyCode: facultyCode,
      departmentName: departmentName,
      level: level,
    );

    final userId = int.tryParse(response['user_id']?.toString() ?? '0') ?? 0;
    final user = UserModel(
      id: userId,
      fullName: fullName,
      email: email,
      facultyCode: facultyCode,
      departmentName: departmentName,
      level: level,
    );

    return AuthResult(user: user, token: '');
  }

  Future<UserModel?> fetchProfile({int? userId, String? email}) async {
    try {
      final profile = await _apiService.profile(userId: userId, email: email);
      await _storageService.updateProfile(
        fullName: profile.fullName,
        email: profile.email,
        facultyCode: profile.facultyCode,
        departmentName: profile.departmentName,
        level: profile.level,
      );
      return profile;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> updateProfile({
    required UserModel user,
  }) async {
    final result = await _apiService.updateProfile(
      userId: user.id,
      fullName: user.fullName,
      facultyCode: user.facultyCode,
      departmentName: user.departmentName,
      level: user.level,
    );
    final updated = result['updated'] == true || result['updated']?.toString() == '1' || result['updated']?.toString().toLowerCase() == 'true';
    if (!updated) {
      throw ApiException('Unable to save changes. Please try again later.', 500);
    }

    final profileData = result['profile'];
    final savedUser = profileData is Map ? UserModel.fromJson(Map<String, dynamic>.from(profileData)) : user;

    await _storageService.updateProfile(
      fullName: savedUser.fullName,
      email: savedUser.email,
      facultyCode: savedUser.facultyCode,
      departmentName: savedUser.departmentName,
      level: savedUser.level,
    );
    return savedUser;
  }
}

class AuthResult {
  const AuthResult({
    required this.user,
    required this.token,
  });

  final UserModel user;
  final String token;
}
