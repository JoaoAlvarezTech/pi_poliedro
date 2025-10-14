import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../models/discipline_model.dart';
import '../models/activity_model.dart';
import '../models/grade_model.dart';
import '../models/material_model.dart';
import '../models/message_model.dart';
import '../models/student_discipline_model.dart';
import '../models/submission_model.dart';
import '../models/chat_message_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Coleções
  static const String usersCollection = 'users';
  static const String disciplinesCollection = 'disciplines';
  static const String activitiesCollection = 'activities';
  static const String gradesCollection = 'grades';
  static const String materialsCollection = 'materials';
  static const String messagesCollection = 'messages';
  static const String studentDisciplinesCollection = 'student_disciplines';
  static const String submissionsCollection = 'submissions';
  static const String chatMessagesCollection = 'chat_messages';

  // ========== USUÁRIOS ==========

  // Criar usuário
  Future<void> createUser({
    required String uid,
    required String email,
    required String name,
    required String userType,
    required String cpf,
    required String phone,
    String? ra,
    String? studentId,
    String? teacherId,
  }) async {
    try {
      final userData = {
        'uid': uid,
        'email': email,
        'name': name,
        'userType': userType, // 'student' ou 'teacher'
        'cpf': cpf,
        'phone': phone,
        'ra': ra,
        'studentId': studentId,
        'teacherId': teacherId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      
      await _firestore.collection(usersCollection).doc(uid).set(userData);
    } catch (e) {
      throw 'Erro ao criar usuário: $e';
    }
  }

  // Buscar usuário por ID
  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      if (uid.isEmpty) {
        throw 'ID do usuário não pode ser vazio';
      }
      DocumentSnapshot doc = await _firestore.collection(usersCollection).doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw 'Erro ao buscar usuário: $e';
    }
  }

  // Buscar usuário por email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return query.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw 'Erro ao buscar usuário por email: $e';
    }
  }

  // Atualizar usuário
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(usersCollection).doc(uid).update(data);
    } catch (e) {
      throw 'Erro ao atualizar usuário: $e';
    }
  }

  // Deletar usuário
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(usersCollection).doc(uid).delete();
    } catch (e) {
      throw 'Erro ao deletar usuário: $e';
    }
  }

  // Buscar todos os alunos
  Future<List<UserModel>> getAllStudents() async {
    try {
      QuerySnapshot query = await _firestore
          .collection(usersCollection)
          .where('userType', isEqualTo: 'student')
          .where('isActive', isEqualTo: true)
          .get();
      
      return query.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Compatibilidade: se não tem 'ra' mas tem 'studentId', usar 'studentId' como 'ra'
        if (data['ra'] == null && data['studentId'] != null) {
          data['ra'] = data['studentId'];
        }
        
        return UserModel.fromMap({
          'uid': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      throw 'Erro ao buscar alunos: $e';
    }
  }

  // Buscar aluno por RA
  Future<UserModel?> getStudentByRA(String ra) async {
    try {
      // Buscar por 'ra' primeiro
      QuerySnapshot query = await _firestore
          .collection(usersCollection)
          .where('ra', isEqualTo: ra)
          .where('userType', isEqualTo: 'student')
          .where('isActive', isEqualTo: true)
          .get();
      
      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data() as Map<String, dynamic>;
        return UserModel.fromMap({
          'uid': query.docs.first.id,
          ...data,
        });
      }
      
      // Se não encontrou por 'ra', buscar por 'studentId' (compatibilidade)
      QuerySnapshot query2 = await _firestore
          .collection(usersCollection)
          .where('studentId', isEqualTo: ra)
          .where('userType', isEqualTo: 'student')
          .where('isActive', isEqualTo: true)
          .get();
      
      if (query2.docs.isNotEmpty) {
        final data = query2.docs.first.data() as Map<String, dynamic>;
        // Garantir que o campo 'ra' seja preenchido
        data['ra'] = data['studentId'];
        return UserModel.fromMap({
          'uid': query2.docs.first.id,
          ...data,
        });
      }
      
      return null;
    } catch (e) {
      throw 'Erro ao buscar aluno por RA: $e';
    }
  }

  // ========== DISCIPLINAS ==========

  // Criar disciplina
  Future<String> createDiscipline(DisciplineModel discipline) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(disciplinesCollection)
          .add(discipline.toMap());
      return docRef.id;
    } catch (e) {
      throw 'Erro ao criar disciplina: $e';
    }
  }

  // Buscar disciplinas do professor
  Future<List<DisciplineModel>> getTeacherDisciplines(String teacherId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(disciplinesCollection)
          .where('teacherId', isEqualTo: teacherId)
          .where('isActive', isEqualTo: true)
          .get();
      
      // Ordenar localmente para evitar necessidade de índice composto
      final disciplines = query.docs.map((doc) => DisciplineModel.fromMap({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      })).toList();
      
      // Ordenar por data de criação (mais recente primeiro)
      disciplines.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return disciplines;
    } catch (e) {
      throw 'Erro ao buscar disciplinas do professor: $e';
    }
  }

  // Buscar disciplinas do aluno
  Future<List<DisciplineModel>> getStudentDisciplines(String studentId) async {
    try {
      print('DEBUG - Buscando disciplinas para aluno: $studentId');
      
      // Validar se o studentId não está vazio
      if (studentId.isEmpty) {
        print('DEBUG - StudentId está vazio, retornando lista vazia');
        return [];
      }
      
      // Primeiro, buscar as disciplinas em que o aluno está matriculado
      QuerySnapshot enrollments = await _firestore
          .collection(studentDisciplinesCollection)
          .where('studentId', isEqualTo: studentId)
          .where('isActive', isEqualTo: true)
          .get();
      
      print('DEBUG - Encontradas ${enrollments.docs.length} matrículas');
      
      if (enrollments.docs.isEmpty) {
        print('DEBUG - Nenhuma matrícula encontrada para o aluno');
        return [];
      }
      
      List<String> disciplineIds = enrollments.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            print('DEBUG - Dados da matrícula: $data');
            return data['disciplineId'] as String?;
          })
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toList();
      
      print('DEBUG - IDs das disciplinas: $disciplineIds');
      
      // Buscar as disciplinas
      QuerySnapshot disciplines = await _firestore
          .collection(disciplinesCollection)
          .where(FieldPath.documentId, whereIn: disciplineIds)
          .where('isActive', isEqualTo: true)
          .get();
      
      print('DEBUG - Encontradas ${disciplines.docs.length} disciplinas ativas');
      
      final result = disciplines.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('DEBUG - Disciplina: ${data['name']} (ID: ${doc.id})');
        return DisciplineModel.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
      print('DEBUG - Retornando ${result.length} disciplinas');
      return result;
    } catch (e) {
      print('DEBUG - Erro ao buscar disciplinas do aluno: $e');
      throw 'Erro ao buscar disciplinas do aluno: $e';
    }
  }

  // ========== ATIVIDADES ==========

  // Criar atividade
  Future<String> createActivity(ActivityModel activity) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(activitiesCollection)
          .add(activity.toMap());
      return docRef.id;
    } catch (e) {
      throw 'Erro ao criar atividade: $e';
    }
  }

  // Buscar atividades de uma disciplina
  Future<List<ActivityModel>> getDisciplineActivities(String disciplineId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(activitiesCollection)
          .where('disciplineId', isEqualTo: disciplineId)
          .where('isActive', isEqualTo: true)
          .get();
      
      // Ordenar localmente para evitar necessidade de índice composto
      final activities = query.docs.map((doc) => ActivityModel.fromMap({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      })).toList();
      
      // Ordenar por data de criação (mais recente primeiro)
      activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return activities;
    } catch (e) {
      throw 'Erro ao buscar atividades da disciplina: $e';
    }
  }

  // ========== NOTAS ==========

  // Criar/atualizar nota
  Future<void> setGrade(GradeModel grade) async {
    try {
      await _firestore
          .collection(gradesCollection)
          .doc(grade.id)
          .set(grade.toMap());
    } catch (e) {
      throw 'Erro ao salvar nota: $e';
    }
  }

  // Buscar notas do aluno em uma disciplina
  Future<List<GradeModel>> getStudentGrades(String studentId, String disciplineId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(gradesCollection)
          .where('studentId', isEqualTo: studentId)
          .where('disciplineId', isEqualTo: disciplineId)
          .get();
      
      // Ordenar localmente para evitar necessidade de índice composto
      final grades = query.docs.map((doc) => GradeModel.fromMap({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      })).toList();
      
      // Ordenar por data de criação (mais recente primeiro)
      grades.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return grades;
    } catch (e) {
      throw 'Erro ao buscar notas do aluno: $e';
    }
  }

  // Calcular média do aluno em uma disciplina
  Future<double> calculateStudentAverage(String studentId, String disciplineId) async {
    try {
      // Buscar todas as atividades da disciplina
      List<ActivityModel> activities = await getDisciplineActivities(disciplineId);
      
      if (activities.isEmpty) return 0.0;
      
      // Buscar todas as notas do aluno na disciplina
      List<GradeModel> grades = await getStudentGrades(studentId, disciplineId);
      
      double totalWeightedGrade = 0.0;
      double totalWeight = 0.0;
      
      for (ActivityModel activity in activities) {
        // Buscar nota do aluno para esta atividade
        GradeModel? studentGrade = grades
            .where((grade) => grade.activityId == activity.id)
            .firstOrNull;
        
        if (studentGrade != null) {
          totalWeightedGrade += (studentGrade.grade / activity.maxGrade) * activity.weight;
          totalWeight += activity.weight;
        }
      }
      
      return totalWeight > 0 ? (totalWeightedGrade / totalWeight) * 10 : 0.0;
    } catch (e) {
      throw 'Erro ao calcular média do aluno: $e';
    }
  }

  // ========== MATERIAIS ==========

  // Criar material
  Future<String> createMaterial(MaterialModel material) async {
    try {
      final materialData = material.toMap();
      
      DocumentReference docRef = await _firestore
          .collection(materialsCollection)
          .add(materialData);
      return docRef.id;
    } catch (e) {
      throw 'Erro ao criar material: $e';
    }
  }

  // Buscar materiais de uma disciplina
  Future<List<MaterialModel>> getDisciplineMaterials(String disciplineId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(materialsCollection)
          .where('disciplineId', isEqualTo: disciplineId)
          .where('isActive', isEqualTo: true)
          .get();
      
      // Ordenar localmente para evitar necessidade de índice composto
      final materials = query.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return MaterialModel.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
      // Ordenar por data de criação (mais recente primeiro)
      materials.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return materials;
    } catch (e) {
      throw 'Erro ao buscar materiais da disciplina: $e';
    }
  }

  // ========== MENSAGENS ==========

  // Enviar mensagem
  Future<String> sendMessage(MessageModel message) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(messagesCollection)
          .add(message.toMap());
      return docRef.id;
    } catch (e) {
      throw 'Erro ao enviar mensagem: $e';
    }
  }

  // Buscar mensagens do aluno
  Future<List<MessageModel>> getStudentMessages(String studentId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(messagesCollection)
          .where('receiverId', isEqualTo: studentId)
          .get();
      
      // Ordenar localmente para evitar necessidade de índice composto
      final messages = query.docs.map((doc) => MessageModel.fromMap({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      })).toList();
      
      // Ordenar por data de criação (mais recente primeiro)
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return messages;
    } catch (e) {
      throw 'Erro ao buscar mensagens do aluno: $e';
    }
  }

  // Marcar mensagem como lida
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore
          .collection(messagesCollection)
          .doc(messageId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Erro ao marcar mensagem como lida: $e';
    }
  }

  // ========== MATRÍCULAS ==========

  // Matricular aluno em disciplina
  Future<void> enrollStudentInDiscipline(StudentDisciplineModel enrollment) async {
    try {
      print('DEBUG - Matriculando aluno: ${enrollment.studentName} em ${enrollment.disciplineName}');
      print('DEBUG - StudentId: ${enrollment.studentId}, DisciplineId: ${enrollment.disciplineId}');
      
      // Usar add() para gerar ID automaticamente, ou set() se ID não estiver vazio
      if (enrollment.id.isEmpty) {
        await _firestore
            .collection(studentDisciplinesCollection)
            .add(enrollment.toMap());
      } else {
        await _firestore
            .collection(studentDisciplinesCollection)
            .doc(enrollment.id)
            .set(enrollment.toMap());
      }
      
      print('DEBUG - Matrícula realizada com sucesso');
    } catch (e) {
      print('DEBUG - Erro na matrícula: $e');
      throw 'Erro ao matricular aluno: $e';
    }
  }

  // Desmatricular aluno de disciplina
  Future<void> unenrollStudentFromDiscipline(String studentId, String disciplineId) async {
    try {
      print('DEBUG - Desmatriculando aluno: $studentId da disciplina: $disciplineId');
      
      // Buscar a matrícula específica
      QuerySnapshot query = await _firestore
          .collection(studentDisciplinesCollection)
          .where('studentId', isEqualTo: studentId)
          .where('disciplineId', isEqualTo: disciplineId)
          .where('isActive', isEqualTo: true)
          .get();
      
      if (query.docs.isEmpty) {
        throw 'Matrícula não encontrada';
      }
      
      // Marcar como inativa em vez de deletar (para manter histórico)
      for (var doc in query.docs) {
        await doc.reference.update({
          'isActive': false,
          'unenrolledAt': FieldValue.serverTimestamp(),
        });
      }
      
      print('DEBUG - Desmatrícula realizada com sucesso');
    } catch (e) {
      print('DEBUG - Erro na desmatrícula: $e');
      throw 'Erro ao desmatricular aluno: $e';
    }
  }

  // Buscar alunos de uma disciplina
  Future<List<StudentDisciplineModel>> getDisciplineStudents(String disciplineId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(studentDisciplinesCollection)
          .where('disciplineId', isEqualTo: disciplineId)
          .where('isActive', isEqualTo: true)
          .get();
      
      return query.docs.map((doc) => StudentDisciplineModel.fromMap({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      })).toList();
    } catch (e) {
      throw 'Erro ao buscar alunos da disciplina: $e';
    }
  }

  // ========== UTILITÁRIOS ==========

  // Verificar se um documento existe
  Future<bool> documentExists(String collection, String docId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(collection).doc(docId).get();
      return doc.exists;
    } catch (e) {
      throw 'Erro ao verificar existência do documento: $e';
    }
  }

  // Buscar documentos com paginação
  Future<List<Map<String, dynamic>>> getDocumentsWithPagination({
    required String collection,
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String? orderBy,
    bool descending = true,
  }) async {
    try {
      Query query = _firestore.collection(collection);
      
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      QuerySnapshot querySnapshot = await query.limit(limit).get();
      
      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      throw 'Erro ao buscar documentos com paginação: $e';
    }
  }

  // ========== SUBMISSÕES ==========

  // Criar submissão
  Future<String> createSubmission(SubmissionModel submission) async {
    try {
      print('DEBUG - Criando submissão para atividade: ${submission.activityId}');
      print('DEBUG - StudentId: ${submission.studentId}');
      print('DEBUG - FileUrl: ${submission.fileUrl}');
      
      final submissionData = submission.toMap();
      print('DEBUG - Dados da submissão: $submissionData');
      
      DocumentReference docRef = await _firestore
          .collection(submissionsCollection)
          .add(submissionData);
      
      print('DEBUG - Submissão criada com ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('DEBUG - Erro ao criar submissão: $e');
      throw 'Erro ao criar submissão: $e';
    }
  }

  // Buscar submissões de uma atividade
  Future<List<SubmissionModel>> getActivitySubmissions(String activityId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(submissionsCollection)
          .where('activityId', isEqualTo: activityId)
          .orderBy('submittedAt', descending: true)
          .get();

      return query.docs.map((doc) => 
          SubmissionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw 'Erro ao buscar submissões da atividade: $e';
    }
  }

  // Buscar submissões de um aluno
  Future<List<SubmissionModel>> getStudentSubmissions(String studentId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(submissionsCollection)
          .where('studentId', isEqualTo: studentId)
          .orderBy('submittedAt', descending: true)
          .get();

      return query.docs.map((doc) => 
          SubmissionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw 'Erro ao buscar submissões do aluno: $e';
    }
  }

  // Buscar submissão específica de um aluno para uma atividade
  Future<SubmissionModel?> getStudentActivitySubmission(String studentId, String activityId) async {
    try {
      print('DEBUG - Buscando submissão para studentId: $studentId, activityId: $activityId');
      
      QuerySnapshot query = await _firestore
          .collection(submissionsCollection)
          .where('studentId', isEqualTo: studentId)
          .where('activityId', isEqualTo: activityId)
          .limit(1)
          .get();

      print('DEBUG - Query executada, documentos encontrados: ${query.docs.length}');

      if (query.docs.isEmpty) {
        print('DEBUG - Nenhuma submissão encontrada');
        return null;
      }

      final doc = query.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      print('DEBUG - Dados da submissão encontrada: $data');
      
      return SubmissionModel.fromMap(data, doc.id);
    } catch (e) {
      print('DEBUG - Erro ao buscar submissão: $e');
      throw 'Erro ao buscar submissão do aluno: $e';
    }
  }

  // Avaliar submissão
  Future<void> gradeSubmission(String submissionId, double grade, String? teacherComments) async {
    try {
      print('DEBUG - Avaliando submissão ID: $submissionId com nota: $grade');
      
      // Primeiro, buscar a submissão para obter os dados necessários
      final submissionDoc = await _firestore
          .collection(submissionsCollection)
          .doc(submissionId)
          .get();
      
      if (!submissionDoc.exists) {
        throw 'Submissão não encontrada';
      }
      
      final submissionData = submissionDoc.data() as Map<String, dynamic>;
      final studentId = submissionData['studentId'] as String;
      final activityId = submissionData['activityId'] as String;
      final disciplineId = submissionData['disciplineId'] as String;
      
      print('DEBUG - Dados da submissão: studentId=$studentId, activityId=$activityId, disciplineId=$disciplineId');
      
      // Atualizar a submissão
      await _firestore
          .collection(submissionsCollection)
          .doc(submissionId)
          .update({
        'grade': grade,
        'teacherComments': teacherComments,
        'gradedAt': FieldValue.serverTimestamp(),
        'status': 'graded',
      });
      
      print('DEBUG - Submissão atualizada com sucesso');
      
      // Criar ou atualizar a nota na coleção grades
      final gradeId = '${studentId}_${activityId}';
      final gradeModel = GradeModel(
        id: gradeId,
        studentId: studentId,
        activityId: activityId,
        disciplineId: disciplineId,
        grade: grade,
        comments: teacherComments,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _firestore
          .collection(gradesCollection)
          .doc(gradeId)
          .set(gradeModel.toMap());
      
      print('DEBUG - Nota criada/atualizada com sucesso na coleção grades');
    } catch (e) {
      print('DEBUG - Erro ao avaliar submissão: $e');
      throw 'Erro ao avaliar submissão: $e';
    }
  }

  // Atualizar submissão
  Future<void> updateSubmission(SubmissionModel submission) async {
    try {
      print('DEBUG - Atualizando submissão ID: ${submission.id}');
      
      if (submission.id.isEmpty) {
        throw 'ID da submissão não pode estar vazio para atualização';
      }
      
      final submissionData = submission.toMap();
      print('DEBUG - Dados da submissão para atualização: $submissionData');
      
      await _firestore
          .collection(submissionsCollection)
          .doc(submission.id)
          .update(submissionData);
      
      print('DEBUG - Submissão atualizada com sucesso');
    } catch (e) {
      print('DEBUG - Erro ao atualizar submissão: $e');
      throw 'Erro ao atualizar submissão: $e';
    }
  }

  // Deletar submissão
  Future<void> deleteSubmission(String submissionId) async {
    try {
      await _firestore
          .collection(submissionsCollection)
          .doc(submissionId)
          .delete();
    } catch (e) {
      throw 'Erro ao deletar submissão: $e';
    }
  }

  // ========== CHAT ==========

  // Enviar mensagem de chat
  Future<void> sendChatMessage(ChatMessageModel message) async {
    try {
      print('DEBUG - Enviando mensagem: ${message.content}');
      print('DEBUG - De: ${message.senderId} para: ${message.receiverId}');
      
      final messageData = message.toMap();
      messageData.remove('id'); // Remove o ID para que o Firestore gere um novo
      
      print('DEBUG - Dados da mensagem: $messageData');
      
      final docRef = await _firestore
          .collection(chatMessagesCollection)
          .add(messageData);
      
      print('DEBUG - Mensagem salva com ID: ${docRef.id}');
    } catch (e) {
      print('DEBUG - Erro ao enviar mensagem: $e');
      throw 'Erro ao enviar mensagem: $e';
    }
  }

  // Buscar mensagens de chat entre dois usuários
  Future<List<ChatMessageModel>> getChatMessages(String userId1, String userId2) async {
    try {
      // Buscar mensagens onde userId1 é o remetente e userId2 é o destinatário
      QuerySnapshot query1 = await _firestore
          .collection(chatMessagesCollection)
          .where('senderId', isEqualTo: userId1)
          .where('receiverId', isEqualTo: userId2)
          .orderBy('timestamp', descending: false)
          .get();

      // Buscar mensagens onde userId2 é o remetente e userId1 é o destinatário
      QuerySnapshot query2 = await _firestore
          .collection(chatMessagesCollection)
          .where('senderId', isEqualTo: userId2)
          .where('receiverId', isEqualTo: userId1)
          .orderBy('timestamp', descending: false)
          .get();

      List<ChatMessageModel> messages = [];

      // Adicionar mensagens da primeira query
      for (var doc in query1.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        messages.add(ChatMessageModel.fromMap(data));
      }

      // Adicionar mensagens da segunda query
      for (var doc in query2.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        messages.add(ChatMessageModel.fromMap(data));
      }

      // Ordenar todas as mensagens por timestamp
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return messages;
    } catch (e) {
      throw 'Erro ao buscar mensagens: $e';
    }
  }

  // Marcar mensagens como lidas
  Future<void> markChatMessagesAsRead(String userId1, String userId2) async {
    try {
      // Buscar mensagens não lidas onde userId1 é o destinatário
      QuerySnapshot query = await _firestore
          .collection(chatMessagesCollection)
          .where('receiverId', isEqualTo: userId1)
          .where('senderId', isEqualTo: userId2)
          .where('isRead', isEqualTo: false)
          .get();

      // Atualizar cada mensagem como lida
      for (var doc in query.docs) {
        await doc.reference.update({
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw 'Erro ao marcar mensagens como lidas: $e';
    }
  }

  // Buscar conversas do usuário (lista de usuários com quem há conversas)
  Future<List<UserModel>> getUserConversations(String userId) async {
    try {
      // Buscar mensagens onde o usuário é remetente ou destinatário
      QuerySnapshot query = await _firestore
          .collection(chatMessagesCollection)
          .where('senderId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      Set<String> conversationUserIds = {};

      // Adicionar IDs dos destinatários
      for (var doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final receiverId = data['receiverId'] as String?;
        if (receiverId != null && receiverId.isNotEmpty) {
          conversationUserIds.add(receiverId);
        }
      }

      // Buscar mensagens onde o usuário é destinatário
      QuerySnapshot query2 = await _firestore
          .collection(chatMessagesCollection)
          .where('receiverId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      // Adicionar IDs dos remetentes
      for (var doc in query2.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final senderId = data['senderId'] as String?;
        if (senderId != null && senderId.isNotEmpty) {
          conversationUserIds.add(senderId);
        }
      }

      // Buscar dados dos usuários
      List<UserModel> conversations = [];
      for (String otherUserId in conversationUserIds) {
        if (otherUserId != userId && otherUserId.isNotEmpty) {
          final userData = await getUser(otherUserId);
          if (userData != null) {
            conversations.add(UserModel.fromMap(userData));
          }
        }
      }

      return conversations;
    } catch (e) {
      throw 'Erro ao buscar conversas: $e';
    }
  }

  // Stream de mensagens de chat entre dois usuários
  Stream<List<ChatMessageModel>> getChatMessagesStream(String userId1, String userId2) {
    try {
      print('DEBUG - Criando stream para usuários: $userId1 e $userId2');
      
      // Usar duas queries separadas que respeitam as regras de segurança
      final stream1 = _firestore
          .collection(chatMessagesCollection)
          .where('senderId', isEqualTo: userId1)
          .where('receiverId', isEqualTo: userId2)
          .orderBy('timestamp', descending: false)
          .snapshots();

      final stream2 = _firestore
          .collection(chatMessagesCollection)
          .where('senderId', isEqualTo: userId2)
          .where('receiverId', isEqualTo: userId1)
          .orderBy('timestamp', descending: false)
          .snapshots();

      // Combinar os dois streams usando combineLatest
      return stream1.asyncExpand((snapshot1) {
        return stream2.map((snapshot2) {
          List<ChatMessageModel> messages = [];

          print('DEBUG - Stream1: ${snapshot1.docs.length} docs, Stream2: ${snapshot2.docs.length} docs');

          // Adicionar mensagens da primeira query
          for (var doc in snapshot1.docs) {
            final data = doc.data();
            data['id'] = doc.id;
            messages.add(ChatMessageModel.fromMap(data));
            print('DEBUG - Mensagem 1 adicionada: ${data['content']}');
          }

          // Adicionar mensagens da segunda query
          for (var doc in snapshot2.docs) {
            final data = doc.data();
            data['id'] = doc.id;
            messages.add(ChatMessageModel.fromMap(data));
            print('DEBUG - Mensagem 2 adicionada: ${data['content']}');
          }

          // Ordenar mensagens por timestamp
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          print('DEBUG - Retornando ${messages.length} mensagens combinadas');
          return messages;
        });
      });
    } catch (e) {
      print('DEBUG - Erro no stream: $e');
      throw 'Erro ao criar stream de mensagens: $e';
    }
  }
}