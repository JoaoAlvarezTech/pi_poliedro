import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/discipline_model.dart';
import '../../theme/app_theme.dart';
import 'student_discipline_detail_screen.dart';

class StudentDisciplinesScreen extends StatefulWidget {
  const StudentDisciplinesScreen({super.key});

  @override
  State<StudentDisciplinesScreen> createState() =>
      _StudentDisciplinesScreenState();
}

class _StudentDisciplinesScreenState extends State<StudentDisciplinesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<DisciplineModel> _disciplines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDisciplines();
  }

  Future<void> _loadDisciplines() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final disciplines =
            await _firestoreService.getStudentDisciplines(user.uid);
        setState(() {
          _disciplines = disciplines;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Erro ao carregar disciplinas: $e');
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
        title: const Text('Minhas Disciplinas'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _buildDisciplinesList(),
    );
  }

  Widget _buildDisciplinesList() {
    if (_disciplines.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma disciplina matriculada',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Entre em contato com seu professor',
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
      itemCount: _disciplines.length,
      itemBuilder: (context, index) {
        final discipline = _disciplines[index];
        return AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    StudentDisciplineDetailScreen(discipline: discipline),
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
                child: const Icon(Icons.school, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      discipline.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Código: ${discipline.code}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Prof. ${discipline.teacherName}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      discipline.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
    );
  }
}
