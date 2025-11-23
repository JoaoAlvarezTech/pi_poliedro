# Portal Poliedro

Uma plataforma web pessoal para professores com foco em compartilhamento de conteúdos, envio de mensagens individuais e divulgação segura de notas.

## 🎯 Objetivos do Projeto

- **Multiplataforma**: Web/desktop e mobile compartilhando os mesmos dados em tempo real
- **Duas áreas distintas**: 
  - 🧑‍🏫 **Área do Professor (Admin)**
  - 👨‍🎓 **Área do Aluno (Usuário)**

## ✨ Funcionalidades Implementadas

### 🧑‍🏫 Para Professores
- ✅ **Login com autenticação segura**
- ✅ **Painel administrativo** com visão geral
- ✅ **Cadastro de disciplinas** com código e descrição
- ✅ **Cadastro de atividades** com pesos personalizados
- ✅ **Cálculo automático de médias finais**
- ✅ **Upload e organização de materiais** (PDFs, imagens, links)
- ✅ **Matrícula de alunos** por RA
- ✅ **Envio de mensagens individuais**
- ✅ **Registro e consulta de notas**

### 👨‍🎓 Para Alunos
- ✅ **Login com RA e senha**
- ✅ **Acesso restrito aos próprios dados**
- ✅ **Visualização de disciplinas matriculadas**
- ✅ **Consulta às notas e parciais**
- ✅ **Visualização de materiais organizados por disciplina**
- ✅ **Leitura de mensagens recebidas do professor**
- ✅ **Cálculo automático de média final**

## 🔐 Segurança

- ✅ **Login com distinção** entre perfil de professor e perfil de aluno
- ✅ **Recuperação de senha** por e-mail
- ✅ **Garantia de privacidade**: alunos não podem acessar dados de outros usuários
- ✅ **Regras de segurança do Firestore** implementadas
- ✅ **Regras de segurança do Storage** para upload de arquivos

## 🛠️ Tecnologias

- **Frontend**: Flutter/Dart
- **Backend**: Firebase
  - Authentication (Email/Password)
  - Firestore Database (NoSQL)
  - Cloud Storage (Arquivos)
- **Dependências**:
  - `file_picker`: Upload de arquivos
  - `url_launcher`: Abertura de links e arquivos

## 📁 Estrutura do Projeto

```
lib/
├── main.dart                          # Ponto de entrada
├── firebase_options.dart              # Configurações do Firebase
├── models/                            # Modelos de dados
│   ├── user_model.dart
│   ├── discipline_model.dart
│   ├── activity_model.dart
│   ├── grade_model.dart
│   ├── material_model.dart
│   ├── message_model.dart
│   └── student_discipline_model.dart
├── services/                          # Serviços
│   ├── auth_service.dart              # Autenticação
│   └── firestore_service.dart         # Banco de dados
├── screens/
│   ├── teacher/                       # Telas do professor
│   │   ├── teacher_dashboard.dart
│   │   ├── disciplines_screen.dart
│   │   ├── discipline_detail_screen.dart
│   │   ├── activities_screen.dart
│   │   ├── grades_screen.dart
│   │   ├── materials_screen.dart
│   │   ├── students_screen.dart
│   │   ├── student_detail_screen.dart
│   │   ├── send_message_screen.dart
│   │   └── messages_screen.dart
│   └── student/                       # Telas do aluno
│       ├── student_dashboard.dart
│       ├── disciplines_screen.dart
│       ├── grades_screen.dart
│       ├── materials_screen.dart
│       └── messages_screen.dart
└── registration_screens.dart          # Telas de cadastro
```

## 🚀 Como Executar

1. **Clone o repositório**
2. **Instale as dependências**: `flutter pub get`
3. **Configure o Firebase** (já configurado)
4. **Execute**: `flutter run -d chrome`

## 📊 Modelo de Dados

### Usuários (users)
```json
{
  "uid": "string",
  "email": "string", 
  "name": "string",
  "userType": "student|teacher",
  "ra": "string?",
  "cpf": "string",
  "phone": "string",
  "isActive": "boolean",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Disciplinas (disciplines)
```json
{
  "id": "string",
  "name": "string",
  "description": "string", 
  "teacherId": "string",
  "teacherName": "string",
  "code": "string",
  "isActive": "boolean",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Atividades (activities)
```json
{
  "id": "string",
  "disciplineId": "string",
  "name": "string",
  "description": "string",
  "weight": "number", // 0.0 a 1.0
  "maxGrade": "number",
  "dueDate": "timestamp",
  "isActive": "boolean",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Notas (grades)
```json
{
  "id": "string",
  "studentId": "string",
  "activityId": "string", 
  "disciplineId": "string",
  "grade": "number",
  "comments": "string?",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Materiais (materials)
```json
{
  "id": "string",
  "disciplineId": "string",
  "title": "string",
  "description": "string",
  "type": "pdf|image|link",
  "fileUrl": "string?",
  "linkUrl": "string?",
  "fileName": "string?",
  "fileSize": "number?",
  "isActive": "boolean",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Mensagens (messages)
```json
{
  "id": "string",
  "senderId": "string",
  "receiverId": "string",
  "senderName": "string",
  "receiverName": "string", 
  "subject": "string",
  "content": "string",
  "isRead": "boolean",
  "createdAt": "timestamp",
  "readAt": "timestamp?"
}
```

### Matrículas (student_disciplines)
```json
{
  "id": "string",
  "studentId": "string",
  "disciplineId": "string",
  "studentName": "string",
  "disciplineName": "string",
  "isActive": "boolean",
  "enrolledAt": "timestamp"
}
```

## 🎨 Identidade Visual

- **Interface simples, limpa e funcional**
- **Prioriza clareza e experiência do usuário**
- **Cores principais**:
  - Azul: `#00A5B5` (primária)
  - Rosa: `#EB2E54` (secundária)
  - Amarelo: `#FFB21C` (destaque)
  - Bege: `#F7DDB8` (fundo)

## 🔧 Configuração do Firebase

O projeto já está configurado com:
- ✅ Firebase Authentication
- ✅ Cloud Firestore
- ✅ Firebase Storage
- ✅ Regras de segurança implementadas

## 📱 Compatibilidade

- ✅ **Web**: Chrome, Firefox, Safari, Edge
- ✅ **Mobile**: Android, iOS
- ✅ **Desktop**: Windows, macOS, Linux

## 🚀 Status do Projeto

**✅ COMPLETO** - Todas as funcionalidades solicitadas foram implementadas e estão funcionando!