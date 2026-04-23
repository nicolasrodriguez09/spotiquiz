import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/spotify_models.dart';

class SpotifyApiException implements Exception {
  SpotifyApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SpotifyApiService {
  SpotifyApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _base = 'https://api.spotify.com/v1';

  Future<SpotifyUserProfile> getCurrentUserProfile(String accessToken) async {
    final json = await _get(
      accessToken: accessToken,
      path: '/me',
    );
    return SpotifyUserProfile.fromJson(json);
  }

  Future<List<SpotifyArtist>> getTopArtists(
    String accessToken,
    SpotifyTimeRange timeRange, {
    int limit = 20,
  }) async {
    final json = await _get(
      accessToken: accessToken,
      path: '/me/top/artists',
      queryParameters: {
        'time_range': timeRange.apiValue,
        'limit': '$limit',
      },
    );
    final items = json['items'] as List<dynamic>? ?? const [];
    return items
        .map((item) => SpotifyArtist.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<SpotifyTrack>> getTopTracks(
    String accessToken,
    SpotifyTimeRange timeRange, {
    int limit = 20,
  }) async {
    final json = await _get(
      accessToken: accessToken,
      path: '/me/top/tracks',
      queryParameters: {
        'time_range': timeRange.apiValue,
        'limit': '$limit',
      },
    );
    final items = json['items'] as List<dynamic>? ?? const [];
    return items
        .map((item) => SpotifyTrack.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<RecentlyPlayedItem>> getRecentlyPlayed(
    String accessToken, {
    int limit = 20,
  }) async {
    final json = await _get(
      accessToken: accessToken,
      path: '/me/player/recently-played',
      queryParameters: {'limit': '$limit'},
    );
    final items = json['items'] as List<dynamic>? ?? const [];
    return items
        .map((item) => RecentlyPlayedItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> _get({
    required String accessToken,
    required String path,
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse('$_base$path').replace(queryParameters: queryParameters);
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      final errorNode = json['error'];
      final message = switch (errorNode) {
        Map<String, dynamic>() => errorNode['message'] ?? 'Error desconocido',
        _ => 'Error desconocido',
      };
      throw SpotifyApiException('Spotify API respondio con error: $message');
    }
    return json;
  }
}
