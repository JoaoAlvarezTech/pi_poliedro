import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';

class SelectStudentScreen extends StatefulWidget {
  const SelectStudentScreen({super.key});

  @override
  State<SelectStudentScreen> createState() => _SelectStudentScreenState();
}

class _SelectStudentScreenState extends State<SelectStudentScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<UserModel> _enrolledStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnrolledStudents();
  }

  Future<void> _loadEnrolledStudents() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showErrorDialog('Usuário não autenticado.');
        return;
      }

      // Verificar se o usuário é um professor
      final userData = await _firestoreService.getUser(user.uid);
      if (userData == null) {
        _showErrorDialog('Dados do usuário atual não encontrados.');
        return;
      }
      
      final currentUser = UserModel.fromMap(userData);
      if (currentUser.userType != 'teacher') {
        _showErrorDialog('Apenas professores podem acessar esta funcionalidade.');
        return;
      }

      // Buscar disciplinas do professor
      final disciplines = await _firestoreService.getTeacherDisciplines(user.uid);
      
      // Buscar todos os alunos matriculados nessas disciplinas
      Set<String> studentIds = {};
      for (var discipline in disciplines) {
        final enrollments = await _firestoreService.getDisciplineStudents(discipline.id);
        for (var enrollment in enrollments) {
          studentIds.add(enrollment.studentId);
        }
      }

      // Buscar dados dos alunos
      List<UserModel> students = [];
      for (String studentId in studentIds) {
        final studentData = await _firestoreService.getUser(studentId);
        if (studentData != null) {
          print('DEBUG - Dados do aluno: $studentData');
          final student = UserModel.fromMap(studentData);
          print('DEBUG - UserModel criado - uid: ${student.uid}, name: ${student.name}');
          students.add(student);
        }
      }

      setState(() {
        _enrolledStudents = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Erro ao carregar alunos: $e');
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

  void _startChat(UserModel student) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          otherUser: student,
        ),
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
        title: const Text('Escolher Aluno'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _enrolledStudents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Nenhum aluno matriculado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Você ainda não tem alunos matriculados em suas disciplinas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _enrolledStudents.length,
                  itemBuilder: (context, index) {
                    final student = _enrolledStudents[index];
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      onTap: () => _startChat(student),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.accentColor,
                            child: Text(
                              student.name.isNotEmpty
                                  ? student.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  student.email,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Aluno',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.accentColor,
                                      fontWeight: FontWeight.w500,
                                    ),
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
    );
  }
}
