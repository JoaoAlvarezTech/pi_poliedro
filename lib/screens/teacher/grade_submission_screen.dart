import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/submission_model.dart';
import '../../models/activity_model.dart';
import '../../models/discipline_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class GradeSubmissionScreen extends StatefulWidget {
  final SubmissionModel submission;
  final ActivityModel activity;
  final DisciplineModel discipline;
  final UserModel student;

  const GradeSubmissionScreen({
    super.key,
    required this.submission,
    required this.activity,
    required this.discipline,
    required this.student,
  });

  @override
  State<GradeSubmissionScreen> createState() => _GradeSubmissionScreenState();
}

class _GradeSubmissionScreenState extends State<GradeSubmissionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _gradeController = TextEditingController();
  final _commentsController = TextEditingController();
  
  bool _isLoading = false;
  double? _currentGrade;

  @override
  void initState() {
    super.initState();
    _currentGrade = widget.submission.grade;
    if (_currentGrade != null) {
      _gradeController.text = _currentGrade!.toStringAsFixed(1);
    }
    _commentsController.text = widget.submission.teacherComments ?? '';
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _saveGrade() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final grade = double.parse(_gradeController.text);
      final comments = _commentsController.text.trim().isEmpty 
          ? null 
          : _commentsController.text.trim();

      await _firestoreService.gradeSubmission(
        widget.submission.id,
        grade,
        comments,
      );

      _showSuccessDialog('Nota salva com sucesso!');
      
      // Aguardar um pouco antes de voltar
      await Future.delayed(const Duration(milliseconds: 1000));
      Navigator.of(context).pop(true); // Retorna true para indicar que foi salvo
    } catch (e) {
      _showErrorDialog('Erro ao salvar nota: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openFile() async {
    if (widget.submission.fileUrl == null) return;

    try {
      final uri = Uri.parse(widget.submission.fileUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorDialog('Não foi possível abrir o arquivo');
      }
    } catch (e) {
      _showErrorDialog('Erro ao abrir arquivo: $e');
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
        title: const Text(
          'Avaliar Entrega',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informações do aluno
              _buildStudentInfo(),
              const SizedBox(height: 20),
              
              // Informações da atividade
              _buildActivityInfo(),
              const SizedBox(height: 20),
              
              // Arquivo enviado
              _buildFileSection(),
              const SizedBox(height: 20),
              
              // Comentários do aluno
              if (widget.submission.comments != null) ...[
                _buildStudentComments(),
                const SizedBox(height: 20),
              ],
              
              // Avaliação
              _buildGradingSection(),
              const SizedBox(height: 30),
              
              // Botão salvar
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentInfo() {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.student.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'RA: ${widget.student.ra}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Email: ${widget.student.email}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityInfo() {
    return AppCard(
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
                  Icons.assignment,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
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
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.activity.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              widget.activity.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Prazo: ${_formatDate(widget.activity.dueDate)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Arquivo Enviado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.submission.fileUrl != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.successColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.attach_file,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.submission.fileName ?? 'Arquivo',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (widget.submission.fileSize != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${(widget.submission.fileSize! / 1024).toStringAsFixed(1)} KB',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AppButton(
                    text: 'Abrir',
                    icon: Icons.open_in_new,
                    onPressed: _openFile,
                    backgroundColor: AppTheme.successColor,
                    width: 100,
                    height: 40,
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.warningColor.withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: AppTheme.warningColor,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Nenhum arquivo foi enviado',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w600,
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

  Widget _buildStudentComments() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comentários do Aluno',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.infoColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              widget.submission.comments!,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradingSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Avaliação',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Campo de nota
          TextFormField(
            controller: _gradeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Nota (0.0 - ${widget.activity.maxGrade.toStringAsFixed(1)})',
              prefixIcon: const Icon(Icons.grade),
              suffixText: '/ ${widget.activity.maxGrade.toStringAsFixed(1)}',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Digite a nota';
              }
              final grade = double.tryParse(value);
              if (grade == null) {
                return 'Digite uma nota válida';
              }
              if (grade < 0 || grade > widget.activity.maxGrade) {
                return 'Nota deve estar entre 0.0 e ${widget.activity.maxGrade.toStringAsFixed(1)}';
              }
              return null;
            },
            onChanged: (value) {
              final grade = double.tryParse(value);
              setState(() {
                _currentGrade = grade;
              });
            },
          ),
          const SizedBox(height: 20),
          
          // Campo de comentários do professor
          TextFormField(
            controller: _commentsController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Comentários do Professor (Opcional)',
              prefixIcon: Icon(Icons.comment),
              hintText: 'Adicione feedback para o aluno...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: AppButton(
        text: _isLoading ? 'Salvando...' : 'Salvar Nota',
        icon: Icons.save,
        onPressed: _isLoading ? null : _saveGrade,
        isLoading: _isLoading,
        backgroundColor: AppTheme.successColor,
        height: 56,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
