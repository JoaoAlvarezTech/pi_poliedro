class BatchGradingModel {
  final String activityId;
  final String disciplineId;
  final String activityName;
  final double maxGrade;
  final List<StudentGrade> studentGrades;

  BatchGradingModel({
    required this.activityId,
    required this.disciplineId,
    required this.activityName,
    required this.maxGrade,
    required this.studentGrades,
  });

  factory BatchGradingModel.fromMap(Map<String, dynamic> map) {
    return BatchGradingModel(
      activityId: map['activityId'] ?? '',
      disciplineId: map['disciplineId'] ?? '',
      activityName: map['activityName'] ?? '',
      maxGrade: (map['maxGrade'] ?? 0.0).toDouble(),
      studentGrades: (map['studentGrades'] as List<dynamic>?)
              ?.map((e) => StudentGrade.fromMap(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activityId': activityId,
      'disciplineId': disciplineId,
      'activityName': activityName,
      'maxGrade': maxGrade,
      'studentGrades': studentGrades.map((e) => e.toMap()).toList(),
    };
  }
}

class StudentGrade {
  final String studentId;
  final String studentName;
  final String? studentRa;
  final double? currentGrade;
  final String? comments;
  final bool hasSubmission;

  StudentGrade({
    required this.studentId,
    required this.studentName,
    this.studentRa,
    this.currentGrade,
    this.comments,
    this.hasSubmission = false,
  });

  factory StudentGrade.fromMap(Map<String, dynamic> map) {
    return StudentGrade(
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentRa: map['studentRa'],
      currentGrade: map['currentGrade']?.toDouble(),
      comments: map['comments'],
      hasSubmission: map['hasSubmission'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentRa': studentRa,
      'currentGrade': currentGrade,
      'comments': comments,
      'hasSubmission': hasSubmission,
    };
  }

  StudentGrade copyWith({
    String? studentId,
    String? studentName,
    String? studentRa,
    double? currentGrade,
    String? comments,
    bool? hasSubmission,
  }) {
    return StudentGrade(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentRa: studentRa ?? this.studentRa,
      currentGrade: currentGrade ?? this.currentGrade,
      comments: comments ?? this.comments,
      hasSubmission: hasSubmission ?? this.hasSubmission,
    );
  }
}
