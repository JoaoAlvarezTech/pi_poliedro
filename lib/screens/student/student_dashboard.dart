import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/discipline_model.dart';
import '../../models/message_model.dart';
import 'disciplines_screen.dart';
import 'messages_screen.dart';
import 'grades_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  UserModel? _currentUser;
  List<DisciplineModel> _disciplines = [];
  List<MessageModel> _messages = [];
  int _unreadMessages = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      print('DEBUG - Usuário atual: ${user?.uid}');
      
      if (user != null) {
        // Buscar dados do usuário
        final userData = await _firestoreService.getUser(user.uid);
        print('DEBUG - Dados do usuário: $userData');
        
        if (userData != null) {
          setState(() {
            _currentUser = UserModel.fromMap(userData);
          });
          print('DEBUG - Usuário carregado: ${_currentUser?.name} (${_currentUser?.userType})');
        }

        // Buscar disciplinas do aluno
        print('DEBUG - Buscando disciplinas para o aluno: ${user.uid}');
        final disciplines = await _firestoreService.getStudentDisciplines(user.uid);
        print('DEBUG - Disciplinas encontradas: ${disciplines.length}');
        
        // Buscar mensagens
        final messages = await _firestoreService.getStudentMessages(user.uid);
        final unreadCount = messages.where((m) => !m.isRead).length;

        setState(() {
          _disciplines = disciplines;
          _messages = messages;
          _unreadMessages = unreadCount;
          _isLoading = false;
        });
      } else {
        print('DEBUG - Usuário não autenticado');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG - Erro no dashboard: $e');
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

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      _showErrorDialog('Erro ao fazer logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7DDB8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A5B5),
        foregroundColor: Colors.white,
        title: Text('Bem-vindo, ${_currentUser?.name ?? 'Aluno'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cards de estatísticas
            _buildStatsCards(),
            const SizedBox(height: 24),
            
            // Seção de disciplinas
            _buildDisciplinesSection(),
            const SizedBox(height: 24),
            
            // Seção de mensagens
            _buildMessagesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Disciplinas',
            value: _disciplines.length.toString(),
            icon: Icons.school,
            color: const Color(0xFF00A5B5),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Mensagens',
            value: _unreadMessages.toString(),
            icon: Icons.message,
            color: _unreadMessages > 0 ? const Color(0xFFEB2E54) : const Color(0xFFFFB21C),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisciplinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Minhas Disciplinas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEB2E54),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StudentDisciplinesScreen(),
                  ),
                );
              },
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_disciplines.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.school, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Nenhuma disciplina matriculada',
                      style: TextStyle(
                        fontSize: 16,
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
              ),
            ),
          )
        else
          ..._disciplines.take(3).map((discipline) => _buildDisciplineCard(discipline)),
      ],
    );
  }

  Widget _buildDisciplineCard(DisciplineModel discipline) {
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
        subtitle: Text('Prof. ${discipline.teacherName}'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StudentGradesScreen(discipline: discipline),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mensagens',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEB2E54),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StudentMessagesScreen(),
                  ),
                );
              },
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_messages.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.message, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Nenhuma mensagem recebida',
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
          ..._messages.take(3).map((message) => _buildMessageCard(message)),
      ],
    );
  }

  Widget _buildMessageCard(MessageModel message) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: message.isRead ? Colors.grey : const Color(0xFFEB2E54),
          child: Icon(
            message.isRead ? Icons.message : Icons.message_outlined,
            color: Colors.white,
          ),
        ),
        title: Text(
          message.subject,
          style: TextStyle(
            fontWeight: message.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text('De: ${message.senderName}'),
        trailing: Text(
          _formatDate(message.createdAt),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const StudentMessagesScreen(),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}
