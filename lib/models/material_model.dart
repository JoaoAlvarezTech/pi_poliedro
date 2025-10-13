class MaterialModel {
  final String id;
  final String disciplineId;
  final String title;
  final String description;
  final String type; // 'pdf', 'image', 'link', 'document'
  final String? fileUrl; // URL do arquivo (para PDFs e imagens)
  final String? linkUrl; // URL do link (para links externos)
  final String? fileName; // Nome do arquivo original
  final int? fileSize; // Tamanho do arquivo em bytes
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaterialModel({
    required this.id,
    required this.disciplineId,
    required this.title,
    required this.description,
    required this.type,
    this.fileUrl,
    this.linkUrl,
    this.fileName,
    this.fileSize,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaterialModel.fromMap(Map<String, dynamic> map) {
    return MaterialModel(
      id: map['id'] ?? '',
      disciplineId: map['disciplineId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? '',
      fileUrl: map['fileUrl'],
      linkUrl: map['linkUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'disciplineId': disciplineId,
      'title': title,
      'description': description,
      'type': type,
      'fileUrl': fileUrl,
      'linkUrl': linkUrl,
      'fileName': fileName,
      'fileSize': fileSize,
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
