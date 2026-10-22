# Islora

Aplicativo Android para organizar frases em inglês por ilhas de aprendizado,
salvar traduções opcionais e praticar a pronúncia com áudio sintetizado.

## Executar

Com o Flutter instalado e um dispositivo ou emulador Android conectado:

```sh
flutter pub get
flutter run
```

As ilhas e frases são armazenadas localmente no SQLite do dispositivo. A
reprodução usa a síntese de voz em inglês do Android.

## Revisar frases

Frases novas aparecem na sessão de revisão. Revele a tradução e marque se
lembrou: respostas corretas espaçam a próxima revisão em 1, 3, 7, 14 e até
30 dias; respostas incorretas retomam o intervalo de 1 dia. O agendamento é
salvo localmente no SQLite.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
