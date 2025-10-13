import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/discipline_model.dart';
import 'materials_screen.dart';
import 'grades_screen.dart';

class StudentDisciplinesScreen extends StatefulWidget {
  const StudentDisciplinesScreen({super.key});

  @override
  State<StudentDisciplinesScreen> createState() => _StudentDisciplinesScreenState();
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
        final disciplines = await _firestoreService.getStudentDisciplines(user.uid);
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
      backgroundColor: const Color(0xFFF7DDB8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A5B5),
        foregroundColor: Colors.white,
        title: const Text('Minhas Disciplinas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF00A5B5),
              child: Icon(Icons.school, color: Colors.white),
            ),
            title: Text(
              discipline.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Código: ${discipline.code}'),
                Text('Prof. ${discipline.teacherName}'),
                Text(discipline.description),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showDisciplineOptions(discipline);
            },
          ),
        );
      },
    );
  }

  void _showDisciplineOptions(DisciplineModel discipline) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              discipline.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEB2E54),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.assignment, color: Color(0xFF00A5B5)),
              title: const Text('Ver Notas'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StudentGradesScreen(discipline: discipline),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Color(0xFF00A5B5)),
              title: const Text('Ver Materiais'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StudentMaterialsScreen(discipline: discipline),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }
}
