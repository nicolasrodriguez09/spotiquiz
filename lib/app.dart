import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/spotiquiz_controller.dart';
import 'core/app_theme.dart';
import 'presentation/spotiquiz_screen.dart';
import 'services/quiz_generator.dart';
import 'services/spotify_api_service.dart';
import 'services/spotify_auth_service.dart';

class SpotiquizApp extends StatelessWidget {
  const SpotiquizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SpotiquizController(
        authService: SpotifyAuthService(),
        apiService: SpotifyApiService(),
        quizGenerator: QuizGenerator(),
      ),
      child: MaterialApp(
        title: 'Spotiquiz',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const SpotiquizScreen(),
      ),
    );
  }
}
