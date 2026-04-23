import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';

import '../core/spotify_config.dart';
import '../models/quiz_models.dart';
import '../models/spotify_models.dart';
import '../services/quiz_generator.dart';
import '../services/spotify_api_service.dart';
import '../services/spotify_auth_service.dart';

enum SpotiquizViewState {
  signedOut,
  authenticating,
  generatingQuiz,
  quiz,
  stats,
  results,
  error,
}

class SpotiquizController extends ChangeNotifier {
  SpotiquizController({
    required SpotifyAuthService authService,
    required SpotifyApiService apiService,
    required QuizGenerator quizGenerator,
  }) : _authService = authService,
       _apiService = apiService,
       _quizGenerator = quizGenerator {
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed &&
          _playingPreviewUrl != null) {
        _playingPreviewUrl = null;
        notifyListeners();
      }
    });
  }

  final SpotifyAuthService _authService;
  final SpotifyApiService _apiService;
  final QuizGenerator _quizGenerator;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final StreamSubscription<PlayerState> _playerStateSubscription;

  SpotiquizViewState _viewState = SpotiquizViewState.signedOut;
  SpotifyAuthSession? _session;
  QuizDataBundle? _bundle;
  QuizSession? _quizSession;
  final Map<int, String> _selectedOptions = {};
  String? _errorMessage;
  String _loadingMessage = 'Preparando tu quiz...';
  int _currentIndex = 0;
  String? _playingPreviewUrl;
  bool _quizFinished = false;

  SpotiquizViewState get viewState => _viewState;
  String? get errorMessage => _errorMessage;
  String get loadingMessage => _loadingMessage;
  QuizSession? get quizSession => _quizSession;
  ListeningStatsSummary? get statsSummary => _quizSession?.statsSummary;
  bool get needsSetup => !SpotifyConfig.isConfigured;
  int get currentIndex => _currentIndex;
  String? get playingPreviewUrl => _playingPreviewUrl;

  QuizQuestion? get currentQuestion {
    if (_quizSession == null || _currentIndex >= _quizSession!.questions.length) {
      return null;
    }
    return _quizSession!.questions[_currentIndex];
  }

  int get totalQuestions => _quizSession?.questions.length ?? 0;
  String? get selectedOptionId => _selectedOptions[_currentIndex];
  int get correctAnswers {
    final session = _quizSession;
    if (session == null) {
      return 0;
    }
    var total = 0;
    for (var index = 0; index < session.questions.length; index++) {
      if (session.questions[index].isCorrect(_selectedOptions[index])) {
        total++;
      }
    }
    return total;
  }

  bool get hasAnsweredCurrent => selectedOptionId != null;
  double get progressValue {
    if (totalQuestions == 0) {
      return 0;
    }
    return (_currentIndex + 1) / totalQuestions;
  }

  String get scoreLabel => '$correctAnswers/$totalQuestions';

  String get resultLevel {
    final ratio = totalQuestions == 0 ? 0 : correctAnswers / totalQuestions;
    if (ratio >= 0.9) {
      return 'Oraculo del algoritmo';
    }
    if (ratio >= 0.7) {
      return 'Archivista musical';
    }
    if (ratio >= 0.5) {
      return 'Fan consistente';
    }
    return 'Explorador distraido';
  }

  String get resultSummary {
    final ratio = totalQuestions == 0 ? 0 : correctAnswers / totalQuestions;
    final session = _quizSession;
    if (session == null) {
      return '';
    }
    if (ratio >= 0.8) {
      return 'Te conoces bastante bien. ${session.topArtistName} y el ${session.dominantGenre} estaban demasiado marcados como para perderlos.';
    }
    if (ratio >= 0.5) {
      return 'Tu memoria musical es buena, pero tus canciones favoritas se te escapan mas que tus artistas.';
    }
    return 'Escuchas mucho, pero tu algoritmo sabe mas de ti que tu mismo. Eso tambien tiene encanto.';
  }

  String get shareText {
    final session = _quizSession;
    if (session == null) {
      return 'Estoy jugando Spotiquiz.';
    }
    return 'Saque $scoreLabel en Spotiquiz. Mi top artist es ${session.topArtistName} y mi genero dominante es ${session.dominantGenre}.';
  }

  bool get quizFinished => _quizFinished;

  Future<void> startQuizFlow() async {
    if (needsSetup) {
      _errorMessage =
          'Falta el client id de Spotify. Configura los dart defines antes de iniciar.';
      notifyListeners();
      return;
    }

    try {
      _errorMessage = null;
      _setViewState(SpotiquizViewState.authenticating);
      _session = await _authService.authenticate();
      await _generateQuiz();
    } catch (error) {
      _errorMessage = error.toString();
      _setViewState(SpotiquizViewState.error);
    }
  }

  void selectOption(String optionId) {
    _selectedOptions[_currentIndex] = optionId;
    notifyListeners();
  }

  void nextQuestion() {
    if (!hasAnsweredCurrent || _quizSession == null) {
      return;
    }

    final lastQuestionIndex = _quizSession!.questions.length - 1;
    if (_currentIndex >= lastQuestionIndex) {
      _quizFinished = true;
      _setViewState(SpotiquizViewState.results);
      return;
    }

    _currentIndex += 1;
    notifyListeners();
  }

  void restartQuiz() {
    final bundle = _bundle;
    if (bundle == null) {
      _reset();
      return;
    }
    try {
      _quizSession = _quizGenerator.generate(bundle);
      _selectedOptions.clear();
      _currentIndex = 0;
      _quizFinished = false;
      _errorMessage = null;
      _setViewState(SpotiquizViewState.quiz);
    } catch (error) {
      _errorMessage = error.toString();
      _setViewState(SpotiquizViewState.error);
    }
  }

  Future<void> shareResults() async {
    await SharePlus.instance.share(
      ShareParams(
        text: shareText,
        subject: 'Mi resultado en Spotiquiz',
      ),
    );
  }

  void openStats() {
    if (_quizSession == null) {
      return;
    }
    _setViewState(SpotiquizViewState.stats);
  }

  void openQuiz() {
    if (_quizSession == null) {
      return;
    }
    _setViewState(SpotiquizViewState.quiz);
  }

  void openResults() {
    if (_quizSession == null || !_quizFinished) {
      return;
    }
    _setViewState(SpotiquizViewState.results);
  }

  Future<void> togglePreview(String? previewUrl) async {
    if (previewUrl == null || previewUrl.isEmpty) {
      return;
    }

    if (_playingPreviewUrl == previewUrl) {
      await _audioPlayer.stop();
      _playingPreviewUrl = null;
      notifyListeners();
      return;
    }

    try {
      await _audioPlayer.setUrl(previewUrl);
      await _audioPlayer.play();
      _playingPreviewUrl = previewUrl;
      notifyListeners();
    } catch (_) {
      _playingPreviewUrl = null;
      notifyListeners();
    }
  }

  void signOut() {
    _reset();
    notifyListeners();
  }

  Future<void> _generateQuiz() async {
    try {
      _setViewState(SpotiquizViewState.generatingQuiz);
      _loadingMessage = 'Leyendo tu perfil musical...';
      notifyListeners();
      final accessToken = await _freshAccessToken();
      final profile = await _apiService.getCurrentUserProfile(accessToken);

      _loadingMessage = 'Analizando tus artistas favoritos...';
      notifyListeners();
      final topArtistsEntries = await Future.wait([
        _apiService.getTopArtists(accessToken, SpotifyTimeRange.shortTerm),
        _apiService.getTopArtists(accessToken, SpotifyTimeRange.mediumTerm),
        _apiService.getTopArtists(accessToken, SpotifyTimeRange.longTerm),
      ]);

      _loadingMessage = 'Revisando tus canciones top...';
      notifyListeners();
      final topTracksEntries = await Future.wait([
        _apiService.getTopTracks(accessToken, SpotifyTimeRange.shortTerm),
        _apiService.getTopTracks(accessToken, SpotifyTimeRange.mediumTerm),
        _apiService.getTopTracks(accessToken, SpotifyTimeRange.longTerm),
      ]);

      _loadingMessage = 'Buscando tus pistas mas recientes...';
      notifyListeners();
      final recent = await _apiService
          .getRecentlyPlayed(accessToken, limit: 50)
          .catchError((_) => <RecentlyPlayedItem>[]);

      _loadingMessage = 'Preparando tu reto musical...';
      notifyListeners();
      _bundle = QuizDataBundle(
        profile: profile,
        topArtists: {
          SpotifyTimeRange.shortTerm: topArtistsEntries[0],
          SpotifyTimeRange.mediumTerm: topArtistsEntries[1],
          SpotifyTimeRange.longTerm: topArtistsEntries[2],
        },
        topTracks: {
          SpotifyTimeRange.shortTerm: topTracksEntries[0],
          SpotifyTimeRange.mediumTerm: topTracksEntries[1],
          SpotifyTimeRange.longTerm: topTracksEntries[2],
        },
        recentlyPlayed: recent,
      );
      _quizSession = _quizGenerator.generate(_bundle!);
      _selectedOptions.clear();
      _currentIndex = 0;
      _quizFinished = false;
      _setViewState(SpotiquizViewState.quiz);
    } catch (error) {
      _errorMessage = error.toString();
      _setViewState(SpotiquizViewState.error);
    }
  }

  Future<String> _freshAccessToken() async {
    final session = _session;
    if (session == null) {
      throw StateError('No hay sesion de Spotify activa.');
    }
    _session = await _authService.refreshIfNeeded(session);
    return _session!.accessToken;
  }

  void _setViewState(SpotiquizViewState next) {
    _viewState = next;
    notifyListeners();
  }

  void _reset() {
    _viewState = SpotiquizViewState.signedOut;
    _session = null;
    _bundle = null;
    _quizSession = null;
    _selectedOptions.clear();
    _errorMessage = null;
    _loadingMessage = 'Preparando tu quiz...';
    _currentIndex = 0;
    _playingPreviewUrl = null;
    _quizFinished = false;
    _audioPlayer.stop();
  }

  @override
  void dispose() {
    _playerStateSubscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
