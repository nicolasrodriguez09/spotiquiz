import 'dart:math';

import '../models/quiz_models.dart';
import '../models/spotify_models.dart';

class QuizGenerationException implements Exception {
  QuizGenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class QuizGenerator {
  QuizSession generate(QuizDataBundle bundle) {
    final shortArtists = bundle.topArtists[SpotifyTimeRange.shortTerm] ?? const [];
    final mediumArtists =
        bundle.topArtists[SpotifyTimeRange.mediumTerm] ?? const [];
    final longArtists = bundle.topArtists[SpotifyTimeRange.longTerm] ?? const [];
    final shortTracks = bundle.topTracks[SpotifyTimeRange.shortTerm] ?? const [];
    final mediumTracks =
        bundle.topTracks[SpotifyTimeRange.mediumTerm] ?? const [];
    final longTracks = bundle.topTracks[SpotifyTimeRange.longTerm] ?? const [];
    final recent = bundle.recentlyPlayed;

    if (shortArtists.length < 4 || shortTracks.length < 4) {
      throw QuizGenerationException(
        'Tu cuenta todavia no tiene suficiente historial para armar un quiz solido.',
      );
    }

    final dominantGenre = _findDominantGenre(shortArtists);
    final topArtist = shortArtists.first.name;

    final questions = <QuizQuestion>[
      _buildTopArtistQuestion(shortArtists, mediumArtists, longArtists),
      _buildTopTrackQuestion(shortTracks, mediumTracks, longTracks, recent),
      _buildGenreQuestion(shortArtists, dominantGenre),
      _buildOverlapQuestion(shortArtists, longArtists, mediumArtists),
      _buildMissingArtistQuestion(shortArtists, mediumArtists, longArtists, recent),
    ];

    return QuizSession(
      profile: bundle.profile,
      questions: questions,
      topTracksSnapshot: shortTracks.take(5).toList(),
      dominantGenre: dominantGenre,
      topArtistName: topArtist,
    );
  }

  QuizQuestion _buildTopArtistQuestion(
    List<SpotifyArtist> shortArtists,
    List<SpotifyArtist> mediumArtists,
    List<SpotifyArtist> longArtists,
  ) {
    final correct = shortArtists.first;
    final options = _artistOptions(
      correct: correct,
      pool: [
        ...shortArtists.skip(1).take(6),
        ...mediumArtists.take(4),
        ...longArtists.take(4),
      ],
      count: 4,
    );
    return QuizQuestion(
      id: 'top-artist-short',
      prompt: 'Cual fue tu artista mas escuchado en el corto plazo?',
      category: QuizCategory.artists,
      difficulty: QuizDifficulty.easy,
      options: options,
      correctOptionId: correct.id,
      funFact:
          '${correct.name} lidera tu momento actual. Tu algoritmo anda bastante alineado con ese sonido.',
    );
  }

  QuizQuestion _buildTopTrackQuestion(
    List<SpotifyTrack> shortTracks,
    List<SpotifyTrack> mediumTracks,
    List<SpotifyTrack> longTracks,
    List<RecentlyPlayedItem> recent,
  ) {
    final candidatePool = shortTracks.take(min(10, shortTracks.length)).toList();
    final correct = candidatePool[_random.nextInt(candidatePool.length)];
    final shortTopIds = candidatePool.map((track) => track.id).toSet();

    final distractors = [
      ...mediumTracks.where((track) => !shortTopIds.contains(track.id)),
      ...longTracks.where((track) => !shortTopIds.contains(track.id)),
      ...recent
          .map((item) => item.track)
          .where((track) => !shortTopIds.contains(track.id)),
    ];

    final options = _trackOptions(
      correct: correct,
      pool: distractors,
      count: 4,
    );

    return QuizQuestion(
      id: 'top-track-10',
      prompt: 'Cual de estas canciones si estuvo en tu top 10 reciente?',
      category: QuizCategory.tracks,
      difficulty: QuizDifficulty.medium,
      options: options,
      correctOptionId: correct.id,
      funFact:
          '"${correct.name}" si se metio en tu top 10. No era una escucha casual.',
    );
  }

  QuizQuestion _buildGenreQuestion(
    List<SpotifyArtist> shortArtists,
    String dominantGenre,
  ) {
    final frequencies = _genreScores(shortArtists);
    final distractorGenres = frequencies.keys
        .where((genre) => genre != dominantGenre)
        .take(8)
        .toList();

    const fallbackGenres = [
      'indie pop',
      'latin pop',
      'reggaeton',
      'alternative rock',
      'dance pop',
      'bedroom pop',
    ];

    for (final genre in fallbackGenres) {
      if (genre != dominantGenre && !distractorGenres.contains(genre)) {
        distractorGenres.add(genre);
      }
      if (distractorGenres.length >= 3) {
        break;
      }
    }

    final options = _stringOptions(
      correct: dominantGenre,
      pool: distractorGenres,
      count: 4,
      prefix: 'genre',
    );

    return QuizQuestion(
      id: 'dominant-genre',
      prompt: 'Cual es el genero que mas se repite en tu perfil reciente?',
      category: QuizCategory.genres,
      difficulty: QuizDifficulty.easy,
      options: options,
      correctOptionId: 'genre::$dominantGenre',
      funFact:
          'Tu genero dominante ahora mismo es $dominantGenre. Tu historial reciente no lo deja pasar desapercibido.',
    );
  }

  QuizQuestion _buildOverlapQuestion(
    List<SpotifyArtist> shortArtists,
    List<SpotifyArtist> longArtists,
    List<SpotifyArtist> mediumArtists,
  ) {
    final longIds = longArtists.map((artist) => artist.id).toSet();
    final overlap = shortArtists
        .where((artist) => longIds.contains(artist.id))
        .toList();
    if (overlap.isEmpty) {
      return _buildTopArtistQuestion(shortArtists, mediumArtists, longArtists);
    }

    final correct = overlap.first;
    final options = _artistOptions(
      correct: correct,
      pool: [
        ...shortArtists.where((artist) => artist.id != correct.id).take(3),
        ...longArtists.where((artist) => artist.id != correct.id).take(3),
        ...mediumArtists.where((artist) => artist.id != correct.id).take(3),
      ],
      count: 4,
    );

    return QuizQuestion(
      id: 'artist-overlap',
      prompt:
          'Que artista aparece tanto en tu top de corto plazo como en el de largo plazo?',
      category: QuizCategory.overlap,
      difficulty: QuizDifficulty.hard,
      options: options,
      correctOptionId: correct.id,
      funFact:
          '${correct.name} no es un capricho temporal: se mantiene contigo a corto y largo plazo.',
    );
  }

  QuizQuestion _buildMissingArtistQuestion(
    List<SpotifyArtist> shortArtists,
    List<SpotifyArtist> mediumArtists,
    List<SpotifyArtist> longArtists,
    List<RecentlyPlayedItem> recent,
  ) {
    final topTwenty = shortArtists.take(20).toList();
    final topIds = topTwenty.map((artist) => artist.id).toSet();
    final inTop = topTwenty.take(3).toList();

    SpotifyArtist? outsider;
    for (final artist in [
      ...mediumArtists,
      ...longArtists,
      ...recent
          .expand((item) => item.track.artistNames)
          .map(
            (name) => SpotifyArtist(
              id: 'recent::$name',
              name: name,
              genres: const [],
            ),
          ),
    ]) {
      if (!topIds.contains(artist.id) &&
          inTop.every((candidate) => candidate.name != artist.name)) {
        outsider = artist;
        break;
      }
    }

    outsider ??= SpotifyArtist(
      id: 'outsider::Radiohead',
      name: 'Radiohead',
      genres: const ['alternative rock'],
    );

    final combined = [...inTop, outsider]..shuffle(_random);
    final options = combined
        .map(
          (artist) => QuizOption(
            id: artist.id,
            title: artist.name,
            subtitle: artist.genres.isEmpty ? null : artist.genres.first,
            imageUrl: artist.imageUrl,
          ),
        )
        .toList();

    return QuizQuestion(
      id: 'artist-not-in-top20',
      prompt: 'Cual de estos artistas NO esta en tu top 20 actual?',
      category: QuizCategory.artists,
      difficulty: QuizDifficulty.medium,
      options: options,
      correctOptionId: outsider.id,
      funFact:
          '${outsider.name} fue el senuelo. Tus favoritos actuales iban por otro lado.',
    );
  }

  String _findDominantGenre(List<SpotifyArtist> artists) {
    final scores = _genreScores(artists);
    if (scores.isEmpty) {
      return 'sonidos alternativos';
    }
    return scores.entries.first.key;
  }

  Map<String, int> _genreScores(List<SpotifyArtist> artists) {
    final scores = <String, int>{};
    for (var index = 0; index < artists.length; index++) {
      final artist = artists[index];
      final weight = max(1, 12 - index);
      for (final genre in artist.genres.take(3)) {
        scores.update(
          genre.toLowerCase(),
          (value) => value + weight,
          ifAbsent: () => weight,
        );
      }
    }
    final orderedEntries = scores.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    return {for (final entry in orderedEntries) entry.key: entry.value};
  }

  List<QuizOption> _artistOptions({
    required SpotifyArtist correct,
    required List<SpotifyArtist> pool,
    required int count,
  }) {
    final unique = <String, SpotifyArtist>{correct.id: correct};
    for (final artist in pool) {
      unique.putIfAbsent(artist.id, () => artist);
    }
    final selected = unique.values.take(count).toList();
    if (selected.length < count) {
      throw QuizGenerationException('No hay suficientes artistas para generar opciones.');
    }
    selected.shuffle(_random);
    return selected
        .map(
          (artist) => QuizOption(
            id: artist.id,
            title: artist.name,
            subtitle: artist.genres.isEmpty ? null : artist.genres.first,
            imageUrl: artist.imageUrl,
          ),
        )
        .toList();
  }

  List<QuizOption> _trackOptions({
    required SpotifyTrack correct,
    required List<SpotifyTrack> pool,
    required int count,
  }) {
    final unique = <String, SpotifyTrack>{correct.id: correct};
    for (final track in pool) {
      unique.putIfAbsent(track.id, () => track);
      if (unique.length >= count) {
        break;
      }
    }
    final selected = unique.values.take(count).toList();
    if (selected.length < count) {
      final fallback = <SpotifyTrack>[
        correct,
        ...pool.where((track) => track.id != correct.id).take(count - 1),
      ];
      if (fallback.length < count) {
        throw QuizGenerationException('No hay suficientes canciones para armar el quiz.');
      }
      fallback.shuffle(_random);
      return fallback
          .map(
            (track) => QuizOption(
              id: track.id,
              title: track.name,
              subtitle: track.subtitle,
              imageUrl: track.imageUrl,
              previewUrl: track.previewUrl,
            ),
          )
          .toList();
    }
    selected.shuffle(_random);
    return selected
        .map(
          (track) => QuizOption(
            id: track.id,
            title: track.name,
            subtitle: track.subtitle,
            imageUrl: track.imageUrl,
            previewUrl: track.previewUrl,
          ),
        )
        .toList();
  }

  List<QuizOption> _stringOptions({
    required String correct,
    required List<String> pool,
    required int count,
    required String prefix,
  }) {
    final options = <String>[correct];
    for (final entry in pool) {
      if (!options.contains(entry)) {
        options.add(entry);
      }
      if (options.length >= count) {
        break;
      }
    }
    if (options.length < count) {
      throw QuizGenerationException('No hay suficientes generos para generar opciones.');
    }
    options.shuffle(_random);
    return options
        .map(
          (value) => QuizOption(
            id: '$prefix::$value',
            title: _capitalize(value),
          ),
        )
        .toList();
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  final Random _random = Random();
}
