import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadUserProfilePhoto({
    required String uid,
    required File file,
  }) async {
    try {
      // Regras do Storage esperam caminho avatars/{uid}
      final ref = _storage.ref().child('avatars/$uid');
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      throw 'Erro ao enviar foto de perfil: $e';
    }
  }

  Future<String> uploadUserProfilePhotoBytes({
    required String uid,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    try {
      // Regras do Storage esperam caminho avatars/{uid}
      final ref = _storage.ref().child('avatars/$uid');
      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      throw 'Erro ao enviar foto de perfil: $e';
    }
  }
}


