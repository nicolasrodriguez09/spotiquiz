import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/spotiquiz_controller.dart';
import '../core/spotify_config.dart';
import '../models/quiz_models.dart';
import '../models/spotify_models.dart';

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
                  SpotiquizViewState.stats => _StatsView(
                    key: const ValueKey('stats'),
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
          const SizedBox(height: 16),
          _LandingHero(controller: controller, theme: theme),
          const SizedBox(height: 18),
          Row(
            children: const [
              Expanded(
                child: _LandingStatCard(
                  tone: Color(0xFF16181C),
                  value: '1 login',
                  label: 'Conecta Spotify',
                  textColor: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _LandingStatCard(
                  tone: Color(0xFFFFD9BF),
                  value: '10 rounds',
                  label: 'Quiz rapido',
                ),
              ),
            ],
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
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Historial real'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _LandingHero extends StatelessWidget {
  const _LandingHero({
    required this.controller,
    required this.theme,
  });

  final SpotiquizController controller;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16181C),
        borderRadius: BorderRadius.circular(36),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2216181C),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -18,
            child: Container(
              width: 130,
              height: 130,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF1ED760), Color(0x44FFFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            left: -24,
            bottom: -34,
            child: Container(
              width: 164,
              height: 164,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFF7A59), Color(0x00FF7A59)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'SPOTIQUIZ',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1ED760),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.multitrack_audio_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'Tu Spotify te conoce.\nLa pregunta es si tu tambien.',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 36,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Conecta Spotify y responde.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _PillAccent(
                      color: Color(0xFF1ED760),
                      icon: Icons.person_search_rounded,
                      label: 'Top artistas',
                    ),
                    _PillAccent(
                      color: Color(0xFFFF7A59),
                      icon: Icons.album_rounded,
                      label: 'Top tracks',
                    ),
                    _PillAccent(
                      color: Color(0xFFEED86C),
                      icon: Icons.auto_graph_rounded,
                      label: 'Cruces y generos',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      const _BeatBars(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quiz instantaneo',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.needsSetup
                                  ? 'Falta configurar Spotify.'
                                  : 'Top artists, tracks y recientes.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: controller.openStats,
                  icon: const Icon(Icons.bar_chart_rounded),
                  tooltip: 'Ver resumen',
                ),
                Text(
                  controller.scoreLabel,
                  style: theme.textTheme.titleLarge,
                ),
              ],
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: controller.openStats,
                  icon: const Icon(Icons.bar_chart_rounded),
                  tooltip: 'Ver resumen',
                ),
                IconButton(
                  onPressed: controller.signOut,
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
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

class _StatsView extends StatelessWidget {
  const _StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SpotiquizController>();
    final session = controller.quizSession;
    final stats = controller.statsSummary;
    final theme = Theme.of(context);

    if (session == null || stats == null) {
      return const SizedBox.shrink();
    }

    return _ScreenShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBar(
            title: 'Resumen',
            subtitle: session.profile.displayName,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: controller.quizFinished
                      ? controller.openResults
                      : controller.openQuiz,
                  icon: Icon(
                    controller.quizFinished
                        ? Icons.assignment_turned_in_rounded
                        : Icons.quiz_rounded,
                  ),
                  tooltip: controller.quizFinished ? 'Ver resultado' : 'Volver al quiz',
                ),
                IconButton(
                  onPressed: controller.signOut,
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF16181C),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ultimo mes',
                  style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                Text(
                  '${session.profile.displayName} ranked',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Top artist: ${stats.topArtistShortTerm.name}',
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (session.profile.product case final product?)
                      _MiniMetaPill(label: _prettyProduct(product)),
                    if (session.profile.country case final country?)
                      _MiniMetaPill(label: country),
                    _MiniMetaPill(label: '${stats.recentPlaysAnalyzed} recientes'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Top track',
                  value: stats.topTrackShortTerm.name,
                  subtitle: stats.topTrackShortTerm.subtitle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Genero',
                  value: _prettyLabel(stats.dominantGenre),
                  subtitle: 'Dominante ahora',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Duracion',
                  value: '${stats.recentListeningMinutes} min',
                  subtitle: 'Solo recientes analizados',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Artistas',
                  value: '${stats.distinctRecentArtists}',
                  subtitle: 'Distintos en recientes',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _RankSection<SpotifyArtist>(
            title: 'Ranking de artistas',
            subtitle: 'Ultimas 4 semanas',
            items: stats.topArtistsShortTerm,
            builder: (artist, index) => _RankedArtistTile(
              rank: index + 1,
              artist: artist,
            ),
          ),
          const SizedBox(height: 16),
          _RankSection<SpotifyTrack>(
            title: 'Ranking de tracks',
            subtitle: 'Top actual',
            items: stats.topTracksShortTerm,
            builder: (track, index) => _RankedTrackTile(
              rank: index + 1,
              title: track.name,
              subtitle: track.subtitle,
              imageUrl: track.imageUrl,
            ),
          ),
          const SizedBox(height: 16),
          _RankSection<GenreStat>(
            title: 'Ranking de generos',
            subtitle: 'Estimado desde tus artistas top',
            items: stats.genreRanking,
            builder: (genre, index) => _RankedTextTile(
              rank: index + 1,
              title: _prettyLabel(genre.genre),
              subtitle: 'Score ${genre.score}',
            ),
          ),
          const SizedBox(height: 16),
          _RankSection<ArtistPlayStat>(
            title: 'Artistas recientes',
            subtitle: 'Frecuencia en recientes',
            items: stats.recentArtistRanking,
            builder: (artist, index) => _RankedCountTile(
              rank: index + 1,
              title: artist.name,
              subtitle: '${artist.count} reproducciones',
              imageUrl: artist.imageUrl,
            ),
          ),
          const SizedBox(height: 16),
          _RankSection<TrackPlayStat>(
            title: 'Tracks recientes',
            subtitle: 'Mas repetidos en recientes',
            items: stats.recentTrackRanking,
            builder: (track, index) => _RankedCountTile(
              rank: index + 1,
              title: track.name,
              subtitle: '${track.artistLabel} · ${track.count} veces',
              imageUrl: track.imageUrl,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Datos extra', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 14),
                  _InfoRow(
                    label: 'Artista estable',
                    value: stats.stableArtist?.name ?? 'No claro aun',
                  ),
                  _InfoRow(
                    label: 'Estables top',
                    value: stats.stableArtists.isEmpty
                        ? 'Sin cruces claros'
                        : stats.stableArtists.take(3).map((artist) => artist.name).join(', '),
                  ),
                  _InfoRow(
                    label: 'Ultimo track',
                    value: stats.mostRecentPlay?.track.name ?? 'Sin datos recientes',
                  ),
                  _InfoRow(
                    label: 'Top 3 generos',
                    value: stats.topGenres.map(_prettyLabel).join(', '),
                  ),
                  _InfoRow(
                    label: 'Minutos escuchados',
                    value: 'Spotify API no entrega ese total real',
                  ),
                ],
              ),
            ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 10),
            Text(value, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(subtitle, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _RankSection<T> extends StatelessWidget {
  const _RankSection({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final List<T> items;
  final Widget Function(T item, int index) builder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 14),
            if (items.isEmpty)
              Text('Sin datos suficientes', style: theme.textTheme.bodyLarge),
            ...items.asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: entry.key == items.length - 1 ? 0 : 10),
                child: builder(entry.value, entry.key),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RankedArtistTile extends StatelessWidget {
  const _RankedArtistTile({
    required this.rank,
    required this.artist,
  });

  final int rank;
  final SpotifyArtist artist;

  @override
  Widget build(BuildContext context) {
    return _RankTileFrame(
      rank: rank,
      imageUrl: artist.imageUrl,
      title: artist.name,
      subtitle: artist.genres.isEmpty ? 'Sin genero' : _prettyLabel(artist.genres.first),
    );
  }
}

class _RankedTrackTile extends StatelessWidget {
  const _RankedTrackTile({
    required this.rank,
    required this.title,
    required this.subtitle,
    this.imageUrl,
  });

  final int rank;
  final String title;
  final String subtitle;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return _RankTileFrame(
      rank: rank,
      imageUrl: imageUrl,
      title: title,
      subtitle: subtitle,
    );
  }
}

class _RankedCountTile extends StatelessWidget {
  const _RankedCountTile({
    required this.rank,
    required this.title,
    required this.subtitle,
    this.imageUrl,
  });

  final int rank;
  final String title;
  final String subtitle;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return _RankTileFrame(
      rank: rank,
      imageUrl: imageUrl,
      title: title,
      subtitle: subtitle,
    );
  }
}

class _RankedTextTile extends StatelessWidget {
  const _RankedTextTile({
    required this.rank,
    required this.title,
    required this.subtitle,
  });

  final int rank;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2E7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _RankBadge(rank: rank),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF16181C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF4D535C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankTileFrame extends StatelessWidget {
  const _RankTileFrame({
    required this.rank,
    required this.title,
    required this.subtitle,
    this.imageUrl,
  });

  final int rank;
  final String title;
  final String subtitle;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2E7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _RankBadge(rank: rank),
          const SizedBox(width: 12),
          _AvatarArt(
            imageUrl: imageUrl,
            size: 46,
            icon: Icons.music_note_rounded,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF16181C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF4D535C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: rank == 1 ? const Color(0xFF1ED760) : const Color(0xFF16181C),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MiniMetaPill extends StatelessWidget {
  const _MiniMetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyLarge),
          ),
        ],
      ),
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

class _LandingStatCard extends StatelessWidget {
  const _LandingStatCard({
    required this.tone,
    required this.value,
    required this.label,
    this.textColor = const Color(0xFF16181C),
  });

  final Color tone;
  final String value;
  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(color: textColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}

class _PillAccent extends StatelessWidget {
  const _PillAccent({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF16181C)),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF16181C),
            ),
          ),
        ],
      ),
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

class _BeatBars extends StatelessWidget {
  const _BeatBars();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: const [
        _BeatBar(height: 18, color: Color(0xFF1ED760)),
        SizedBox(width: 4),
        _BeatBar(height: 28, color: Color(0xFFFF7A59)),
        SizedBox(width: 4),
        _BeatBar(height: 22, color: Color(0xFFEED86C)),
        SizedBox(width: 4),
        _BeatBar(height: 34, color: Color(0xFF1ED760)),
      ],
    );
  }
}

class _BeatBar extends StatelessWidget {
  const _BeatBar({
    required this.height,
    required this.color,
  });

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

String _prettyLabel(String value) {
  if (value.isEmpty) {
    return value;
  }
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

String _prettyProduct(String value) {
  switch (value) {
    case 'premium':
      return 'Premium';
    case 'free':
      return 'Free';
    case 'open':
      return 'Open';
    default:
      return _prettyLabel(value);
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
