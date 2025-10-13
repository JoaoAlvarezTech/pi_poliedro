class DisciplineModel {
  final String id;
  final String name;
  final String description;
  final String teacherId;
  final String teacherName;
  final String code; // Código da disciplina
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  DisciplineModel({
    required this.id,
    required this.name,
    required this.description,
    required this.teacherId,
    required this.teacherName,
    required this.code,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DisciplineModel.fromMap(Map<String, dynamic> map) {
    return DisciplineModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      code: map['code'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'description': description,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'code': code,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
    
    // Só incluir o ID se não estiver vazio (para updates)
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    
    return map;
  }
}
