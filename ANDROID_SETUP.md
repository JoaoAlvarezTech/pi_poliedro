# Configuração do Android para Firebase

## Passos para configurar o Firebase no Android:

### 1. Configurar o arquivo `android/app/build.gradle`

Adicione o plugin do Google Services no final do arquivo:

```gradle
apply plugin: 'com.google.gms.google-services'
```

### 2. Configurar o arquivo `android/build.gradle`

Adicione a dependência do Google Services na seção `dependencies`:

```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
    // outras dependências...
}
```

### 3. Configurar o arquivo `android/app/build.gradle`

Adicione as dependências do Firebase:

```gradle
dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.firebase:firebase-firestore'
    implementation 'com.google.firebase:firebase-storage'
    // outras dependências...
}
```

### 4. Configurar o arquivo `android/app/src/main/AndroidManifest.xml`

Adicione as permissões necessárias:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### 5. Configurar o arquivo `android/app/src/main/kotlin/.../MainActivity.kt`

Certifique-se de que o arquivo está configurado corretamente:

```kotlin
package com.example.portal_polidro

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
}
```

### 6. Baixar o arquivo `google-services.json`

1. Acesse o [Firebase Console](https://console.firebase.google.com/)
2. Selecione seu projeto
3. Vá em "Configurações do projeto" (ícone de engrenagem)
4. Na aba "Geral", role até "Seus aplicativos"
5. Clique em "Adicionar app" e selecione Android
6. Digite o nome do pacote: `com.example.portal_polidro`
7. Baixe o arquivo `google-services.json`
8. Coloque o arquivo em `android/app/google-services.json`

### 7. Configurar o arquivo `android/app/google-services.json`

O arquivo deve conter algo similar a:

```json
{
  "project_info": {
    "project_number": "123456789",
    "project_id": "seu-projeto-id",
    "storage_bucket": "seu-projeto-id.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789:android:abcdef123456",
        "android_client_info": {
          "package_name": "com.example.portal_polidro"
        }
      },
      "oauth_client": [...],
      "api_key": [
        {
          "current_key": "SUA_API_KEY_AQUI"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": [...]
        }
      }
    }
  ],
  "configuration_version": "1"
}
```

### 8. Executar o projeto

```bash
flutter clean
flutter pub get
flutter run
```

## Notas importantes:

- Certifique-se de que o nome do pacote no `google-services.json` corresponde ao configurado no `android/app/build.gradle`
- Se você mudar o nome do pacote, será necessário baixar um novo `google-services.json`
- O arquivo `google-services.json` deve estar sempre na pasta `android/app/`
- Nunca commite o arquivo `google-services.json` em repositórios públicos
