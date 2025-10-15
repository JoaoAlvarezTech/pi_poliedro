import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  UserModel? _currentUser;
  bool _loading = true;
  bool _saving = false;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  String? _photoUrl;
  File? _pickedImageFile;
  Uint8List? _pickedImageBytes;
  String? _pickedImageContentType;

  // Valores iniciais para detectar mudanças
  String? _initialName;
  String? _initialEmail;
  String? _initialPhone;
  String? _initialPhotoUrl;

  bool get _hasChanges {
    final nameChanged = _nameController.text.trim() != (_initialName ?? '');
    final emailChanged = _emailController.text.trim() != (_initialEmail ?? '');
    final phoneChanged = _phoneController.text.trim() != (_initialPhone ?? '');
    final photoChanged = _pickedImageBytes != null || _pickedImageFile != null;
    final wantsPasswordChange = _newPasswordController.text.isNotEmpty;
    return nameChanged || emailChanged || phoneChanged || photoChanged || wantsPasswordChange;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('Usuário não autenticado');
        return;
      }
      final data = await _firestoreService.getUser(user.uid);
      if (data == null) {
        _showError('Dados do usuário não encontrados');
        return;
      }
      final model = UserModel.fromMap({
        'uid': user.uid,
        ...data,
      });
      setState(() {
        _currentUser = model;
        _nameController.text = model.name;
        _emailController.text = model.email;
        _phoneController.text = model.phone ?? '';
        _photoUrl = model.photoUrl;
        _initialName = model.name;
        _initialEmail = model.email;
        _initialPhone = model.phone ?? '';
        _initialPhotoUrl = model.photoUrl;
        _loading = false;
      });
    } catch (e) {
      _showError('Erro ao carregar perfil: $e');
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // garante bytes no Web
      );
      if (result != null) {
        if (kIsWeb) {
          final bytes = result.files.single.bytes;
          if (bytes != null) {
            final ext = (result.files.single.extension ?? 'jpg').toLowerCase();
            final contentType = ext == 'png'
                ? 'image/png'
                : ext == 'gif'
                    ? 'image/gif'
                    : 'image/jpeg';
            setState(() {
              _pickedImageBytes = bytes;
              _pickedImageContentType = contentType;
              _pickedImageFile = null;
            });
          }
        } else {
          final path = result.files.single.path;
          if (path != null) {
            setState(() {
              _pickedImageFile = File(path);
              _pickedImageBytes = null;
              _pickedImageContentType = null;
            });
          }
        }
      }
    } catch (e) {
      _showError('Erro ao selecionar imagem: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null) return;
    setState(() => _saving = true);
    try {
      // Upload photo if changed
      String? newPhotoUrl = _photoUrl;
      if (_pickedImageBytes != null) {
        newPhotoUrl = await _storageService.uploadUserProfilePhotoBytes(
          uid: _currentUser!.uid,
          bytes: _pickedImageBytes!,
          contentType: _pickedImageContentType ?? 'image/jpeg',
        );
      } else if (_pickedImageFile != null) {
        newPhotoUrl = await _storageService.uploadUserProfilePhoto(
          uid: _currentUser!.uid,
          file: _pickedImageFile!,
        );
      }

      // Update Firestore profile fields
      await _firestoreService.updateUser(_currentUser!.uid, {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        if (newPhotoUrl != null) 'photoUrl': newPhotoUrl,
      });

      // Update email if changed
      final newEmail = _emailController.text.trim();
      if (newEmail.isNotEmpty && newEmail != _currentUser!.email) {
        if (_currentPasswordController.text.isEmpty) {
          throw 'Para alterar o e-mail, informe a senha atual.';
        }
        await _authService.updateEmail(
          newEmail,
          currentPassword: _currentPasswordController.text.isNotEmpty
              ? _currentPasswordController.text
              : null,
        );
      }

      // Update password if requested
      if (_newPasswordController.text.isNotEmpty && _currentPasswordController.text.isNotEmpty) {
        await _authService.updatePassword(
          _newPasswordController.text,
          currentPassword: _currentPasswordController.text,
        );
      } else if (_newPasswordController.text.isNotEmpty && _currentPasswordController.text.isEmpty) {
        throw 'Para alterar a senha, informe a senha atual.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso.')),
        );
        // Reset estado inicial após salvar
        _pickedImageFile = null;
        _pickedImageBytes = null;
        _pickedImageContentType = null;
        _initialName = _nameController.text.trim();
        _initialEmail = _emailController.text.trim();
        _initialPhone = _phoneController.text.trim();
        _initialPhotoUrl = newPhotoUrl;
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
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
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return WillPopScope(
      onWillPop: () async {
        if (_saving) return false;
        if (!_hasChanges) return true;
        final shouldLeave = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Descartar alterações?'),
                content: const Text('Você tem alterações não salvas.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Descartar'),
                  ),
                ],
              ),
            ) ??
            false;
        return shouldLeave;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Perfil'),
          actions: [
            TextButton(
              onPressed: _saving || !_hasChanges ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: _pickedImageBytes != null
                            ? MemoryImage(_pickedImageBytes!)
                            : _pickedImageFile != null
                                ? FileImage(_pickedImageFile!)
                                : (_photoUrl != null && _photoUrl!.isNotEmpty)
                                    ? NetworkImage(_photoUrl!) as ImageProvider
                                    : null,
                        child: (_photoUrl == null && _pickedImageFile == null && _pickedImageBytes == null)
                            ? const Icon(Icons.person, size: 48)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: _pickPhoto,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.edit, color: Colors.white, size: 18),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Informações da conta',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Informe o e-mail' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 24),
                const Text(
                  'Alterar senha (opcional)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _currentPasswordController,
                  decoration: const InputDecoration(labelText: 'Senha atual'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(labelText: 'Nova senha'),
                  obscureText: true,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving || !_hasChanges ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Salvar alterações'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


