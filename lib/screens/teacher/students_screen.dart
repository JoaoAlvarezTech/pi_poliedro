import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/discipline_model.dart';
import '../../models/student_discipline_model.dart';
import '../../models/user_model.dart';
import '../../models/grade_model.dart';
import 'student_detail_screen.dart';

class StudentsScreen extends StatefulWidget {
  final DisciplineModel? discipline;
  final StudentDisciplineModel? selectedStudent;

  const StudentsScreen({
    super.key,
    this.discipline,
    this.selectedStudent,
  });

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  
  List<StudentDisciplineModel> _students = [];
  List<UserModel> _allStudents = [];
  List<UserModel> _filteredStudents = [];
  bool _isLoading = true;
  bool _showEnrollForm = false;
  
  final TextEditingController _raController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _raController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      if (widget.discipline != null) {
        // Carregar alunos da disciplina
        final students = await _firestoreService.getDisciplineStudents(widget.discipline!.id);
        
        // Também carregar todos os alunos para permitir matrícula
        final allStudents = await _firestoreService.getAllStudents();
        
        setState(() {
          _students = students;
          _allStudents = allStudents;
          _filteredStudents = allStudents;
          _isLoading = false;
        });
      } else {
        // Carregar todos os alunos para matricular em disciplinas
        final allStudents = await _firestoreService.getAllStudents();
        setState(() {
          _allStudents = allStudents;
          _filteredStudents = allStudents;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Erro ao carregar dados: $e');
    }
  }

  Future<void> _enrollStudentByRA() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final ra = _raController.text.trim();
      
      // Buscar aluno pelo RA
      final student = await _firestoreService.getStudentByRA(ra);
      if (student == null) {
        _showErrorDialog('Aluno não encontrado com o RA: $ra');
        return;
      }

      if (widget.discipline != null) {
        // Verificar se já está matriculado
        final existingEnrollment = _students
            .where((s) => s.studentId == student.uid)
            .firstOrNull;
        
        if (existingEnrollment != null) {
          _showErrorDialog('Aluno já está matriculado nesta disciplina');
          return;
        }

        // Matricular aluno
        final enrollment = StudentDisciplineModel(
          id: '', // Deixar vazio para o Firestore gerar automaticamente
          studentId: student.uid,
          disciplineId: widget.discipline!.id,
          studentName: student.name,
          disciplineName: widget.discipline!.name,
          enrolledAt: DateTime.now(),
        );

        await _firestoreService.enrollStudentInDiscipline(enrollment);
        
        _raController.clear();
        setState(() {
          _showEnrollForm = false;
        });
        
        _loadData();
        _showSuccessDialog('Aluno matriculado com sucesso!');
      }
    } catch (e) {
      _showErrorDialog('Erro ao matricular aluno: $e');
    }
  }

  Future<void> _enrollStudent(UserModel student) async {
    if (widget.discipline == null) return;

    try {
      // Verificar se já está matriculado
      final existingEnrollment = _students
          .where((s) => s.studentId == student.uid)
          .firstOrNull;
      
      if (existingEnrollment != null) {
        _showErrorDialog('Aluno já está matriculado nesta disciplina');
        return;
      }

      // Matricular aluno
      final enrollment = StudentDisciplineModel(
        id: '', // Deixar vazio para o Firestore gerar automaticamente
        studentId: student.uid,
        disciplineId: widget.discipline!.id,
        studentName: student.name,
        disciplineName: widget.discipline!.name,
        enrolledAt: DateTime.now(),
      );

      await _firestoreService.enrollStudentInDiscipline(enrollment);
      
      _loadData();
      _showSuccessDialog('Aluno matriculado com sucesso!');
    } catch (e) {
      _showErrorDialog('Erro ao matricular aluno: $e');
    }
  }

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _allStudents;
      } else {
        _filteredStudents = _allStudents.where((student) {
          final name = student.name.toLowerCase();
          final ra = student.ra?.toLowerCase() ?? '';
          final email = student.email.toLowerCase();
          final searchQuery = query.toLowerCase();
          
          return name.contains(searchQuery) || 
                 ra.contains(searchQuery) || 
                 email.contains(searchQuery);
        }).toList();
      }
    });
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
        title: Text(widget.discipline != null 
            ? 'Alunos - ${widget.discipline!.name}'
            : 'Todos os Alunos'),
        actions: [
          if (widget.discipline != null)
            IconButton(
              icon: Icon(_showEnrollForm ? Icons.close : Icons.person_add),
              onPressed: () {
                setState(() {
                  _showEnrollForm = !_showEnrollForm;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_showEnrollForm && widget.discipline != null) _buildEnrollForm(),
                if (widget.discipline == null) _buildSearchBar(),
                Expanded(child: _buildStudentsList()),
              ],
            ),
    );
  }

  Widget _buildEnrollForm() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Matricular Aluno',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEB2E54),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Selecione um aluno da lista abaixo ou digite o RA:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            // Campo de busca por RA
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _raController,
                decoration: const InputDecoration(
                  labelText: 'RA do Aluno (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Digite o RA para busca rápida',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _enrollStudentByRA,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A5B5),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Matricular por RA'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showEnrollForm = false;
                      });
                    },
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Ou selecione da lista:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A5B5),
              ),
            ),
            const SizedBox(height: 8),
            // Lista de alunos para seleção
            Container(
              height: 200,
              child: _allStudents.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum aluno cadastrado',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _allStudents.length,
                      itemBuilder: (context, index) {
                        final student = _allStudents[index];
                        final isAlreadyEnrolled = _students
                            .any((s) => s.studentId == student.uid);
                        
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: isAlreadyEnrolled 
                                ? Colors.grey 
                                : const Color(0xFF00A5B5),
                            child: Icon(
                              isAlreadyEnrolled ? Icons.check : Icons.person,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            student.name,
                            style: TextStyle(
                              fontSize: 14,
                              color: isAlreadyEnrolled ? Colors.grey : null,
                            ),
                          ),
                          subtitle: Text(
                            'RA: ${student.ra ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isAlreadyEnrolled ? Colors.grey : Colors.grey[600],
                            ),
                          ),
                          trailing: isAlreadyEnrolled
                              ? const Text(
                                  'Matriculado',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.add, size: 20),
                                  onPressed: () => _enrollStudent(student),
                                ),
                          enabled: !isAlreadyEnrolled,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por nome, RA ou email...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterStudents('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: _filterStudents,
      ),
    );
  }

  Widget _buildStudentsList() {
    if (widget.discipline != null) {
      return _buildDisciplineStudents();
    } else {
      return _buildAllStudents();
    }
  }

  Widget _buildDisciplineStudents() {
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
            SizedBox(height: 8),
            Text(
              'Matricule alunos para começar',
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
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEB2E54),
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              student.studentName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Matriculado em: ${_formatDate(student.enrolledAt)}'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StudentDetailScreen(
                    discipline: widget.discipline!,
                    student: student,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAllStudents() {
    if (_allStudents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum aluno cadastrado',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredStudents.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum aluno encontrado',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tente uma busca diferente',
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
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEB2E54),
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              student.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RA: ${student.ra ?? 'N/A'}'),
                Text('Email: ${student.email}'),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Mostrar detalhes do aluno ou matricular em disciplinas
              _showStudentOptions(student);
            },
          ),
        );
      },
    );
  }

  void _showStudentOptions(UserModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RA: ${student.ra ?? 'N/A'}'),
            Text('Email: ${student.email}'),
            Text('CPF: ${student.cpf}'),
            Text('Telefone: ${student.phone}'),
            const SizedBox(height: 16),
            const Text(
              'Ações disponíveis:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Matricular em disciplinas'),
            const Text('• Ver histórico de notas'),
            const Text('• Enviar mensagem'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
