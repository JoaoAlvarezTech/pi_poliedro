# Portal Poliedro (Flutter)

Aplicativo Flutter com tela de login e alternância entre os canais Aluno e Professor.

## Pré-requisitos
- Flutter SDK instalado e configurado (canal stable)
- Android Studio/Xcode para mobile (opcional) ou Chrome para Web

## Como rodar
```bash
flutter pub get
flutter run -d chrome   # Web
# ou
flutter run              # Selecionará um dispositivo disponível
```

## Estrutura
- `lib/main.dart`: App principal e tela de login com alternância Aluno/Professor.
- `pubspec.yaml`: Configurações do projeto.

## Notas
- Ao clicar em Login, você é redirecionado para uma tela placeholder específica do canal selecionado.

