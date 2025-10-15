import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/discipline_model.dart';
import '../../models/grade_model.dart';
import '../../models/activity_model.dart';

class StudentGradesScreen extends StatefulWidget {
  final DisciplineModel discipline;

  const StudentGradesScreen({super.key, required this.discipline});

  @override
  State<StudentGradesScreen> createState() => _StudentGradesScreenState();
}

class _StudentGradesScreenState extends State<StudentGradesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<GradeModel> _grades = [];
  List<ActivityModel> _activities = [];
  double _average = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final grades = await _firestoreService.getStudentGrades(
          user.uid,
          widget.discipline.id,
        );

        final activities = await _firestoreService.getDisciplineActivities(
          widget.discipline.id,
        );

        final average = await _firestoreService.calculateStudentAverage(
          user.uid,
          widget.discipline.id,
        );

        setState(() {
          _grades = grades;
          _activities = activities;
          _average = average;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Erro ao carregar notas: $e');
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
      backgroundColor: const Color(0xFFF7DDB8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A5B5),
        foregroundColor: Colors.white,
        title: Text('Notas - ${widget.discipline.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAverageCard(),
                  const SizedBox(height: 24),
                  _buildGradesSection(),
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
                color: Color(0xFFEB2E54),
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
            color: Color(0xFFEB2E54),
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
            Text('Prazo: ${_formatDate(activity.dueDate)}'),
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
    if (average >= 70) return Colors.green;
    if (average >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 70) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
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
