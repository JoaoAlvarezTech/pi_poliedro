import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/firestore_service.dart';
import '../../models/discipline_model.dart';
import '../../models/material_model.dart';

class MaterialsScreen extends StatefulWidget {
  final DisciplineModel discipline;
  final MaterialModel? selectedMaterial;

  const MaterialsScreen({
    super.key,
    required this.discipline,
    this.selectedMaterial,
  });

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  List<MaterialModel> _materials = [];
  bool _isLoading = true;
  bool _showCreateForm = false;
  bool _isUploading = false;
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  
  String _selectedType = 'link';
  String? _selectedFile;
  String? _fileName;
  Uint8List? _selectedFileBytes;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    try {
      final materials = await _firestoreService.getDisciplineMaterials(widget.discipline.id);
      setState(() {
        _materials = materials;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Erro ao carregar materiais: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          _fileName = result.files.single.name;
          if (kIsWeb) {
            // Para web, usar bytes
            _selectedFileBytes = result.files.single.bytes;
            _selectedFile = null;
          } else {
            // Para mobile/desktop, usar path
            _selectedFile = result.files.single.path;
            _selectedFileBytes = null;
          }
        });
      }
    } catch (e) {
      _showErrorDialog('Erro ao selecionar arquivo: $e');
    }
  }

  Future<String> _uploadFile() async {
    if (_selectedFile == null && _selectedFileBytes == null) {
      throw Exception('Nenhum arquivo selecionado');
    }

    try {
      setState(() {
        _isUploading = true;
      });

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$_fileName';
      final ref = _storage.ref().child('materials/${widget.discipline.id}/$fileName');
      
      UploadTask uploadTask;
      if (kIsWeb && _selectedFileBytes != null) {
        // Para web, usar bytes
        uploadTask = ref.putData(_selectedFileBytes!);
      } else if (_selectedFile != null) {
        // Para mobile/desktop, usar File
        uploadTask = ref.putFile(File(_selectedFile!));
      } else {
        throw Exception('Arquivo não encontrado');
      }
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Erro ao fazer upload: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _createMaterial() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String? fileUrl;
      int? fileSize;

      if (_selectedType == 'pdf' || _selectedType == 'image') {
        if (_selectedFile == null && _selectedFileBytes == null) {
          _showErrorDialog('Por favor, selecione um arquivo');
          return;
        }
        fileUrl = await _uploadFile();
        // Aqui você pode calcular o tamanho do arquivo se necessário
      } else if (_selectedType == 'link') {
        fileUrl = _linkController.text.trim();
      }

      final material = MaterialModel(
        id: '', // Será gerado pelo Firestore
        disciplineId: widget.discipline.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        fileUrl: fileUrl,
        fileName: _fileName,
        fileSize: fileSize,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createMaterial(material);
      
      _titleController.clear();
      _descriptionController.clear();
      _linkController.clear();
      _selectedFile = null;
      _fileName = null;
      
      setState(() {
        _showCreateForm = false;
        _selectedType = 'link';
      });
      
      _loadMaterials();
      _showSuccessDialog('Material criado com sucesso!');
    } catch (e) {
      _showErrorDialog('Erro ao criar material: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sucesso'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7DDB8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A5B5),
        foregroundColor: Colors.white,
        title: Text('Materiais - ${widget.discipline.name}'),
        actions: [
          IconButton(
            icon: Icon(_showCreateForm ? Icons.close : Icons.add),
            onPressed: () {
              setState(() {
                _showCreateForm = !_showCreateForm;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_showCreateForm) _buildCreateForm(),
                Expanded(child: _buildMaterialsList()),
              ],
            ),
    );
  }

  Widget _buildCreateForm() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Novo Material',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEB2E54),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite o título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite uma descrição';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Material',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'link', child: Text('Link')),
                  DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                  DropdownMenuItem(value: 'image', child: Text('Imagem')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_selectedType == 'link')
                TextFormField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'URL do Link',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, digite a URL';
                    }
                    return null;
                  },
                )
              else
                Column(
                  children: [
                    if (_selectedFile != null || _selectedFileBytes != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_fileName!)),
                          ],
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Selecionar Arquivo'),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _createMaterial,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A5B5),
                        foregroundColor: Colors.white,
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Criar Material'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showCreateForm = false;
                        });
                      },
                      child: const Text('Cancelar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialsList() {
    if (_materials.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum material cadastrado',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Adicione materiais para compartilhar com os alunos',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _materials.length,
      itemBuilder: (context, index) {
        final material = _materials[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getMaterialColor(material.type),
              child: Icon(_getMaterialIcon(material.type), color: Colors.white),
            ),
            title: Text(
              material.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(material.description),
                const SizedBox(height: 4),
                Chip(
                  label: Text(_getMaterialTypeName(material.type)),
                  backgroundColor: _getMaterialColor(material.type).withOpacity(0.1),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Abrir material
              if (material.fileUrl != null) {
                // Implementar abertura do material
                _showSuccessDialog('Material: ${material.title}');
              }
            },
          ),
        );
      },
    );
  }

  Color _getMaterialColor(String type) {
    switch (type) {
      case 'pdf':
        return Colors.red;
      case 'image':
        return Colors.green;
      case 'link':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getMaterialIcon(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      case 'link':
        return Icons.link;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getMaterialTypeName(String type) {
    switch (type) {
      case 'pdf':
        return 'PDF';
      case 'image':
        return 'Imagem';
      case 'link':
        return 'Link';
      default:
        return 'Documento';
    }
  }
}
