import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream do usuário atual
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuário atual
  User? get currentUser => _auth.currentUser;

  // Login com email e senha
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erro inesperado: $e';
    }
  }

  // Cadastro com email e senha
  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erro inesperado: $e';
    }
  }

  // Salvar dados do usuário no Firestore
  Future<void> saveUserData({
    required String uid,
    required String email,
    required String name,
    required String userType,
    required String cpf,
    required String phone,
    String? studentId,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'name': name,
        'userType': userType,
        'cpf': cpf,
        'phone': phone,
        'studentId': studentId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Erro ao salvar dados do usuário: $e';
    }
  }

  // Buscar dados do usuário
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw 'Erro ao buscar dados do usuário: $e';
    }
  }

  // Atualizar dados do usuário
  Future<void> updateUserData({
    required String uid,
    String? name,
    String? phone,
    String? studentId,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (studentId != null) updateData['studentId'] = studentId;

      await _firestore.collection('users').doc(uid).update(updateData);
    } catch (e) {
      throw 'Erro ao atualizar dados do usuário: $e';
    }
  }

  // Enviar email de redefinição de senha
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erro inesperado: $e';
    }
  }

  // Reautenticar usuário com a senha atual (necessário para atualizar email/senha)
  Future<void> reauthenticate(String currentPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw 'Usuário não autenticado';
      }
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erro ao reautenticar: $e';
    }
  }

  // Atualizar email do usuário autenticado
  Future<void> updateEmail(String newEmail, {String? currentPassword}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Usuário não autenticado';
      if (currentPassword != null) {
        await reauthenticate(currentPassword);
      }
      await user.updateEmail(newEmail);
      await _firestore.collection('users').doc(user.uid).update({
        'email': newEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erro ao atualizar email: $e';
    }
  }

  // Atualizar senha do usuário autenticado
  Future<void> updatePassword(String newPassword, {required String currentPassword}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Usuário não autenticado';
      await reauthenticate(currentPassword);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erro ao atualizar senha: $e';
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Erro ao fazer logout: $e';
    }
  }

  // Deletar conta
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Deletar dados do Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        // Deletar conta do Firebase Auth
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erro ao deletar conta: $e';
    }
  }

  // Tratar exceções do Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Nenhum usuário encontrado com este email.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este email já está sendo usado por outra conta.';
      case 'weak-password':
        return 'A senha é muito fraca.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'user-disabled':
        return 'Esta conta foi desabilitada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      case 'invalid-credential':
        return 'Credenciais inválidas.';
      default:
        return 'Erro de autenticação: ${e.message}';
    }
  }
}
