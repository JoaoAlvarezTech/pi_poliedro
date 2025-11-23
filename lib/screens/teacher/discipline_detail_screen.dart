import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/discipline_model.dart';
import '../../models/activity_model.dart';
import '../../models/material_model.dart';
import '../../models/student_discipline_model.dart';
import '../../theme/app_theme.dart';
import 'activities_screen.dart';
import 'materials_screen.dart';
import 'students_screen.dart';
import 'submissions_screen.dart';
import 'student_detail_screen.dart';
import 'grades_overview_screen.dart';

class DisciplineDetailScreen extends StatefulWidget {
  final DisciplineModel discipline;

  const DisciplineDetailScreen({super.key, required this.discipline});

  @override
  State<DisciplineDetailScreen> createState() => _DisciplineDetailScreenState();
}

class _DisciplineDetailScreenState extends State<DisciplineDetailScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;

  List<ActivityModel> _activities = [];
  List<MaterialModel> _materials = [];
  List<StudentDisciplineModel> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDisciplineData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDisciplineData() async {
    try {
      final activities =
          await _firestoreService.getDisciplineActivities(widget.discipline.id);
      final materials =
          await _firestoreService.getDisciplineMaterials(widget.discipline.id);
      final students =
          await _firestoreService.getDisciplineStudents(widget.discipline.id);

      setState(() {
        _activities = activities;
        _materials = materials;
        _students = students;
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
            Tab(icon: Icon(Icons.people), text: 'Alunos'),
            Tab(icon: Icon(Icons.analytics), text: 'Médias'),
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
                _buildStudentsTab(),
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
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ActivitiesScreen(
                        discipline: widget.discipline,
                        showCreateForm: true,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Nova Atividade'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
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
                        'Nenhuma atividade cadastrada',
                        style: TextStyle(
                          fontSize: 16,
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
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          MaterialsScreen(discipline: widget.discipline),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Novo Material'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
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
                        'Nenhum material cadastrado',
                        style: TextStyle(
                          fontSize: 16,
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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getMaterialColor(material.type),
                          child: Icon(_getMaterialIcon(material.type),
                              color: Colors.white),
                        ),
                        title: Text(
                          material.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(material.description),
                            Text(
                                'Tipo: ${_getMaterialTypeName(material.type)}'),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MaterialsScreen(
                                discipline: widget.discipline,
                                selectedMaterial: material,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStudentsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alunos (${_students.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StudentsScreen(
                        discipline: widget.discipline,
                        openEnrollForm: true,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Matricular Aluno'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _students.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum aluno matriculado',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          student.studentName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                            'Matriculado em: ${_formatDate(student.enrolledAt)}'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StudentDetailScreen(
                                discipline: widget.discipline,
                                student: student,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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

  Widget _buildGradesTab() {
    return GradesOverviewScreen(discipline: widget.discipline);
  }
}
