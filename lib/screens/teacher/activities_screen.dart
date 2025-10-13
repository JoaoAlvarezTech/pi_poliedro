import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../services/firestore_service.dart';
import '../../models/discipline_model.dart';
import '../../models/activity_model.dart';
import 'grades_screen.dart';

class ActivitiesScreen extends StatefulWidget {
  final DisciplineModel discipline;
  final ActivityModel? selectedActivity;

  const ActivitiesScreen({
    super.key,
    required this.discipline,
    this.selectedActivity,
  });

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _formKey = GlobalKey<FormState>();
  
  List<ActivityModel> _activities = [];
  bool _isLoading = true;
  bool _showCreateForm = false;
  bool _isUploading = false;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _maxGradeController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  
  // Variáveis para anexo
  String? _selectedFilePath;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _maxGradeController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    try {
      final activities = await _firestoreService.getDisciplineActivities(widget.discipline.id);
      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Erro ao carregar atividades: $e');
    }
  }

  Future<void> _createActivity() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isUploading = true;
      });

      // Upload do anexo se houver
      String? attachmentUrl;
      String? attachmentName;
      String? attachmentType;
      
      if (_selectedFilePath != null) {
        attachmentUrl = await _uploadFile();
        attachmentName = _selectedFileName;
        attachmentType = _getFileType(_selectedFileName!);
      }

      final activity = ActivityModel(
        id: '', // Será gerado pelo Firestore
        disciplineId: widget.discipline.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        weight: double.parse(_weightController.text) / 100, // Converter para decimal
        maxGrade: double.parse(_maxGradeController.text),
        dueDate: _dueDate,
        hasAttachment: _selectedFilePath != null,
        attachmentUrl: attachmentUrl,
        attachmentName: attachmentName,
        attachmentType: attachmentType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createActivity(activity);
      
      _clearForm();
      
      setState(() {
        _showCreateForm = false;
        _isUploading = false;
      });
      
      _loadActivities();
      _showSuccessDialog('Atividade criada com sucesso!');
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showErrorDialog('Erro ao criar atividade: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png', 'gif'],
      );

      if (result != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      _showErrorDialog('Erro ao selecionar arquivo: $e');
    }
  }

  Future<String> _uploadFile() async {
    if (_selectedFilePath == null) throw Exception('Nenhum arquivo selecionado');

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$_selectedFileName';
      final ref = _storage.ref().child('activities/${widget.discipline.id}/$fileName');

      final uploadTask = await ref.putFile(File(_selectedFilePath!));
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Erro ao fazer upload: $e');
    }
  }

  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'pdf';
      case 'doc':
      case 'docx':
        return 'document';
      case 'txt':
        return 'text';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'image';
      default:
        return 'file';
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _weightController.clear();
    _maxGradeController.clear();
    _dueDate = DateTime.now().add(const Duration(days: 7));
    _selectedFilePath = null;
    _selectedFileName = null;
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showErrorDialog('Não foi possível abrir o arquivo');
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
        title: Text('Atividades - ${widget.discipline.name}'),
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
                Expanded(child: _buildActivitiesList()),
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
                'Nova Atividade',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEB2E54),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Atividade',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite o nome da atividade';
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Peso (%)',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, digite o peso';
                        }
                        final weight = double.tryParse(value);
                        if (weight == null || weight <= 0 || weight > 100) {
                          return 'Peso deve ser entre 1 e 100';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxGradeController,
                      decoration: const InputDecoration(
                        labelText: 'Nota Máxima',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, digite a nota máxima';
                        }
                        final grade = double.tryParse(value);
                        if (grade == null || grade <= 0) {
                          return 'Nota máxima deve ser maior que 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 16),
                      Text(
                        'Prazo: ${_formatDate(_dueDate)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Seção de anexo
              const Text(
                'Anexo (Opcional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A5B5),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    if (_selectedFileName == null) ...[
                      Row(
                        children: [
                          const Icon(Icons.attach_file, color: Color(0xFF00A5B5)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Nenhum arquivo selecionado',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _selectFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Selecionar Arquivo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A5B5),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Icon(
                            _getFileIcon(_getFileType(_selectedFileName!)),
                            color: const Color(0xFF00A5B5),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedFileName!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Tipo: ${_getFileType(_selectedFileName!).toUpperCase()}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedFilePath = null;
                                _selectedFileName = null;
                              });
                            },
                            icon: const Icon(Icons.close, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Formatos aceitos: PDF, DOC, DOCX, TXT, JPG, JPEG, PNG, GIF',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _createActivity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A5B5),
                        foregroundColor: Colors.white,
                      ),
                      child: _isUploading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Criando...'),
                              ],
                            )
                          : const Text('Criar Atividade'),
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

  Widget _buildActivitiesList() {
    if (_activities.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma atividade cadastrada',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Crie sua primeira atividade para começar',
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
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF00A5B5),
              child: Icon(Icons.assignment, color: Colors.white),
            ),
            title: Text(
              activity.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.description),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Chip(
                      label: Text('${(activity.weight * 100).toStringAsFixed(0)}%'),
                      backgroundColor: const Color(0xFF00A5B5).withOpacity(0.1),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('Max: ${activity.maxGrade.toStringAsFixed(1)}'),
                      backgroundColor: const Color(0xFFEB2E54).withOpacity(0.1),
                    ),
                    if (activity.hasAttachment) ...[
                      const SizedBox(width: 8),
                      Chip(
                        label: const Text('Anexo'),
                        backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                        avatar: const Icon(Icons.attach_file, size: 16),
                      ),
                    ],
                  ],
                ),
                Text('Prazo: ${_formatDate(activity.dueDate)}'),
                if (activity.hasAttachment && activity.attachmentName != null) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _launchUrl(activity.attachmentUrl!),
                    child: Row(
                      children: [
                        Icon(
                          _getFileIcon(activity.attachmentType ?? 'file'),
                          size: 16,
                          color: const Color(0xFF00A5B5),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activity.attachmentName!,
                            style: const TextStyle(
                              color: Color(0xFF00A5B5),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GradesScreen(
                    discipline: widget.discipline,
                    activity: activity,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'document':
        return Icons.description;
      case 'text':
        return Icons.text_snippet;
      case 'image':
        return Icons.image;
      default:
        return Icons.attach_file;
    }
  }
}
