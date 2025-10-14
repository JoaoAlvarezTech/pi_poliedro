class SubmissionModel {
  final String id;
  final String activityId;
  final String studentId;
  final String disciplineId;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? comments;
  final double? grade;
  final String? teacherComments;
  final DateTime submittedAt;
  final DateTime? gradedAt;
  final String status; // 'submitted', 'graded', 'returned'

  SubmissionModel({
    required this.id,
    required this.activityId,
    required this.studentId,
    required this.disciplineId,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.comments,
    this.grade,
    this.teacherComments,
    required this.submittedAt,
    this.gradedAt,
    this.status = 'submitted',
  });

  factory SubmissionModel.fromMap(Map<String, dynamic> map, String id) {
    return SubmissionModel(
      id: id,
      activityId: map['activityId'] ?? '',
      studentId: map['studentId'] ?? '',
      disciplineId: map['disciplineId'] ?? '',
      fileUrl: map['fileUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      comments: map['comments'],
      grade: map['grade']?.toDouble(),
      teacherComments: map['teacherComments'],
      submittedAt: (map['submittedAt'] as dynamic).toDate(),
      gradedAt: map['gradedAt'] != null 
          ? (map['gradedAt'] as dynamic).toDate() 
          : null,
      status: map['status'] ?? 'submitted',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activityId': activityId,
      'studentId': studentId,
      'disciplineId': disciplineId,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'comments': comments,
      'grade': grade,
      'teacherComments': teacherComments,
      'submittedAt': submittedAt,
      'gradedAt': gradedAt,
      'status': status,
    };
  }

  SubmissionModel copyWith({
    String? id,
    String? activityId,
    String? studentId,
    String? disciplineId,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? comments,
    double? grade,
    String? teacherComments,
    DateTime? submittedAt,
    DateTime? gradedAt,
    String? status,
  }) {
    return SubmissionModel(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      studentId: studentId ?? this.studentId,
      disciplineId: disciplineId ?? this.disciplineId,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      comments: comments ?? this.comments,
      grade: grade ?? this.grade,
      teacherComments: teacherComments ?? this.teacherComments,
      submittedAt: submittedAt ?? this.submittedAt,
      gradedAt: gradedAt ?? this.gradedAt,
      status: status ?? this.status,
    );
  }
}
