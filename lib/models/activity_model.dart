class ActivityModel {
  final String id;
  final String disciplineId;
  final String name;
  final String description;
  final double weight; // Peso da atividade (ex: 0.3 = 30%)
  final double maxGrade; // Nota máxima
  final DateTime dueDate; // Data de entrega
  final bool hasAttachment; // Se tem anexo
  final String? attachmentUrl; // URL do anexo
  final String? attachmentName; // Nome do arquivo anexo
  final String? attachmentType; // Tipo do anexo (pdf, doc, etc.)
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ActivityModel({
    required this.id,
    required this.disciplineId,
    required this.name,
    required this.description,
    required this.weight,
    required this.maxGrade,
    required this.dueDate,
    this.hasAttachment = false,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentType,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'] ?? '',
      disciplineId: map['disciplineId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      weight: (map['weight'] ?? 0.0).toDouble(),
      maxGrade: (map['maxGrade'] ?? 0.0).toDouble(),
      dueDate: map['dueDate']?.toDate() ?? DateTime.now(),
      hasAttachment: map['hasAttachment'] ?? false,
      attachmentUrl: map['attachmentUrl'],
      attachmentName: map['attachmentName'],
      attachmentType: map['attachmentType'],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'disciplineId': disciplineId,
      'name': name,
      'description': description,
      'weight': weight,
      'maxGrade': maxGrade,
      'dueDate': dueDate,
      'hasAttachment': hasAttachment,
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
      'attachmentType': attachmentType,
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
