import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/spotiquiz_controller.dart';
import '../core/spotify_config.dart';
import '../models/quiz_models.dart';

class SpotiquizScreen extends StatelessWidget {
  const SpotiquizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SpotiquizController>(
      builder: (context, controller, _) {
        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF7F2E7),
                  Color(0xFFD8F6D7),
                  Color(0xFFFFDCC7),
                ],
              ),
            ),
            child: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: switch (controller.viewState) {
                  SpotiquizViewState.signedOut => _LandingView(
                    key: const ValueKey('landing'),
                  ),
                  SpotiquizViewState.authenticating ||
                  SpotiquizViewState.generatingQuiz => _LoadingView(
                    key: const ValueKey('loading'),
                    message: controller.loadingMessage,
                  ),
                  SpotiquizViewState.quiz => _QuizView(
                    key: const ValueKey('quiz'),
                  ),
                  SpotiquizViewState.results => _ResultsView(
                    key: const ValueKey('results'),
                  ),
                  SpotiquizViewState.error => _ErrorView(
                    key: const ValueKey('error'),
                  ),
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScreenShell extends StatelessWidget {
  const _ScreenShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 720 ? 720.0 : constraints.maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
              child: SizedBox(width: width, child: child),
            ),
          ),
        );
      },
    );
  }
}

