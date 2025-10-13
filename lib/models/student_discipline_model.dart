class StudentDisciplineModel {
  final String id;
  final String studentId;
  final String disciplineId;
  final String studentName;
  final String disciplineName;
  final bool isActive;
  final DateTime enrolledAt;

  StudentDisciplineModel({
    required this.id,
    required this.studentId,
    required this.disciplineId,
    required this.studentName,
    required this.disciplineName,
    this.isActive = true,
    required this.enrolledAt,
  });

  factory StudentDisciplineModel.fromMap(Map<String, dynamic> map) {
    return StudentDisciplineModel(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      disciplineId: map['disciplineId'] ?? '',
      studentName: map['studentName'] ?? '',
      disciplineName: map['disciplineName'] ?? '',
      isActive: map['isActive'] ?? true,
      enrolledAt: map['enrolledAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'studentId': studentId,
      'disciplineId': disciplineId,
      'studentName': studentName,
      'disciplineName': disciplineName,
      'isActive': isActive,
      'enrolledAt': enrolledAt,
    };
    
    // Só incluir o ID se não estiver vazio (para updates)
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    
    return map;
  }
}
