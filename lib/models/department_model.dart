class DepartmentModel {
  const DepartmentModel({
    required this.facultyCode,
    required this.name,
    this.sortOrder = 0,
  });

  final String facultyCode;
  final String name;
  final int sortOrder;

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      facultyCode: json['faculty_code']?.toString() ?? json['facultyCode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
    );
  }
}

