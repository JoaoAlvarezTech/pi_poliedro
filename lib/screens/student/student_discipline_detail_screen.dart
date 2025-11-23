import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/discipline_model.dart';
import '../../models/activity_model.dart';
import '../../models/material_model.dart';
import '../../models/grade_model.dart';
import '../../theme/app_theme.dart';
import 'materials_screen.dart';
import 'submission_screen.dart';

class StudentDisciplineDetailScreen extends StatefulWidget {
  final DisciplineModel discipline;

  const StudentDisciplineDetailScreen({super.key, required this.discipline});

  @override
  State<StudentDisciplineDetailScreen> createState() =>
      _StudentDisciplineDetailScreenState();
}

class _StudentDisciplineDetailScreenState
    extends State<StudentDisciplineDetailScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;

  List<ActivityModel> _activities = [];
  List<MaterialModel> _materials = [];
  List<GradeModel> _grades = [];
  double _average = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDisciplineData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDisciplineData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final activities =
          await _firestoreService.getDisciplineActivities(widget.discipline.id);
      final materials =
          await _firestoreService.getDisciplineMaterials(widget.discipline.id);
      final grades = await _firestoreService.getStudentGrades(
          user.uid, widget.discipline.id);
      final average = await _firestoreService.calculateStudentAverage(
          user.uid, widget.discipline.id);

      setState(() {
        _activities = activities;
        _materials = materials;
        _grades = grades;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.discipline.name),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: 'Atividades'),
            Tab(icon: Icon(Icons.folder), text: 'Materiais'),
            Tab(icon: Icon(Icons.grade), text: 'Notas'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActivitiesTab(),
                _buildMaterialsTab(),
                _buildGradesTab(),
              ],
            ),
    );
  }

  Widget _buildActivitiesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Atividades (${_activities.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _activities.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nenhuma atividade disponível',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _activities.length,
                  itemBuilder: (context, index) {
                    final activity = _activities[index];
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      onTap: () {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SubmissionScreen(
                                activity: activity,
                                discipline: widget.discipline,
                                studentId: user.uid,
                              ),
                            ),
                          );
                        }
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
                            child: const Icon(Icons.assignment,
                                color: Colors.white),
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
                                  'Peso: ${(activity.weight * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Nota máxima: ${activity.maxGrade.toStringAsFixed(1)}',
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
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: AppTheme.textSecondary,
                            size: 16,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMaterialsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Materiais (${_materials.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _materials.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum material disponível',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _materials.length,
                  itemBuilder: (context, index) {
                    final material = _materials[index];
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StudentMaterialsScreen(
                                discipline: widget.discipline),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:
                                const Icon(Icons.folder, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  material.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  material.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Criado em: ${_formatDate(material.createdAt)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
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
                ),
        ),
      ],
    );
  }

  Widget _buildGradesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card de média geral
          _buildAverageCard(),
          const SizedBox(height: 20),

          // Estatísticas rápidas
          _buildStatsCards(),
          const SizedBox(height: 20),

          // Lista de notas
          _buildGradesList(),
        ],
      ),
    );
  }

  Widget _buildAverageCard() {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: _getAverageGradient(),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.grade,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Média Geral',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _average.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: _getAverageColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getAverageStatus(),
                      style: TextStyle(
                        fontSize: 14,
                        color: _getAverageColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalActivities = _activities.length;
    final gradedActivities = _grades.length;
    final pendingActivities = totalActivities - gradedActivities;

    return Row(
      children: [
        Expanded(
          child: AppCard(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppTheme.successColor,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$gradedActivities',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Avaliadas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppCard(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pending,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$pendingActivities',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pendentes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppCard(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment,
                    color: AppTheme.accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalActivities',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradesList() {
    if (_grades.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.grade,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Nenhuma nota disponível',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Suas notas aparecerão aqui conforme forem avaliadas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notas por Atividade',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ..._grades.map((grade) {
          final activity = _activities.firstWhere(
            (a) => a.id == grade.activityId,
            orElse: () => ActivityModel(
              id: '',
              disciplineId: '',
              name: 'Atividade não encontrada',
              description: '',
              weight: 0.0,
              maxGrade: 0.0,
              dueDate: DateTime.now(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          return AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: _getGradeGradient(grade.grade, activity.maxGrade),
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
                      Row(
                        children: [
                          Text(
                            'Nota: ${grade.grade.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: _getGradeColor(
                                  grade.grade, activity.maxGrade),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '/ ${activity.maxGrade.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Peso: ${(activity.weight * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (grade.comments != null &&
                          grade.comments!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            grade.comments!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  LinearGradient _getAverageGradient() {
    if (_average >= 7.0) {
      return AppTheme.successGradient;
    } else if (_average >= 5.0) {
      return AppTheme.warningGradient;
    } else {
      return const LinearGradient(
        colors: [AppTheme.errorColor, AppTheme.errorColor],
      );
    }
  }

  Color _getAverageColor() {
    if (_average >= 7.0) {
      return AppTheme.successColor;
    } else if (_average >= 5.0) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.errorColor;
    }
  }

  String _getAverageStatus() {
    if (_average >= 7.0) {
      return 'Aprovado';
    } else if (_average >= 5.0) {
      return 'Recuperação';
    } else {
      return 'Reprovado';
    }
  }

  LinearGradient _getGradeGradient(double grade, double maxGrade) {
    final percentage = grade / maxGrade;
    if (percentage >= 0.7) {
      return AppTheme.successGradient;
    } else if (percentage >= 0.5) {
      return AppTheme.warningGradient;
    } else {
      return const LinearGradient(
        colors: [AppTheme.errorColor, AppTheme.errorColor],
      );
    }
  }

  Color _getGradeColor(double grade, double maxGrade) {
    final percentage = grade / maxGrade;
    if (percentage >= 0.7) {
      return AppTheme.successColor;
    } else if (percentage >= 0.5) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.errorColor;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
