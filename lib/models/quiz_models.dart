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

class ListeningStatsSummary {
  ListeningStatsSummary({
    required this.topArtistShortTerm,
    required this.topTrackShortTerm,
    required this.dominantGenre,
    required this.topGenres,
    required this.genreRanking,
    required this.topArtistsShortTerm,
    required this.topTracksShortTerm,
    required this.recentArtistRanking,
    required this.recentTrackRanking,
    required this.stableArtists,
    required this.recentPlaysAnalyzed,
    required this.distinctRecentArtists,
    required this.distinctRecentTracks,
    required this.recentListeningMinutes,
    this.mostRecentPlay,
    this.stableArtist,
  });

  final SpotifyArtist topArtistShortTerm;
  final SpotifyTrack topTrackShortTerm;
  final String dominantGenre;
  final List<String> topGenres;
  final List<GenreStat> genreRanking;
  final List<SpotifyArtist> topArtistsShortTerm;
  final List<SpotifyTrack> topTracksShortTerm;
  final List<ArtistPlayStat> recentArtistRanking;
  final List<TrackPlayStat> recentTrackRanking;
  final List<SpotifyArtist> stableArtists;
  final int recentPlaysAnalyzed;
  final int distinctRecentArtists;
  final int distinctRecentTracks;
  final int recentListeningMinutes;
  final RecentlyPlayedItem? mostRecentPlay;
  final SpotifyArtist? stableArtist;
}

class GenreStat {
  GenreStat({
    required this.genre,
    required this.score,
  });

  final String genre;
  final int score;
}

class ArtistPlayStat {
  ArtistPlayStat({
    required this.name,
    required this.count,
    this.imageUrl,
  });

  final String name;
  final int count;
  final String? imageUrl;
}

class TrackPlayStat {
  TrackPlayStat({
    required this.name,
    required this.artistLabel,
    required this.count,
    this.imageUrl,
  });

  final String name;
  final String artistLabel;
  final int count;
  final String? imageUrl;
}

class QuizSession {
  QuizSession({
    required this.profile,
    required this.questions,
    required this.topTracksSnapshot,
    required this.dominantGenre,
    required this.topArtistName,
    required this.statsSummary,
  });

  final SpotifyUserProfile profile;
  final List<QuizQuestion> questions;
  final List<SpotifyTrack> topTracksSnapshot;
  final String dominantGenre;
  final String topArtistName;
  final ListeningStatsSummary statsSummary;
}
