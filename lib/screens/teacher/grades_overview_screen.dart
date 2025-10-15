import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/discipline_model.dart';
import '../../models/activity_model.dart';
import '../../models/grade_model.dart';
import '../../models/student_discipline_model.dart';
import '../../theme/app_theme.dart';
import 'student_grades_detail_screen.dart';

class GradesOverviewScreen extends StatefulWidget {
  final DisciplineModel discipline;

  const GradesOverviewScreen({super.key, required this.discipline});

  @override
  State<GradesOverviewScreen> createState() => _GradesOverviewScreenState();
}

class _GradesOverviewScreenState extends State<GradesOverviewScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<ActivityModel> _activities = [];
  List<StudentDisciplineModel> _students = [];
  Map<String, List<GradeModel>> _studentGrades = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Carregar atividades e alunos
      final activities = await _firestoreService.getDisciplineActivities(widget.discipline.id);
      final students = await _firestoreService.getDisciplineStudents(widget.discipline.id);

      // Carregar notas de todos os alunos
      Map<String, List<GradeModel>> studentGrades = {};
      for (var student in students) {
        final grades = await _firestoreService.getStudentGrades(student.studentId, widget.discipline.id);
        studentGrades[student.studentId] = grades;
      }

      setState(() {
        _activities = activities;
        _students = students;
        _studentGrades = studentGrades;
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

  double _calculateStudentAverage(String studentId) {
    final grades = _studentGrades[studentId] ?? [];
    if (grades.isEmpty) return 0.0;

    double totalWeightedGrade = 0.0;
    double totalWeight = 0.0;

    for (var grade in grades) {
      final activity = _activities.firstWhere(
        (a) => a.id == grade.activityId,
        orElse: () => ActivityModel(
          id: '',
          disciplineId: '',
          name: '',
          description: '',
          weight: 0.0,
          maxGrade: 0.0,
          dueDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (activity.id.isNotEmpty) {
        // Normalizar a nota para 0-10 baseado na nota máxima da atividade
        final normalizedGrade = (grade.grade / activity.maxGrade) * 10;
        totalWeightedGrade += normalizedGrade * activity.weight;
        totalWeight += activity.weight;
      }
    }

    return totalWeight > 0 ? totalWeightedGrade / totalWeight : 0.0;
  }

  double _calculateClassAverage() {
    if (_students.isEmpty) return 0.0;

    double totalAverage = 0.0;
    for (var student in _students) {
      totalAverage += _calculateStudentAverage(student.studentId);
    }

    return totalAverage / _students.length;
  }

  String _getGradeStatus(double average) {
    if (average >= 7.0) return 'Aprovado';
    if (average >= 5.0) return 'Recuperação';
    return 'Reprovado';
  }

  Color _getGradeStatusColor(double average) {
    if (average >= 7.0) return Colors.green;
    if (average >= 5.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    return Column(
      children: [
        // Estatísticas gerais da turma
        _buildClassStatistics(),
        
        // Lista de alunos com suas médias
        Expanded(
          child: _buildStudentsList(),
        ),
      ],
    );
  }

  Widget _buildClassStatistics() {
    final classAverage = _calculateClassAverage();
    final totalStudents = _students.length;
    final approvedStudents = _students.where((s) => _calculateStudentAverage(s.studentId) >= 7.0).length;
    final recoveryStudents = _students.where((s) {
      final avg = _calculateStudentAverage(s.studentId);
      return avg >= 5.0 && avg < 7.0;
    }).length;
    final failedStudents = _students.where((s) => _calculateStudentAverage(s.studentId) < 5.0).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'Estatísticas da Turma',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Média Geral',
                  classAverage.toStringAsFixed(1),
                  Icons.trending_up,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Alunos',
                  totalStudents.toString(),
                  Icons.people,
                  Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Aprovados',
                  approvedStudents.toString(),
                  Icons.check_circle,
                  Colors.green.shade100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Recuperação',
                  recoveryStudents.toString(),
                  Icons.warning,
                  Colors.orange.shade100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Reprovados',
                  failedStudents.toString(),
                  Icons.cancel,
                  Colors.red.shade100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    if (_students.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum aluno matriculado',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Ordenar alunos por média (maior para menor)
    _students.sort((a, b) {
      final avgA = _calculateStudentAverage(a.studentId);
      final avgB = _calculateStudentAverage(b.studentId);
      return avgB.compareTo(avgA);
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final average = _calculateStudentAverage(student.studentId);
        final status = _getGradeStatus(average);
        final statusColor = _getGradeStatusColor(average);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => StudentGradesDetailScreen(
                    discipline: widget.discipline,
                    student: student,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar do aluno
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    student.studentName.isNotEmpty 
                        ? student.studentName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Informações do aluno
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Média: ${average.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status e nota
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: average >= 7.0 
                            ? AppTheme.accentGradient 
                            : LinearGradient(
                                colors: [statusColor, statusColor.withValues(alpha: 0.7)],
                              ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        average.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }
}
