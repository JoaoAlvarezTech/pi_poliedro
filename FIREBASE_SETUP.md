# Configuração do Firebase

## Passos para configurar o Firebase no seu projeto:

### 1. Configurar o Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

### 2. Configurar o FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### 3. Configurar o projeto Firebase
```bash
cd pi-of
flutterfire configure
```

### 4. Arquivos que serão gerados automaticamente:
- `android/app/google-services.json` (para Android)
- `ios/Runner/GoogleService-Info.plist` (para iOS)
- `lib/firebase_options.dart` (será sobrescrito com suas configurações reais)

### 5. Configurações necessárias no Firebase Console:

#### Authentication:
- Habilitar Email/Password
- Configurar domínios autorizados (se necessário)

#### Firestore Database:
- Criar banco de dados
- Configurar regras de segurança

#### Storage:
- Configurar regras de acesso

### 6. Estrutura de dados no Firestore:

#### Coleção: `users`
```json
{
  "uid": "user_id",
  "email": "user@example.com",
  "name": "Nome do Usuário",
  "userType": "student" | "teacher",
  "cpf": "000.000.000-00",
  "phone": "+5511999999999",
  "studentId": "RA123456", // apenas para alunos
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 7. Regras de segurança do Firestore:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuários podem ler e escrever apenas seus próprios dados
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 8. Regras de segurança do Storage:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Após a configuração:
1. Execute `flutter pub get` para instalar as dependências
2. Execute `flutter run` para testar o aplicativo
3. Verifique se a autenticação está funcionando corretamente
