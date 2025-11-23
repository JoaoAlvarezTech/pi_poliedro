import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firestore_service.dart';
import '../../models/activity_model.dart';
import '../../models/discipline_model.dart';
import '../../models/submission_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import 'grade_submission_screen.dart';
import 'batch_grading_screen.dart';

class SubmissionsScreen extends StatefulWidget {
  final ActivityModel activity;
  final DisciplineModel discipline;

  const SubmissionsScreen({
    super.key,
    required this.activity,
    required this.discipline,
  });

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<SubmissionModel> _submissions = [];
  List<UserModel> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    try {
      final submissions =
          await _firestoreService.getActivitySubmissions(widget.activity.id);
      final studentDisciplines =
          await _firestoreService.getDisciplineStudents(widget.discipline.id);

      // Buscar dados completos dos alunos
      List<UserModel> students = [];
      for (var studentDiscipline in studentDisciplines) {
        final userData =
            await _firestoreService.getUser(studentDiscipline.studentId);
        if (userData != null) {
          students.add(UserModel.fromMap(userData));
        }
      }

      setState(() {
        _submissions = submissions;
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Erro ao carregar submissões: $e');
    }
  }

  Future<void> _gradeSubmission(SubmissionModel submission) async {
    final student = _getStudent(submission.studentId);
    if (student == null) {
      _showErrorDialog('Aluno não encontrado');
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => GradeSubmissionScreen(
          submission: submission,
          activity: widget.activity,
          discipline: widget.discipline,
          student: student,
        ),
      ),
    );

    if (result == true) {
      _loadSubmissions(); // Recarregar a lista
    }
  }

  Future<void> _openSubmissionFile(SubmissionModel submission) async {
    if (submission.fileUrl != null) {
      try {
        final Uri url = Uri.parse(submission.fileUrl!);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          _showErrorDialog('Não foi possível abrir o arquivo');
        }
      } catch (e) {
        _showErrorDialog('Erro ao abrir arquivo: $e');
      }
    }
  }

  UserModel? _getStudent(String studentId) {
    try {
      return _students.firstWhere((s) => s.uid == studentId);
    } catch (e) {
      return null;
    }
  }

  String _getStudentName(String studentId) {
    final student = _getStudent(studentId);
    return student?.name ?? 'Aluno não encontrado';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Submissões - ${widget.activity.name}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Avaliação em Lote',
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BatchGradingScreen(
                    activityId: widget.activity.id,
                  ),
                ),
              );
              if (result == true) {
                // Recarregar dados se houve alterações
                _loadSubmissions();
              }
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
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_submissions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.upload,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Nenhuma submissão encontrada',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aguardando os alunos enviarem suas tarefas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Botão de avaliação em lote
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BatchGradingScreen(
                    activityId: widget.activity.id,
                  ),
                ),
              );
              if (result == true) {
                _loadSubmissions();
              }
            },
            icon: const Icon(Icons.table_chart),
            label: const Text('Avaliação em Lote'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        // Lista de submissões
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _submissions.length,
            itemBuilder: (context, index) {
              final submission = _submissions[index];
              return _buildSubmissionCard(submission);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionCard(SubmissionModel submission) {
    final studentName = _getStudentName(submission.studentId);
    final isGraded = submission.grade != null;
    final isOverdue = submission.submittedAt.isAfter(widget.activity.dueDate);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: isGraded
                      ? AppTheme.successGradient
                      : AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  isGraded ? Icons.check_circle : Icons.upload,
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
                      studentName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enviado em: ${_formatDate(submission.submittedAt)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOverdue)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.errorColor.withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    'Atrasado',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.errorColor,
                    ),
                  ),
                ),
            ],
          ),
          if (submission.comments != null) ...[
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Comentários do Aluno:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.infoColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    submission.comments!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              if (submission.fileName != null) ...[
                Expanded(
                  child: InkWell(
                    onTap: () => _openSubmissionFile(submission),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
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
                            child: Text(
                              submission.fileName!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (isGraded) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.successGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Nota: ${submission.grade!.toStringAsFixed(1)}/${widget.activity.maxGrade.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              AppButton(
                text: isGraded ? 'Reavaliar' : 'Avaliar',
                icon: Icons.grade,
                onPressed: () => _gradeSubmission(submission),
                height: 48,
              ),
            ],
          ),
          if (isGraded && submission.teacherComments != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.secondaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Comentários do Professor:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    submission.teacherComments!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      height: 1.4,
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
