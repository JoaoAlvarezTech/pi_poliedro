import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/firestore_service.dart';
import '../../models/activity_model.dart';
import '../../models/discipline_model.dart';
import '../../models/submission_model.dart';
import '../../theme/app_theme.dart';

class SubmissionScreen extends StatefulWidget {
  final ActivityModel activity;
  final DisciplineModel discipline;
  final String studentId;

  const SubmissionScreen({
    super.key,
    required this.activity,
    required this.discipline,
    required this.studentId,
  });

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  SubmissionModel? _existingSubmission;
  
  // Variáveis para arquivo
  String? _selectedFile;
  String? _fileName;
  Uint8List? _selectedFileBytes;

  @override
  void initState() {
    super.initState();
    _loadExistingSubmission();
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingSubmission() async {
    try {
      print('DEBUG - Carregando submissão existente para aluno: ${widget.studentId}');
      print('DEBUG - Atividade ID: ${widget.activity.id}');
      
      final submission = await _firestoreService.getStudentActivitySubmission(
        widget.studentId,
        widget.activity.id,
      );
      
      print('DEBUG - Submissão encontrada: ${submission != null}');
      if (submission != null) {
        print('DEBUG - Status da submissão: ${submission.status}');
        print('DEBUG - Arquivo: ${submission.fileName}');
      }
      
      setState(() {
        _existingSubmission = submission;
        _isLoading = false;
      });
      
      if (submission != null) {
        _commentsController.text = submission.comments ?? '';
      }
    } catch (e) {
      print('DEBUG - Erro ao carregar submissão: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Erro ao carregar submissão: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      print('DEBUG - Iniciando seleção de arquivo');
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png', 'gif'],
      );

      if (result != null) {
        print('DEBUG - Arquivo selecionado: ${result.files.single.name}');
        print('DEBUG - Tamanho do arquivo: ${result.files.single.size} bytes');
        print('DEBUG - Plataforma: ${kIsWeb ? 'Web' : 'Mobile/Desktop'}');
        
        setState(() {
          _fileName = result.files.single.name;
          if (kIsWeb) {
            // Para web, usar bytes
            _selectedFileBytes = result.files.single.bytes;
            _selectedFile = null;
            print('DEBUG - Arquivo configurado para web (bytes)');
          } else {
            // Para mobile/desktop, usar path
            _selectedFile = result.files.single.path;
            _selectedFileBytes = null;
            print('DEBUG - Arquivo configurado para mobile/desktop (path: $_selectedFile)');
          }
        });
      } else {
        print('DEBUG - Nenhum arquivo selecionado');
      }
    } catch (e) {
      print('DEBUG - Erro ao selecionar arquivo: $e');
      _showErrorDialog('Erro ao selecionar arquivo: $e');
    }
  }

  Future<String> _uploadFile() async {
    if (_selectedFile == null && _selectedFileBytes == null) {
      throw Exception('Nenhum arquivo selecionado');
    }

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$_fileName';
      final ref = _storage.ref().child('submissions/${widget.activity.id}/${widget.studentId}/$fileName');
      
      print('DEBUG - Iniciando upload do arquivo: $fileName');
      print('DEBUG - Caminho no storage: submissions/${widget.activity.id}/${widget.studentId}/$fileName');

      UploadTask uploadTask;
      if (kIsWeb && _selectedFileBytes != null) {
        // Para web, usar bytes
        print('DEBUG - Upload para web usando bytes');
        uploadTask = ref.putData(_selectedFileBytes!);
      } else if (_selectedFile != null) {
        // Para mobile/desktop, usar File
        print('DEBUG - Upload para mobile/desktop usando File');
        uploadTask = ref.putFile(File(_selectedFile!));
      } else {
        throw Exception('Arquivo não encontrado');
      }

      print('DEBUG - Aguardando conclusão do upload...');
      final snapshot = await uploadTask;
      print('DEBUG - Upload concluído, obtendo URL de download...');
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('DEBUG - URL de download obtida: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('DEBUG - Erro no upload: $e');
      throw Exception('Erro ao fazer upload: $e');
    }
  }

  Future<void> _submitAssignment() async {
    print('DEBUG - Iniciando envio de tarefa');
    print('DEBUG - Arquivo selecionado: ${_selectedFile != null || _selectedFileBytes != null}');
    print('DEBUG - Submissão existente: ${_existingSubmission != null}');
    print('DEBUG - Nome do arquivo: $_fileName');
    
    // Validar se há arquivo selecionado ou submissão existente
    if (_selectedFile == null && _selectedFileBytes == null && _existingSubmission == null) {
      print('DEBUG - Nenhum arquivo selecionado e nenhuma submissão existente');
      _showErrorDialog('Por favor, selecione um arquivo para enviar');
      return;
    }

    try {
      print('DEBUG - Iniciando processo de envio...');
      setState(() {
        _isSubmitting = true;
      });

      String? fileUrl;
      String? fileName;
      int? fileSize;

      // Se há um novo arquivo selecionado, fazer upload
      if (_selectedFile != null || _selectedFileBytes != null) {
        print('DEBUG - Fazendo upload de novo arquivo...');
        fileUrl = await _uploadFile();
        fileName = _fileName;
        // Calcular o tamanho do arquivo se necessário
        if (_selectedFileBytes != null) {
          fileSize = _selectedFileBytes!.length;
        }
        print('DEBUG - Upload concluído. URL: $fileUrl, Nome: $fileName, Tamanho: $fileSize');
      } else if (_existingSubmission != null) {
        // Usar dados da submissão existente
        print('DEBUG - Usando dados da submissão existente...');
        fileUrl = _existingSubmission!.fileUrl;
        fileName = _existingSubmission!.fileName;
        fileSize = _existingSubmission!.fileSize;
        print('DEBUG - Dados da submissão existente - URL: $fileUrl, Nome: $fileName, Tamanho: $fileSize');
      }

      print('DEBUG - Criando objeto SubmissionModel...');
      final submission = SubmissionModel(
        id: _existingSubmission?.id ?? '', // Será gerado automaticamente pelo Firestore se vazio
        activityId: widget.activity.id,
        studentId: widget.studentId,
        disciplineId: widget.discipline.id,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize,
        comments: _commentsController.text.trim().isEmpty ? null : _commentsController.text.trim(),
        submittedAt: _existingSubmission?.submittedAt ?? DateTime.now(),
        status: 'submitted',
      );

      print('DEBUG - SubmissionModel criado. ID: ${submission.id}');
      print('DEBUG - ActivityId: ${submission.activityId}');
      print('DEBUG - StudentId: ${submission.studentId}');
      print('DEBUG - DisciplineId: ${submission.disciplineId}');

      if (_existingSubmission != null) {
        // Atualizar submissão existente
        print('DEBUG - Atualizando submissão existente...');
        await _firestoreService.updateSubmission(submission);
        _showSuccessDialog('Submissão atualizada com sucesso!');
      } else {
        // Criar nova submissão
        print('DEBUG - Criando nova submissão...');
        await _firestoreService.createSubmission(submission);
        _showSuccessDialog('Tarefa enviada com sucesso!');
      }

      // Aguardar um pouco antes de fechar para o usuário ver a mensagem de sucesso
      print('DEBUG - Aguardando antes de fechar a tela...');
      await Future.delayed(const Duration(milliseconds: 500));
      print('DEBUG - Fechando tela de submissão...');
      Navigator.of(context).pop();
    } catch (e) {
      print('DEBUG - Erro ao enviar tarefa: $e');
      _showErrorDialog('Erro ao enviar tarefa: $e');
    } finally {
      print('DEBUG - Finalizando processo de envio...');
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    print('DEBUG - Mostrando diálogo de erro: $message');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              print('DEBUG - Fechando diálogo de erro');
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    print('DEBUG - Mostrando diálogo de sucesso: $message');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sucesso'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              print('DEBUG - Fechando diálogo de sucesso');
              Navigator.of(context).pop();
            },
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
        title: Text(
          'Enviar Tarefa - ${widget.activity.name}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações da atividade
            _buildActivityInfo(),
            const SizedBox(height: 24),
            
            // Status da submissão
            if (_existingSubmission != null) _buildSubmissionStatus(),
            if (_existingSubmission != null) const SizedBox(height: 24),
            
            // Seleção de arquivo
            _buildFileSelection(),
            const SizedBox(height: 24),
            
            // Comentários
            _buildCommentsSection(),
            const SizedBox(height: 32),
            
            // Botão de envio
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityInfo() {
    final isOverdue = DateTime.now().isAfter(widget.activity.dueDate);
    final daysUntilDue = widget.activity.dueDate.difference(DateTime.now()).inDays;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.assignment,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.activity.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Peso: ${(widget.activity.weight * 100).toStringAsFixed(0)}% • Nota máxima: ${widget.activity.maxGrade.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(isOverdue, daysUntilDue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(isOverdue, daysUntilDue),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(isOverdue, daysUntilDue),
                  ),
                ),
              ),
            ],
          ),
          if (widget.activity.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.activity.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                'Prazo: ${_formatDate(widget.activity.dueDate)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _existingSubmission!.status == 'graded' 
            ? Colors.green.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _existingSubmission!.status == 'graded' 
              ? Colors.green
              : Colors.blue,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _existingSubmission!.status == 'graded' 
                ? Icons.check_circle
                : Icons.upload,
            color: _existingSubmission!.status == 'graded' 
                ? Colors.green
                : Colors.blue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _existingSubmission!.status == 'graded' 
                      ? 'Tarefa Avaliada'
                      : 'Tarefa Enviada',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _existingSubmission!.status == 'graded' 
                        ? Colors.green
                        : Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enviado em: ${_formatDate(_existingSubmission!.submittedAt)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (_existingSubmission!.grade != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Nota: ${_existingSubmission!.grade!.toStringAsFixed(1)}/${widget.activity.maxGrade.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Arquivo da Tarefa',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedFile != null || _selectedFileBytes != null || _existingSubmission != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fileName ?? _existingSubmission?.fileName ?? 'Arquivo selecionado',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  if (_selectedFile != null || _selectedFileBytes != null)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedFile = null;
                          _selectedFileBytes = null;
                          _fileName = null;
                        });
                      },
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.upload_file,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Selecione um arquivo para enviar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Formatos aceitos: PDF, DOC, DOCX, TXT, JPG, PNG, GIF',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Selecionar Arquivo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comentários (Opcional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _commentsController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Adicione comentários sobre sua tarefa...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : () {
          print('DEBUG - Botão de envio pressionado');
          print('DEBUG - Estado atual: _isSubmitting = $_isSubmitting');
          print('DEBUG - Arquivo selecionado: ${_selectedFile != null || _selectedFileBytes != null}');
          print('DEBUG - Submissão existente: ${_existingSubmission != null}');
          print('DEBUG - Nome do arquivo: $_fileName');
          print('DEBUG - Comentários: ${_commentsController.text}');
          print('DEBUG - Activity ID: ${widget.activity.id}');
          print('DEBUG - Student ID: ${widget.studentId}');
          print('DEBUG - Discipline ID: ${widget.discipline.id}');
          _submitAssignment();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
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
                  SizedBox(width: 12),
                  Text('Enviando...'),
                ],
              )
            : Text(
                _existingSubmission != null ? 'Atualizar Submissão' : 'Enviar Tarefa',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Color _getStatusColor(bool isOverdue, int daysUntilDue) {
    if (isOverdue) return Colors.red;
    if (daysUntilDue <= 1) return Colors.orange;
    if (daysUntilDue <= 3) return Colors.amber;
    return Colors.green;
  }

  String _getStatusText(bool isOverdue, int daysUntilDue) {
    if (isOverdue) return 'Vencida';
    if (daysUntilDue == 0) return 'Hoje';
    if (daysUntilDue == 1) return '1 dia';
    if (daysUntilDue <= 3) return '$daysUntilDue dias';
    return 'Em dia';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Hoje às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference == 1) {
      return 'Amanhã às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference == -1) {
      return 'Ontem às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference > 0) {
      return '${date.day}/${date.month}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}
