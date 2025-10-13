class GradeModel {
  final String id;
  final String studentId;
  final String activityId;
  final String disciplineId;
  final double grade;
  final String? comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  GradeModel({
    required this.id,
    required this.studentId,
    required this.activityId,
    required this.disciplineId,
    required this.grade,
    this.comments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GradeModel.fromMap(Map<String, dynamic> map) {
    return GradeModel(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      activityId: map['activityId'] ?? '',
      disciplineId: map['disciplineId'] ?? '',
      grade: (map['grade'] ?? 0.0).toDouble(),
      comments: map['comments'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'activityId': activityId,
      'disciplineId': disciplineId,
      'grade': grade,
      'comments': comments,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
