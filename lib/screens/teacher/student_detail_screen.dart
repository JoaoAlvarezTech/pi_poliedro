import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/discipline_model.dart';
import '../../models/student_discipline_model.dart';
import '../../models/grade_model.dart';
import '../../models/activity_model.dart';
import 'send_message_screen.dart';
import '../../theme/app_theme.dart';

class StudentDetailScreen extends StatefulWidget {
  final DisciplineModel discipline;
  final StudentDisciplineModel student;

  const StudentDetailScreen({
    super.key,
    required this.discipline,
    required this.student,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<GradeModel> _grades = [];
  List<ActivityModel> _activities = [];
  double _average = 0.0;
  bool _isLoading = true;
  bool _isUnenrolling = false;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final grades = await _firestoreService.getStudentGrades(
        widget.student.studentId,
        widget.discipline.id,
      );

      final activities = await _firestoreService.getDisciplineActivities(
        widget.discipline.id,
      );

      final average = await _firestoreService.calculateStudentAverage(
        widget.student.studentId,
        widget.discipline.id,
      );

      setState(() {
        _grades = grades;
        _activities = activities;
        _average = average;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Erro ao carregar dados: $e');
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

  void _showUnenrollDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desmatricular Aluno'),
        content: Text(
          'Tem certeza que deseja desmatricular ${widget.student.studentName} da disciplina ${widget.discipline.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: _isUnenrolling
                ? null
                : () {
              Navigator.of(context).pop();
              _unenrollStudent();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Desmatricular'),
          ),
        ],
      ),
    );
  }

  Future<void> _unenrollStudent() async {
    try {
      setState(() {
        _isUnenrolling = true;
      });
      await _firestoreService.unenrollStudentFromDiscipline(
        widget.student.studentId,
        widget.discipline.id,
      );

      // Voltar para a tela anterior após desmatricular
      Navigator.of(context).pop();

      // Mostrar mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${widget.student.studentName} foi desmatriculado com sucesso!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      _showErrorDialog('Erro ao desmatricular aluno: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUnenrolling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(widget.student.studentName),
        actions: [
          if (_isUnenrolling)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.person_remove),
              tooltip: 'Desmatricular',
              onPressed: () => _showUnenrollDialog(),
            ),
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SendMessageScreen(
                    student: widget.student,
                    discipline: widget.discipline,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStudentInfo(),
                  const SizedBox(height: 24),
                  _buildAverageCard(),
                  const SizedBox(height: 24),
                  _buildGradesSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildStudentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações do Aluno',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.student.studentName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Disciplina: ${widget.discipline.name}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        'Matriculado em: ${_formatDate(widget.student.enrolledAt)}',
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
          ],
        ),
      ),
    );
  }

  Widget _buildAverageCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Média Final',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getAverageColor(_average).withOpacity(0.1),
                border: Border.all(
                  color: _getAverageColor(_average),
                  width: 4,
                ),
              ),
              child: Center(
                child: Text(
                  _average.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _getAverageColor(_average),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getAverageStatus(_average),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getAverageColor(_average),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notas por Atividade',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        if (_grades.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.assignment, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Nenhuma nota registrada',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ..._grades.map((grade) => _buildGradeCard(grade)),
      ],
    );
  }

  Widget _buildGradeCard(GradeModel grade) {
    final activity =
        _activities.where((a) => a.id == grade.activityId).firstOrNull;

    if (activity == null) return const SizedBox.shrink();

    final percentage = (grade.grade / activity.maxGrade) * 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getGradeColor(percentage),
          child: Text(
            grade.grade.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          activity.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Peso: ${(activity.weight * 100).toStringAsFixed(0)}%'),
            Text('Nota máxima: ${activity.maxGrade.toStringAsFixed(1)}'),
            if (grade.comments != null) Text('Comentário: ${grade.comments}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getGradeColor(percentage),
              ),
            ),
            Text(
              _getGradeStatus(percentage),
              style: TextStyle(
                fontSize: 12,
                color: _getGradeColor(percentage),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAverageColor(double average) {
    if (average >= 70) return AppTheme.successColor;
    if (average >= 50) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 70) return AppTheme.successColor;
    if (percentage >= 50) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _getAverageStatus(double average) {
    if (average >= 70) return 'Aprovado';
    if (average >= 50) return 'Recuperação';
    return 'Reprovado';
  }

  String _getGradeStatus(double percentage) {
    if (percentage >= 70) return 'Bom';
    if (percentage >= 50) return 'Regular';
    return 'Ruim';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
