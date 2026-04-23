enum SpotifyTimeRange {
  shortTerm('short_term', 'corto plazo'),
  mediumTerm('medium_term', 'medio plazo'),
  longTerm('long_term', 'largo plazo');

  const SpotifyTimeRange(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

class SpotifyAuthSession {
  SpotifyAuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.expiresAt,
    required this.scopes,
    this.refreshToken,
  });

  final String accessToken;
  final String tokenType;
  final DateTime expiresAt;
  final String? refreshToken;
  final List<String> scopes;

  bool get isExpired =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(seconds: 30)));

  SpotifyAuthSession copyWith({
    String? accessToken,
    String? tokenType,
    DateTime? expiresAt,
    String? refreshToken,
    List<String>? scopes,
  }) {
    return SpotifyAuthSession(
      accessToken: accessToken ?? this.accessToken,
      tokenType: tokenType ?? this.tokenType,
      expiresAt: expiresAt ?? this.expiresAt,
      refreshToken: refreshToken ?? this.refreshToken,
      scopes: scopes ?? this.scopes,
    );
  }
}

class SpotifyUserProfile {
  SpotifyUserProfile({
    required this.id,
    required this.displayName,
    this.imageUrl,
    this.country,
    this.product,
  });

  final String id;
  final String displayName;
  final String? imageUrl;
  final String? country;
  final String? product;

  factory SpotifyUserProfile.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>? ?? const [];
    return SpotifyUserProfile(
      id: (json['id'] ?? '') as String,
      displayName:
          (json['display_name'] ?? json['id'] ?? 'Fan de Spotify') as String,
      imageUrl: images.isEmpty ? null : images.first['url'] as String?,
      country: json['country'] as String?,
      product: json['product'] as String?,
    );
  }
}

class SpotifyArtist {
  SpotifyArtist({
    required this.id,
    required this.name,
    required this.genres,
    this.imageUrl,
    this.externalUrl,
  });

  final String id;
  final String name;
  final List<String> genres;
  final String? imageUrl;
  final String? externalUrl;

  factory SpotifyArtist.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>? ?? const [];
    return SpotifyArtist(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? 'Artista desconocido') as String,
      genres:
          (json['genres'] as List<dynamic>? ?? const [])
              .map((genre) => genre.toString())
              .toList(),
      imageUrl: images.isEmpty ? null : images.first['url'] as String?,
      externalUrl: (json['external_urls'] as Map<String, dynamic>?)?['spotify']
          as String?,
    );
  }
}

class SpotifyTrack {
  SpotifyTrack({
    required this.id,
    required this.name,
    required this.artistNames,
    required this.artistIds,
    required this.durationMs,
    this.imageUrl,
    this.previewUrl,
    this.externalUrl,
  });

  final String id;
  final String name;
  final List<String> artistNames;
  final List<String> artistIds;
  final int durationMs;
  final String? imageUrl;
  final String? previewUrl;
  final String? externalUrl;

  String get subtitle => artistNames.join(', ');

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    final artists = json['artists'] as List<dynamic>? ?? const [];
    final album = json['album'] as Map<String, dynamic>? ?? const {};
    final albumImages = album['images'] as List<dynamic>? ?? const [];

    return SpotifyTrack(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? 'Cancion desconocida') as String,
      artistNames: artists
          .map((artist) => (artist as Map<String, dynamic>)['name'].toString())
          .toList(),
      artistIds: artists
          .map((artist) => (artist as Map<String, dynamic>)['id'].toString())
          .toList(),
      durationMs: (json['duration_ms'] as num? ?? 0).toInt(),
      imageUrl: albumImages.isEmpty ? null : albumImages.first['url'] as String?,
      previewUrl: json['preview_url'] as String?,
      externalUrl: (json['external_urls'] as Map<String, dynamic>?)?['spotify']
          as String?,
    );
  }
}

class RecentlyPlayedItem {
  RecentlyPlayedItem({
    required this.playedAt,
    required this.track,
  });

  final DateTime playedAt;
  final SpotifyTrack track;

  factory RecentlyPlayedItem.fromJson(Map<String, dynamic> json) {
    return RecentlyPlayedItem(
      playedAt: DateTime.tryParse((json['played_at'] ?? '') as String) ??
          DateTime.now(),
      track: SpotifyTrack.fromJson(
        (json['track'] as Map<String, dynamic>? ?? const {}),
      ),
    );
  }
}
