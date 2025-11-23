import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/discipline_model.dart';
import '../../theme/app_theme.dart';
import 'discipline_detail_screen.dart';

class DisciplinesScreen extends StatefulWidget {
  final DisciplineModel? selectedDiscipline;
  final bool showCreateForm;

  const DisciplinesScreen(
      {super.key, this.selectedDiscipline, this.showCreateForm = false});

  @override
  State<DisciplinesScreen> createState() => _DisciplinesScreenState();
}

class _DisciplinesScreenState extends State<DisciplinesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  List<DisciplineModel> _disciplines = [];
  bool _isLoading = true;
  bool _showCreateForm = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _showCreateForm = widget.showCreateForm;
    _loadDisciplines();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadDisciplines() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final disciplines =
            await _firestoreService.getTeacherDisciplines(user.uid);
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

  Future<void> _createDiscipline() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Buscar dados do professor no Firestore
        final userData = await _firestoreService.getUser(user.uid);
        final teacherName = userData?['name'] ?? 'Professor';

        final discipline = DisciplineModel(
          id: '', // Será gerado pelo Firestore
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          teacherId: user.uid,
          teacherName: teacherName,
          code: _codeController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestoreService.createDiscipline(discipline);

        _nameController.clear();
        _descriptionController.clear();
        _codeController.clear();

        setState(() {
          _showCreateForm = false;
        });

        _loadDisciplines();
        _showSuccessDialog('Disciplina criada com sucesso!');
      }
    } catch (e) {
      _showErrorDialog('Erro ao criar disciplina: $e');
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Minhas Disciplinas'),
        actions: [
          IconButton(
            icon: Icon(_showCreateForm ? Icons.close : Icons.add),
            onPressed: () {
              setState(() {
                _showCreateForm = !_showCreateForm;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_showCreateForm) _buildCreateForm(),
                Expanded(child: _buildDisciplinesList()),
              ],
            ),
    );
  }

  Widget _buildCreateForm() {
    return AppCard(
      margin: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nova Disciplina',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Disciplina',
                prefixIcon: Icon(Icons.school),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, digite o nome da disciplina';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Código da Disciplina',
                prefixIcon: Icon(Icons.tag),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, digite o código da disciplina';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, digite uma descrição';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Criar Disciplina',
                    onPressed: _createDiscipline,
                    backgroundColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppButton(
                    text: 'Cancelar',
                    onPressed: () {
                      setState(() {
                        _showCreateForm = false;
                      });
                    },
                    backgroundColor: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
              'Nenhuma disciplina cadastrada',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Crie sua primeira disciplina para começar',
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
                builder: (_) => DisciplineDetailScreen(discipline: discipline),
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
