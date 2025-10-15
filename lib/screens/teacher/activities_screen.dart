import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../services/firestore_service.dart';
import '../../models/discipline_model.dart';
import '../../models/activity_model.dart';
import '../../theme/app_theme.dart';
import 'submissions_screen.dart';

class ActivitiesScreen extends StatefulWidget {
  final DisciplineModel discipline;
  final ActivityModel? selectedActivity;
  final bool showCreateForm;

  const ActivitiesScreen({
    super.key,
    required this.discipline,
    this.selectedActivity,
    this.showCreateForm = false,
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
  Uint8List? _selectedFileBytes;

  @override
  void initState() {
    super.initState();
    _showCreateForm = widget.showCreateForm;
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
      final activities =
          await _firestoreService.getDisciplineActivities(widget.discipline.id);
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

      if (_selectedFilePath != null || _selectedFileBytes != null) {
        attachmentUrl = await _uploadFile();
        attachmentName = _selectedFileName;
        attachmentType = _getFileType(_selectedFileName!);
      }

      final activity = ActivityModel(
        id: '', // Será gerado pelo Firestore
        disciplineId: widget.discipline.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        weight: double.parse(_weightController.text) /
            100, // Converter para decimal
        maxGrade: double.parse(_maxGradeController.text),
        dueDate: _dueDate,
        hasAttachment: _selectedFilePath != null || _selectedFileBytes != null,
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
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'txt',
          'jpg',
          'jpeg',
          'png',
          'gif'
        ],
      );

      if (result != null) {
        setState(() {
          _selectedFileName = result.files.single.name;
          if (kIsWeb) {
            // Para web, usar bytes
            _selectedFileBytes = result.files.single.bytes;
            _selectedFilePath = null;
          } else {
            // Para mobile/desktop, usar path
            _selectedFilePath = result.files.single.path;
            _selectedFileBytes = null;
          }
        });
      }
    } catch (e) {
      _showErrorDialog('Erro ao selecionar arquivo: $e');
    }
  }

  Future<String> _uploadFile() async {
    if (_selectedFilePath == null && _selectedFileBytes == null) {
      throw Exception('Nenhum arquivo selecionado');
    }

    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$_selectedFileName';
      final ref =
          _storage.ref().child('activities/${widget.discipline.id}/$fileName');

      UploadTask uploadTask;
      if (kIsWeb && _selectedFileBytes != null) {
        // Para web, usar bytes
        uploadTask = ref.putData(_selectedFileBytes!);
      } else if (_selectedFilePath != null) {
        // Para mobile/desktop, usar File
        uploadTask = ref.putFile(File(_selectedFilePath!));
      } else {
        throw Exception('Arquivo não encontrado');
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

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
    _selectedFileBytes = null;
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Atividades - ${widget.discipline.name}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
          ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : Column(
              children: [
                if (_showCreateForm) _buildCreateForm(),
                Expanded(child: _buildActivitiesList()),
              ],
            ),
    );
  }

  Widget _buildCreateForm() {
    return AppCard(
      margin: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.secondaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Nova Atividade',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Atividade',
                prefixIcon: Icon(Icons.assignment),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, digite o nome da atividade';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                prefixIcon: Icon(Icons.description),
                hintText: 'Descreva a atividade...',
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
                  if (_selectedFileName == null ||
                      (_selectedFilePath == null &&
                          _selectedFileBytes == null)) ...[
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
                              _selectedFileBytes = null;
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
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
        return AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SubmissionsScreen(
                  activity: activity,
                  discipline: widget.discipline,
                ),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.assignment, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(activity.weight * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Max: ${activity.maxGrade.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (activity.hasAttachment) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.attach_file,
                                    size: 12, color: AppTheme.successColor),
                                SizedBox(width: 4),
                                Text(
                                  'Anexo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.successColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Prazo: ${_formatDate(activity.dueDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (activity.hasAttachment &&
                        activity.attachmentName != null) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _launchUrl(activity.attachmentUrl!),
                        child: Row(
                          children: [
                            Icon(
                              _getFileIcon(activity.attachmentType ?? 'file'),
                              size: 16,
                              color: AppTheme.accentColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                activity.attachmentName!,
                                style: const TextStyle(
                                  color: AppTheme.accentColor,
                                  decoration: TextDecoration.underline,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondary,
                size: 16,
              ),
            ],
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
