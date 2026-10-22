import 'package:flutter/material.dart';

import 'src/repositories/sqlite_learning_repository.dart';
import 'src/services/tts_speech_service.dart';
import 'src/view_models/learning_view_model.dart';
import 'src/views/learning_home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final viewModel = LearningViewModel(
    repository: SqliteLearningRepository(),
    speechService: TtsSpeechService(),
  );

  runApp(IsloraApp(viewModel: viewModel));
}

class IsloraApp extends StatelessWidget {
  const IsloraApp({super.key, required this.viewModel});

  final LearningViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF287A66);

    return MaterialApp(
      title: 'Islora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          surface: const Color(0xFFF8F7F2),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F7F2),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F7F2),
          foregroundColor: Color(0xFF163C34),
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E8E1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: seedColor, width: 1.5),
          ),
        ),
      ),
      home: LearningHomePage(viewModel: viewModel),
    );
  }
}