class _LandingView extends StatelessWidget {
  const _LandingView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SpotiquizController>();
    final theme = Theme.of(context);
    return _ScreenShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _MiniTag(label: 'Spotify OAuth'),
              _MiniTag(label: 'Quiz personal'),
              _MiniTag(label: 'Top artists + tracks'),
            ],
          ),
          const SizedBox(height: 18),
          Text('Que tanto conoces tu propio Spotify?', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 14),
          Text(
            'Conecta tu cuenta y deja que la app convierta tus habitos musicales en un reto personal, raro y bastante compartible.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tu algoritmo, convertido en quiz',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16181C),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'MVP',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _FeatureLine(
                    icon: Icons.person_search_rounded,
                    title: 'Top artistas',
                    subtitle: 'Identifica tus obsesiones recientes y de largo plazo.',
                  ),
                  const SizedBox(height: 12),
                  const _FeatureLine(
                    icon: Icons.library_music_rounded,
                    title: 'Top canciones',
                    subtitle: 'Cruza temas top con distractores creibles.',
                  ),
                  const SizedBox(height: 12),
                  const _FeatureLine(
                    icon: Icons.auto_graph_rounded,
                    title: 'Generos y cruces',
                    subtitle: 'Detecta patrones, overlaps y memoria musical real.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (controller.needsSetup) const _SetupCard(),
          if (controller.errorMessage case final message?)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ElevatedButton.icon(
            onPressed: controller.needsSetup ? null : controller.startQuizFlow,
            icon: const Icon(Icons.link_rounded),
            label: const Text('Iniciar con Spotify'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.music_note_rounded),
            label: const Text('El quiz se genera con tus datos'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _LoadingView extends StatefulWidget {
  const _LoadingView({
    super.key,
    required this.message,
  });

  final String message;

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ScreenShell(
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RotationTransition(
                  turns: _controller,
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(
                        colors: [
                          Color(0xFF1ED760),
                          Color(0xFFFF7A59),
                          Color(0xFF1ED760),
                        ],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x331ED760),
                          blurRadius: 26,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.graphic_eq_rounded, size: 34),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Generando tu reto musical',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.message,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizView extends StatelessWidget {
  const _QuizView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SpotiquizController>();
    final question = controller.currentQuestion;
    final theme = Theme.of(context);

    if (question == null) {
      return const SizedBox.shrink();
    }

    return _ScreenShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBar(
            title: 'Spotiquiz',
            subtitle: 'Pregunta ${controller.currentIndex + 1} de ${controller.totalQuestions}',
            trailing: Text(
              controller.scoreLabel,
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: controller.progressValue,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: Colors.white.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MiniTag(label: question.category.label),
                      _MiniTag(label: question.difficulty.label),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(question.prompt, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 20),
                  ...question.options.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OptionTile(question: question, option: option),
                    ),
                  ),
                  if (controller.hasAnsweredCurrent) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6FBF6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        question.funFact,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.hasAnsweredCurrent ? controller.nextQuestion : null,
            child: Text(
              controller.currentIndex == controller.totalQuestions - 1
                  ? 'Ver resultado'
                  : 'Siguiente',
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SpotiquizController>();
    final session = controller.quizSession;
    final theme = Theme.of(context);

    if (session == null) {
      return const SizedBox.shrink();
    }

    return _ScreenShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBar(
            title: 'Resultado',
            subtitle: session.profile.displayName,
            trailing: IconButton(
              onPressed: controller.signOut,
              icon: const Icon(Icons.logout_rounded),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(controller.resultLevel, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  Text(
                    controller.scoreLabel,
                    style: theme.textTheme.headlineLarge?.copyWith(fontSize: 52),
                  ),
                  const SizedBox(height: 12),
                  Text(controller.resultSummary, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16181C),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tarjeta compartible',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Saque ${controller.scoreLabel} en Spotiquiz.\nTop artist: ${session.topArtistName}\nGenero dominante: ${session.dominantGenre}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Top tracks para escuchar', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          ...session.topTracksSnapshot.map(
            (track) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: _AvatarArt(
                    imageUrl: track.imageUrl,
                    size: 54,
                    icon: Icons.album_rounded,
                  ),
                  title: Text(track.name),
                  subtitle: Text(track.subtitle),
                  trailing: IconButton(
                    onPressed: track.previewUrl == null
                        ? null
                        : () => controller.togglePreview(track.previewUrl),
                    icon: Icon(
                      controller.playingPreviewUrl == track.previewUrl
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: controller.shareResults,
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('Compartir resultado'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: controller.restartQuiz,
            child: const Text('Generar otro quiz'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SpotiquizController>();
    final theme = Theme.of(context);
    return _ScreenShell(
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48),
                const SizedBox(height: 16),
                Text(
                  'No pude generar el quiz',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  controller.errorMessage ?? 'Error desconocido',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: controller.startQuizFlow,
                  child: const Text('Intentar de nuevo'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: controller.signOut,
                  child: const Text('Volver al inicio'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configura tu app de Spotify', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              'Crea una app en Spotify for Developers y agrega este redirect URI: ${SpotifyConfig.redirectUri}',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            SelectableText(
              'flutter run --dart-define=SPOTIFY_CLIENT_ID=tu_client_id --dart-define=SPOTIFY_REDIRECT_URI=${SpotifyConfig.redirectUri}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailingChildren = trailing == null ? const <Widget>[] : <Widget>[trailing!];
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        ...trailingChildren,
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.question,
    required this.option,
  });

  final QuizQuestion question;
  final QuizOption option;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SpotiquizController>();
    final selected = controller.selectedOptionId == option.id;
    final answered = controller.hasAnsweredCurrent;
    final isCorrect = question.correctOptionId == option.id;

    Color? background;
    BorderSide? border;
    if (answered && selected && isCorrect) {
      background = const Color(0xFFE6F9EA);
      border = const BorderSide(color: Color(0xFF1ED760), width: 1.4);
    } else if (answered && selected && !isCorrect) {
      background = const Color(0xFFFFE8E2);
      border = const BorderSide(color: Color(0xFFFF7A59), width: 1.4);
    } else if (answered && isCorrect) {
      background = const Color(0xFFF2FBF3);
      border = const BorderSide(color: Color(0x661ED760), width: 1.2);
    } else if (selected) {
      background = Colors.white;
      border = const BorderSide(color: Color(0xFF16181C), width: 1.4);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: answered ? null : () => controller.selectOption(option.id),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background ?? Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.fromBorderSide(
            border ?? const BorderSide(color: Color(0x1416181C)),
          ),
        ),
        child: Row(
          children: [
            _AvatarArt(
              imageUrl: option.imageUrl,
              size: 52,
              icon: Icons.music_note_rounded,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.title),
                  if (option.subtitle case final subtitle?)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
            if (option.previewUrl case final preview?)
              IconButton(
                onPressed: () => controller.togglePreview(preview),
                icon: Icon(
                  controller.playingPreviewUrl == preview
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF6EA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}

class _AvatarArt extends StatelessWidget {
  const _AvatarArt({
    required this.imageUrl,
    required this.size,
    required this.icon,
  });

  final String? imageUrl;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size / 3);
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF16181C),
          borderRadius: radius,
        ),
        child: Icon(icon, color: Colors.white),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFF16181C),
              borderRadius: radius,
            ),
            child: Icon(icon, color: Colors.white),
          );
        },
      ),
    );
  }
}
