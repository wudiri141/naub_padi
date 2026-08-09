class FacultyModel {
  const FacultyModel({
    required this.code,
    required this.name,
    required this.departmentCount,
    this.description,
    this.departments = const <String>[],
  });

  final String code;
  final String name;
  final int departmentCount;
  final String? description;
  final List<String> departments;

  factory FacultyModel.fromJson(Map<String, dynamic> json) {
    final departments = (json['departments'] as List<dynamic>?)?.map((entry) => entry.toString()).toList() ?? const <String>[];

    return FacultyModel(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      departmentCount: int.tryParse(json['departmentCount']?.toString() ?? json['department_count']?.toString() ?? departments.length.toString()) ?? departments.length,
      description: json['description']?.toString(),
      departments: departments,
    );
  }

  FacultyModel copyWith({
    String? code,
    String? name,
    int? departmentCount,
    String? description,
    List<String>? departments,
  }) {
    return FacultyModel(
      code: code ?? this.code,
      name: name ?? this.name,
      departmentCount: departmentCount ?? this.departmentCount,
      description: description ?? this.description,
      departments: departments ?? this.departments,
    );
  }
}

