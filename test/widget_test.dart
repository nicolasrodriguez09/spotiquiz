import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:spotiquiz/controllers/spotiquiz_controller.dart';
import 'package:spotiquiz/presentation/spotiquiz_screen.dart';
import 'package:spotiquiz/services/quiz_generator.dart';
import 'package:spotiquiz/services/spotify_api_service.dart';
import 'package:spotiquiz/services/spotify_auth_service.dart';

void main() {
  testWidgets('landing page renders app concept', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SpotiquizController(
          authService: SpotifyAuthService(),
          apiService: SpotifyApiService(),
          quizGenerator: QuizGenerator(),
        ),
        child: const MaterialApp(
          home: SpotiquizScreen(),
        ),
      ),
    );

    expect(find.text('Tu Spotify te conoce.\nLa pregunta es si tu tambien.'), findsOneWidget);
    expect(find.text('Iniciar con Spotify'), findsOneWidget);
  });
}
