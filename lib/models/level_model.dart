class LevelModel {
  const LevelModel({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  factory LevelModel.fromValue(String value) {
    return LevelModel(value: value, label: value);
  }
}

