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
      _buildArtistInTopTenQuestion(
        shortArtists,
        mediumArtists,
        longArtists,
        recent,
      ),
      _buildMissingArtistQuestion(shortArtists, mediumArtists, longArtists, recent),
      _buildTopTrackLeaderQuestion(shortTracks, mediumTracks, longTracks),
      _buildTopTrackQuestion(shortTracks, mediumTracks, longTracks, recent),
      _buildMissingTrackQuestion(shortTracks, mediumTracks, longTracks, recent),
      _buildGenreQuestion(shortArtists, dominantGenre),
      _buildGenreTopThreeQuestion(shortArtists, dominantGenre),
      _buildOverlapQuestion(shortArtists, longArtists, mediumArtists),
      _buildShortMediumOverlapQuestion(shortArtists, mediumArtists, longArtists),
      _buildRecentArtistLeaderQuestion(recent, shortArtists, mediumArtists),
    ]..shuffle(_random);

    return QuizSession(
      profile: bundle.profile,
      questions: questions,
      topTracksSnapshot: shortTracks.take(5).toList(),
      dominantGenre: dominantGenre,
      topArtistName: topArtist,
      statsSummary: _buildStatsSummary(
        shortArtists: shortArtists,
        longArtists: longArtists,
        shortTracks: shortTracks,
        recent: recent,
        dominantGenre: dominantGenre,
      ),
    );
  }

  ListeningStatsSummary _buildStatsSummary({
    required List<SpotifyArtist> shortArtists,
    required List<SpotifyArtist> longArtists,
    required List<SpotifyTrack> shortTracks,
    required List<RecentlyPlayedItem> recent,
    required String dominantGenre,
  }) {
    final stableArtists = _findStableArtists(shortArtists, longArtists);
    final stableArtist = stableArtists.isEmpty ? null : stableArtists.first;
    final recentArtistNames = recent
        .expand((item) => item.track.artistNames)
        .toSet();
    final recentTrackIds = recent.map((item) => item.track.id).toSet();
    final genreScores = _genreScores(shortArtists);
    final topGenres = genreScores.keys.take(3).toList();
    final recentArtistRanking = _buildRecentArtistRanking(recent);
    final recentTrackRanking = _buildRecentTrackRanking(recent);
    final recentListeningMinutes = recent.fold<int>(
      0,
      (total, item) => total + item.track.durationMs,
    ) ~/
        60000;

    return ListeningStatsSummary(
      topArtistShortTerm: shortArtists.first,
      topTrackShortTerm: shortTracks.first,
      dominantGenre: dominantGenre,
      topGenres: topGenres,
      genreRanking: genreScores.entries
          .take(5)
          .map((entry) => GenreStat(genre: entry.key, score: entry.value))
          .toList(),
      topArtistsShortTerm: shortArtists.take(5).toList(),
      topTracksShortTerm: shortTracks.take(5).toList(),
      recentArtistRanking: recentArtistRanking,
      recentTrackRanking: recentTrackRanking,
      stableArtists: stableArtists.take(5).toList(),
      recentPlaysAnalyzed: recent.length,
      distinctRecentArtists: recentArtistNames.length,
      distinctRecentTracks: recentTrackIds.length,
      recentListeningMinutes: recentListeningMinutes,
      mostRecentPlay: recent.isEmpty ? null : recent.first,
      stableArtist: stableArtist,
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

  QuizQuestion _buildArtistInTopTenQuestion(
    List<SpotifyArtist> shortArtists,
    List<SpotifyArtist> mediumArtists,
    List<SpotifyArtist> longArtists,
    List<RecentlyPlayedItem> recent,
  ) {
    final topTen = shortArtists.take(min(10, shortArtists.length)).toList();
    final correct = topTen[min(2, topTen.length - 1)];
    final topTenIds = topTen.map((artist) => artist.id).toSet();

    final recentArtists = recent
        .expand((item) => item.track.artistNames)
        .toSet()
        .map(
          (name) => SpotifyArtist(
            id: 'recent-artist::$name',
            name: name,
            genres: const [],
          ),
        )
        .toList();

    final options = _artistOptions(
      correct: correct,
      pool: [
        ...mediumArtists.where((artist) => !topTenIds.contains(artist.id)),
        ...longArtists.where((artist) => !topTenIds.contains(artist.id)),
        ...recentArtists.where((artist) => artist.name != correct.name),
      ],
      count: 4,
    );

    return QuizQuestion(
      id: 'artist-in-top10',
      prompt: 'Cual de estos artistas si aparece en tu top 10 reciente?',
      category: QuizCategory.artists,
      difficulty: QuizDifficulty.medium,
      options: options,
      correctOptionId: correct.id,
      funFact:
          '${correct.name} se mantiene dentro de tu top 10 del ultimo mes.',
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

  QuizQuestion _buildTopTrackLeaderQuestion(
    List<SpotifyTrack> shortTracks,
    List<SpotifyTrack> mediumTracks,
    List<SpotifyTrack> longTracks,
  ) {
    final correct = shortTracks.first;
    final options = _trackOptions(
      correct: correct,
      pool: [
        ...shortTracks.skip(1).take(6),
        ...mediumTracks.take(4),
        ...longTracks.take(4),
      ],
      count: 4,
    );

    return QuizQuestion(
      id: 'top-track-short',
      prompt: 'Cual fue tu track mas escuchado en el corto plazo?',
      category: QuizCategory.tracks,
      difficulty: QuizDifficulty.easy,
      options: options,
      correctOptionId: correct.id,
      funFact:
          '"${correct.name}" fue tu track numero uno del periodo corto.',
    );
  }

  QuizQuestion _buildMissingTrackQuestion(
    List<SpotifyTrack> shortTracks,
    List<SpotifyTrack> mediumTracks,
    List<SpotifyTrack> longTracks,
    List<RecentlyPlayedItem> recent,
  ) {
    final topTen = shortTracks.take(min(10, shortTracks.length)).toList();
    final topTenIds = topTen.map((track) => track.id).toSet();
    final inTop = topTen.take(3).toList();

    SpotifyTrack? outsider;
    for (final track in [
      ...mediumTracks,
      ...longTracks,
      ...recent.map((item) => item.track),
    ]) {
      if (!topTenIds.contains(track.id) &&
          inTop.every((candidate) => candidate.id != track.id)) {
        outsider = track;
        break;
      }
    }

    outsider ??= _fallbackTrack('Blinding Lights', 'The Weeknd');

    final options = [...inTop, outsider]..shuffle(_random);

    return QuizQuestion(
      id: 'track-not-in-top10',
      prompt: 'Cual de estas canciones NO esta en tu top 10 reciente?',
      category: QuizCategory.tracks,
      difficulty: QuizDifficulty.medium,
      options: options
          .map(
            (track) => QuizOption(
              id: track.id,
              title: track.name,
              subtitle: track.subtitle,
              imageUrl: track.imageUrl,
              previewUrl: track.previewUrl,
            ),
          )
          .toList(),
      correctOptionId: outsider.id,
      funFact:
          '"${outsider.name}" fue el distractor. Tus favoritas recientes eran otras.',
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

  QuizQuestion _buildGenreTopThreeQuestion(
    List<SpotifyArtist> shortArtists,
    String dominantGenre,
  ) {
    final ranking = _genreScores(shortArtists).keys.toList();
    final topThree = ranking.take(3).toList();
    final correct = topThree.length > 1 ? topThree[1] : dominantGenre;
    final distractors = ranking
        .where((genre) => genre != correct && !topThree.contains(genre))
        .take(8)
        .toList();

    final options = _stringOptions(
      correct: correct,
      pool: distractors,
      count: 4,
      prefix: 'genre-top',
    );

    return QuizQuestion(
      id: 'genre-top-three',
      prompt: 'Cual de estos generos si esta entre tus mas fuertes?',
      category: QuizCategory.genres,
      difficulty: QuizDifficulty.medium,
      options: options,
      correctOptionId: 'genre-top::$correct',
      funFact:
          '${_capitalize(correct)} tambien pesa bastante dentro de tu perfil.',
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

  QuizQuestion _buildShortMediumOverlapQuestion(
    List<SpotifyArtist> shortArtists,
    List<SpotifyArtist> mediumArtists,
    List<SpotifyArtist> longArtists,
  ) {
    final mediumIds = mediumArtists.map((artist) => artist.id).toSet();
    final overlap = shortArtists
        .where((artist) => mediumIds.contains(artist.id))
        .toList();
    if (overlap.isEmpty) {
      return _buildOverlapQuestion(shortArtists, longArtists, mediumArtists);
    }

    final correct = overlap.first;
    final options = _artistOptions(
      correct: correct,
      pool: [
        ...shortArtists.where((artist) => artist.id != correct.id).take(3),
        ...mediumArtists.where((artist) => artist.id != correct.id).take(3),
        ...longArtists.where((artist) => artist.id != correct.id).take(3),
      ],
      count: 4,
    );

    return QuizQuestion(
      id: 'artist-overlap-medium',
      prompt: 'Que artista aparece en tu top de corto y medio plazo?',
      category: QuizCategory.overlap,
      difficulty: QuizDifficulty.hard,
      options: options,
      correctOptionId: correct.id,
      funFact:
          '${correct.name} esta fuerte tanto en tu presente como en tu promedio reciente.',
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

  QuizQuestion _buildRecentArtistLeaderQuestion(
    List<RecentlyPlayedItem> recent,
    List<SpotifyArtist> shortArtists,
    List<SpotifyArtist> mediumArtists,
  ) {
    final ranking = _buildRecentArtistRanking(recent);
    if (ranking.isEmpty) {
      return _buildShortMediumOverlapQuestion(
        shortArtists,
        mediumArtists,
        shortArtists,
      );
    }

    final correct = ranking.first;
    final fakeArtists = ranking.skip(1).map(_artistFromRecentStat).toList();
    final options = _artistOptions(
      correct: _artistFromRecentStat(correct),
      pool: [
        ...fakeArtists,
        ...shortArtists.where((artist) => artist.name != correct.name).take(4),
        ...mediumArtists.where((artist) => artist.name != correct.name).take(4),
      ],
      count: 4,
    );

    return QuizQuestion(
      id: 'recent-artist-leader',
      prompt: 'Que artista aparece mas veces en tus reproducciones recientes?',
      category: QuizCategory.recent,
      difficulty: QuizDifficulty.medium,
      options: options,
      correctOptionId: 'recent-artist::${correct.name}',
      funFact:
          '${correct.name} fue quien mas se repitio en tu actividad reciente.',
    );
  }

  String _findDominantGenre(List<SpotifyArtist> artists) {
    final scores = _genreScores(artists);
    if (scores.isEmpty) {
      return 'sonidos alternativos';
    }
    return scores.entries.first.key;
  }

  List<SpotifyArtist> _findStableArtists(
    List<SpotifyArtist> shortArtists,
    List<SpotifyArtist> longArtists,
  ) {
    final longIds = longArtists.map((artist) => artist.id).toSet();
    return shortArtists.where((artist) => longIds.contains(artist.id)).toList();
  }

  List<ArtistPlayStat> _buildRecentArtistRanking(List<RecentlyPlayedItem> recent) {
    final counts = <String, ArtistPlayStat>{};
    for (final item in recent) {
      final imageUrl = item.track.imageUrl;
      for (final artistName in item.track.artistNames) {
        final current = counts[artistName];
        counts[artistName] = ArtistPlayStat(
          name: artistName,
          count: (current?.count ?? 0) + 1,
          imageUrl: current?.imageUrl ?? imageUrl,
        );
      }
    }
    final ranking = counts.values.toList()
      ..sort((left, right) => right.count.compareTo(left.count));
    return ranking.take(5).toList();
  }

  List<TrackPlayStat> _buildRecentTrackRanking(List<RecentlyPlayedItem> recent) {
    final counts = <String, TrackPlayStat>{};
    for (final item in recent) {
      final track = item.track;
      final current = counts[track.id];
      counts[track.id] = TrackPlayStat(
        name: track.name,
        artistLabel: track.subtitle,
        count: (current?.count ?? 0) + 1,
        imageUrl: current?.imageUrl ?? track.imageUrl,
      );
    }
    final ranking = counts.values.toList()
      ..sort((left, right) => right.count.compareTo(left.count));
    return ranking.take(5).toList();
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
    for (final artist in _fallbackArtists()) {
      unique.putIfAbsent(artist.id, () => artist);
      if (unique.length >= count) {
        break;
      }
    }
    final selected = unique.values.take(count).toList();
    if (selected.length < count) {
      throw QuizGenerationException(
        'No hay suficientes artistas para generar opciones.',
      );
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
    for (final track in _fallbackTracks()) {
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
        ..._fallbackTracks().where((track) => track.id != correct.id).take(count - 1),
      ];
      if (fallback.length < count) {
        throw QuizGenerationException(
          'No hay suficientes canciones para armar el quiz.',
        );
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
    for (final entry in _fallbackGenres) {
      if (!options.contains(entry)) {
        options.add(entry);
      }
      if (options.length >= count) {
        break;
      }
    }
    if (options.length < count) {
      throw QuizGenerationException(
        'No hay suficientes generos para generar opciones.',
      );
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

  SpotifyArtist _artistFromRecentStat(ArtistPlayStat stat) {
    return SpotifyArtist(
      id: 'recent-artist::${stat.name}',
      name: stat.name,
      genres: const [],
      imageUrl: stat.imageUrl,
    );
  }

  SpotifyTrack _fallbackTrack(String name, String artist) {
    return SpotifyTrack(
      id: 'fallback-track::$name::$artist',
      name: name,
      artistNames: [artist],
      artistIds: const [],
      durationMs: 0,
    );
  }

  List<SpotifyArtist> _fallbackArtists() {
    return [
      SpotifyArtist(
        id: 'fallback-artist::Coldplay',
        name: 'Coldplay',
        genres: ['pop rock'],
      ),
      SpotifyArtist(
        id: 'fallback-artist::Taylor Swift',
        name: 'Taylor Swift',
        genres: ['pop'],
      ),
      SpotifyArtist(
        id: 'fallback-artist::Bad Bunny',
        name: 'Bad Bunny',
        genres: ['reggaeton'],
      ),
      SpotifyArtist(
        id: 'fallback-artist::Arctic Monkeys',
        name: 'Arctic Monkeys',
        genres: ['indie rock'],
      ),
      SpotifyArtist(
        id: 'fallback-artist::Feid',
        name: 'Feid',
        genres: ['latin pop'],
      ),
      SpotifyArtist(
        id: 'fallback-artist::Dua Lipa',
        name: 'Dua Lipa',
        genres: ['dance pop'],
      ),
    ];
  }

  List<SpotifyTrack> _fallbackTracks() {
    return [
      _fallbackTrack('Blinding Lights', 'The Weeknd'),
      _fallbackTrack('As It Was', 'Harry Styles'),
      _fallbackTrack('Ojitos Lindos', 'Bad Bunny'),
      _fallbackTrack('Anti-Hero', 'Taylor Swift'),
      _fallbackTrack('Normal', 'Feid'),
      _fallbackTrack('Do I Wanna Know?', 'Arctic Monkeys'),
    ];
  }

  static const List<String> _fallbackGenres = [
    'pop',
    'latin pop',
    'reggaeton',
    'indie pop',
    'alternative rock',
    'dance pop',
    'trap latino',
    'urban latino',
  ];

  final Random _random = Random();
}
