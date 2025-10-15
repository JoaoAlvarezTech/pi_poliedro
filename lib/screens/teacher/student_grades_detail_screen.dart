import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/discipline_model.dart';
import '../../models/activity_model.dart';
import '../../models/grade_model.dart';
import '../../models/student_discipline_model.dart';
import '../../theme/app_theme.dart';

class StudentGradesDetailScreen extends StatefulWidget {
  final DisciplineModel discipline;
  final StudentDisciplineModel student;

  const StudentGradesDetailScreen({
    super.key,
    required this.discipline,
    required this.student,
  });

  @override
  State<StudentGradesDetailScreen> createState() => _StudentGradesDetailScreenState();
}

class _StudentGradesDetailScreenState extends State<StudentGradesDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<ActivityModel> _activities = [];
  List<GradeModel> _grades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Carregar atividades da disciplina
      final activities = await _firestoreService.getDisciplineActivities(widget.discipline.id);
      
      // Carregar notas do aluno
      final grades = await _firestoreService.getStudentGrades(widget.student.studentId, widget.discipline.id);

      setState(() {
        _activities = activities;
        _grades = grades;
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

  double _calculateStudentAverage() {
    if (_grades.isEmpty) return 0.0;

    double totalWeightedGrade = 0.0;
    double totalWeight = 0.0;

    for (var grade in _grades) {
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

  GradeModel? _getGradeForActivity(String activityId) {
    return _grades.firstWhere(
      (g) => g.activityId == activityId,
      orElse: () => GradeModel(
        id: '',
        studentId: '',
        activityId: '',
        disciplineId: '',
        grade: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          title: Text('Notas - ${widget.student.studentName}'),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      );
    }

    final average = _calculateStudentAverage();
    final status = _getGradeStatus(average);
    final statusColor = _getGradeStatusColor(average);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text('Notas - ${widget.student.studentName}'),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Header com informações do aluno
          _buildStudentHeader(average, status, statusColor),
          
          // Estatísticas das notas
          _buildGradeStatistics(),
          
          // Lista de atividades e notas
          _buildActivitiesList(),
        ],
      ),
    );
  }

  Widget _buildStudentHeader(double average, String status, Color statusColor) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            // Avatar do aluno
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Text(
                widget.student.studentName.isNotEmpty 
                    ? widget.student.studentName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
            ),
            const SizedBox(width: 20),
            
            // Informações do aluno
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.student.studentName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.discipline.name,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Média: ${average.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeStatistics() {
    final totalActivities = _activities.length;
    final gradedActivities = _grades.length;
    final pendingActivities = totalActivities - gradedActivities;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estatísticas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Atividades',
                    totalActivities.toString(),
                    Icons.assignment,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Avaliadas',
                    gradedActivities.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Pendentes',
                    pendingActivities.toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActivitiesList() {
    if (_activities.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
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
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final activity = _activities[index];
          final grade = _getGradeForActivity(activity.id);
          final hasGrade = grade != null && grade.id.isNotEmpty;
          final normalizedGrade = hasGrade ? (grade.grade / activity.maxGrade) * 10 : 0.0;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho da atividade
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: hasGrade 
                                ? (normalizedGrade >= 7.0 
                                    ? AppTheme.accentGradient 
                                    : LinearGradient(
                                        colors: [
                                          normalizedGrade >= 5.0 ? Colors.orange : Colors.red,
                                          (normalizedGrade >= 5.0 ? Colors.orange : Colors.red).withValues(alpha: 0.7)
                                        ],
                                      ))
                                : LinearGradient(
                                    colors: [Colors.grey, Colors.grey.withValues(alpha: 0.7)],
                                  ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            hasGrade ? Icons.assignment_turned_in : Icons.assignment,
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
                                activity.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Peso: ${(activity.weight * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Prazo: ${_formatDate(activity.dueDate)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Nota
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (hasGrade) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: normalizedGrade >= 7.0 
                                      ? AppTheme.accentGradient 
                                      : LinearGradient(
                                          colors: [
                                            normalizedGrade >= 5.0 ? Colors.orange : Colors.red,
                                            (normalizedGrade >= 5.0 ? Colors.orange : Colors.red).withValues(alpha: 0.7)
                                          ],
                                        ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  normalizedGrade.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${grade.grade.toStringAsFixed(1)}/${activity.maxGrade.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                                ),
                                child: const Text(
                                  'Pendente',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    
                    // Descrição da atividade
                    if (activity.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        activity.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
        childCount: _activities.length,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
