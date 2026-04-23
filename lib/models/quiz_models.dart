import 'spotify_models.dart';

enum QuizCategory {
  artists('Artistas'),
  tracks('Canciones'),
  genres('Generos'),
  overlap('Cruces'),
  recent('Reciente');

  const QuizCategory(this.label);

  final String label;
}

enum QuizDifficulty {
  easy('Facil'),
  medium('Media'),
  hard('Dificil');

  const QuizDifficulty(this.label);

  final String label;
}

class QuizOption {
  QuizOption({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.previewUrl,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? previewUrl;
}

class QuizQuestion {
  QuizQuestion({
    required this.id,
    required this.prompt,
    required this.category,
    required this.difficulty,
    required this.options,
    required this.correctOptionId,
    required this.funFact,
  });

  final String id;
  final String prompt;
  final QuizCategory category;
  final QuizDifficulty difficulty;
  final List<QuizOption> options;
  final String correctOptionId;
  final String funFact;

  bool isCorrect(String? optionId) => optionId == correctOptionId;
}

class QuizDataBundle {
  QuizDataBundle({
    required this.profile,
    required this.topArtists,
    required this.topTracks,
    required this.recentlyPlayed,
  });

  final SpotifyUserProfile profile;
  final Map<SpotifyTimeRange, List<SpotifyArtist>> topArtists;
  final Map<SpotifyTimeRange, List<SpotifyTrack>> topTracks;
  final List<RecentlyPlayedItem> recentlyPlayed;
}

class QuizSession {
  QuizSession({
    required this.profile,
    required this.questions,
    required this.topTracksSnapshot,
    required this.dominantGenre,
    required this.topArtistName,
  });

  final SpotifyUserProfile profile;
  final List<QuizQuestion> questions;
  final List<SpotifyTrack> topTracksSnapshot;
  final String dominantGenre;
  final String topArtistName;
}
