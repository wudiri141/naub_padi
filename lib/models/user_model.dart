class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.facultyCode,
    this.departmentName,
    this.level,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String fullName;
  final String email;
  final String? facultyCode;
  final String? departmentName;
  final String? level;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      fullName: json['full_name']?.toString() ?? json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      facultyCode: json['faculty_code']?.toString(),
      departmentName: json['department_name']?.toString(),
      level: json['level']?.toString(),
      createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at'].toString()),
      updatedAt: json['updated_at'] == null ? null : DateTime.tryParse(json['updated_at'].toString()),
    );
  }

  UserModel copyWith({
    int? id,
    String? fullName,
    String? email,
    String? facultyCode,
    String? departmentName,
    String? level,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      facultyCode: facultyCode ?? this.facultyCode,
      departmentName: departmentName ?? this.departmentName,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'U';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}
