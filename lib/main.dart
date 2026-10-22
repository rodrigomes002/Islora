import 'package:flutter/material.dart';

import 'src/repositories/sqlite_learning_repository.dart';
import 'src/services/tts_speech_service.dart';
import 'src/theme/app_colors.dart';
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
    return MaterialApp(
      title: 'Islora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              surface: AppColors.canvas,
            ).copyWith(
              primary: AppColors.primary,
              onPrimary: AppColors.card,
              secondary: AppColors.accent,
              onSecondary: AppColors.ink,
              surface: AppColors.canvas,
              onSurface: AppColors.ink,
              outline: AppColors.border,
              error: AppColors.error,
              onError: AppColors.card,
            ),
        scaffoldBackgroundColor: AppColors.canvas,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.canvas,
          foregroundColor: AppColors.ink,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
      home: LearningHomePage(viewModel: viewModel),
    );
  }
}
