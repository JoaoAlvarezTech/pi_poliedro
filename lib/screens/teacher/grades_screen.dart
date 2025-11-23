import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/discipline_model.dart';
import '../../models/activity_model.dart';
import '../../models/grade_model.dart';
import '../../models/student_discipline_model.dart';
import 'batch_grading_screen.dart';

class GradesScreen extends StatefulWidget {
  final DisciplineModel discipline;
  final ActivityModel activity;

  const GradesScreen({
    super.key,
    required this.discipline,
    required this.activity,
  });

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<StudentDisciplineModel> _students = [];
  Map<String, GradeModel> _grades = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final students =
          await _firestoreService.getDisciplineStudents(widget.discipline.id);

      // Buscar notas existentes
      Map<String, GradeModel> grades = {};
      for (var student in students) {
        final studentGrades = await _firestoreService.getStudentGrades(
            student.studentId, widget.discipline.id);
        final grade = studentGrades
            .where((g) => g.activityId == widget.activity.id)
            .firstOrNull;
        if (grade != null) {
          grades[student.studentId] = grade;
        }
      }

      setState(() {
        _students = students;
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

  Future<void> _saveGrade(String studentId, double grade) async {
    try {
      final gradeId = '${studentId}_${widget.activity.id}';
      final gradeModel = GradeModel(
        id: gradeId,
        studentId: studentId,
        activityId: widget.activity.id,
        disciplineId: widget.discipline.id,
        grade: grade,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.setGrade(gradeModel);

      setState(() {
        _grades[studentId] = gradeModel;
      });

      _showSuccessDialog('Nota salva com sucesso!');
    } catch (e) {
      _showErrorDialog('Erro ao salvar nota: $e');
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
      backgroundColor: const Color(0xFFF7DDB8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A5B5),
        foregroundColor: Colors.white,
        title: Text('Notas - ${widget.activity.name}'),
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
                _loadData();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildActivityInfo(),
                Expanded(child: _buildGradesList()),
              ],
            ),
    );
  }

  Widget _buildActivityInfo() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.activity.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEB2E54),
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.activity.description),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(
                      'Peso: ${(widget.activity.weight * 100).toStringAsFixed(0)}%'),
                  backgroundColor: const Color(0xFF00A5B5).withOpacity(0.1),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                      'Nota máxima: ${widget.activity.maxGrade.toStringAsFixed(1)}'),
                  backgroundColor: const Color(0xFFEB2E54).withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Prazo: ${_formatDate(widget.activity.dueDate)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildGradesList() {
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final grade = _grades[student.studentId];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEB2E54),
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              student.studentName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              grade != null
                  ? 'Nota: ${grade.grade.toStringAsFixed(1)}'
                  : 'Sem nota',
            ),
            trailing: SizedBox(
              width: 100,
              child: TextFormField(
                initialValue: grade?.grade.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nota',
                  border: const OutlineInputBorder(),
                  suffixText: '/${widget.activity.maxGrade.toStringAsFixed(0)}',
                ),
                onFieldSubmitted: (value) {
                  final gradeValue = double.tryParse(value);
                  if (gradeValue != null &&
                      gradeValue >= 0 &&
                      gradeValue <= widget.activity.maxGrade) {
                    _saveGrade(student.studentId, gradeValue);
                  } else {
                    _showErrorDialog(
                        'Nota deve estar entre 0 e ${widget.activity.maxGrade}');
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
