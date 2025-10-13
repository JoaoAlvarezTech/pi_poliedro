import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firestore_service.dart';
import '../../models/discipline_model.dart';
import '../../models/material_model.dart';

class StudentMaterialsScreen extends StatefulWidget {
  final DisciplineModel discipline;

  const StudentMaterialsScreen({super.key, required this.discipline});

  @override
  State<StudentMaterialsScreen> createState() => _StudentMaterialsScreenState();
}

class _StudentMaterialsScreenState extends State<StudentMaterialsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<MaterialModel> _materials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    try {
      final materials = await _firestoreService.getDisciplineMaterials(widget.discipline.id);
      setState(() {
        _materials = materials;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Erro ao carregar materiais: $e');
    }
  }

  Future<void> _openMaterial(MaterialModel material) async {
    if (material.fileUrl != null) {
      try {
        final Uri url = Uri.parse(material.fileUrl!);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          _showErrorDialog('Não foi possível abrir o material');
        }
      } catch (e) {
        _showErrorDialog('Erro ao abrir material: $e');
      }
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
        title: Text('Materiais - ${widget.discipline.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMaterialsList(),
    );
  }

  Widget _buildMaterialsList() {
    if (_materials.isEmpty) {
      return const Center(
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
            SizedBox(height: 8),
            Text(
              'Os materiais aparecerão aqui quando o professor os adicionar',
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
      itemCount: _materials.length,
      itemBuilder: (context, index) {
        final material = _materials[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getMaterialColor(material.type),
              child: Icon(_getMaterialIcon(material.type), color: Colors.white),
            ),
            title: Text(
              material.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(material.description),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Chip(
                      label: Text(_getMaterialTypeName(material.type)),
                      backgroundColor: _getMaterialColor(material.type).withOpacity(0.1),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(material.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.download),
            onTap: () => _openMaterial(material),
          ),
        );
      },
    );
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
