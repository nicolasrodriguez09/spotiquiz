import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

import '../core/spotify_config.dart';
import '../models/spotify_models.dart';

class SpotifyAuthException implements Exception {
  SpotifyAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SpotifyAuthService {
  SpotifyAuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _authBase = 'https://accounts.spotify.com/authorize';
  static const _tokenBase = 'https://accounts.spotify.com/api/token';

  Future<SpotifyAuthSession> authenticate() async {
    final verifier = _generateRandomString(72);
    final challenge = _createCodeChallenge(verifier);
    final state = _generateRandomString(18);

    final authUri = Uri.parse(_authBase).replace(
      queryParameters: {
        'client_id': SpotifyConfig.clientId,
        'response_type': 'code',
        'redirect_uri': SpotifyConfig.redirectUri,
        'code_challenge_method': 'S256',
        'code_challenge': challenge,
        'scope': SpotifyConfig.scopes.join(' '),
        'state': state,
        'show_dialog': 'true',
      },
    );

    final callback = await FlutterWebAuth2.authenticate(
      url: authUri.toString(),
      callbackUrlScheme: SpotifyConfig.callbackScheme,
      options: const FlutterWebAuth2Options(
        preferEphemeral: true,
      ),
    );

    final callbackUri = Uri.parse(callback);
    final incomingState = callbackUri.queryParameters['state'];
    final authError = callbackUri.queryParameters['error'];
    final authCode = callbackUri.queryParameters['code'];

    if (authError != null) {
      throw SpotifyAuthException('Spotify devolvio un error: $authError');
    }
    if (incomingState != state) {
      throw SpotifyAuthException(
        'La respuesta de autenticacion no coincide con el estado esperado.',
      );
    }
    if (authCode == null || authCode.isEmpty) {
      throw SpotifyAuthException('No se recibio el codigo de autorizacion.');
    }

    return _exchangeAuthorizationCode(
      authorizationCode: authCode,
      codeVerifier: verifier,
    );
  }

  Future<SpotifyAuthSession> refresh(SpotifyAuthSession session) async {
    final refreshToken = session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw SpotifyAuthException('No hay refresh token disponible.');
    }

    final response = await _client.post(
      Uri.parse(_tokenBase),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': SpotifyConfig.clientId,
      },
    );

    final json = _parseTokenResponse(response);
    return _toSession(json, refreshTokenFallback: refreshToken);
  }

  Future<SpotifyAuthSession> refreshIfNeeded(SpotifyAuthSession session) async {
    if (!session.isExpired) {
      return session;
    }
    return refresh(session);
  }

  Future<SpotifyAuthSession> _exchangeAuthorizationCode({
    required String authorizationCode,
    required String codeVerifier,
  }) async {
    final response = await _client.post(
      Uri.parse(_tokenBase),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': authorizationCode,
        'redirect_uri': SpotifyConfig.redirectUri,
        'client_id': SpotifyConfig.clientId,
        'code_verifier': codeVerifier,
      },
    );

    final json = _parseTokenResponse(response);
    return _toSession(json);
  }

  Map<String, dynamic> _parseTokenResponse(http.Response response) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      final error = json['error_description'] ?? json['error'] ?? 'desconocido';
      throw SpotifyAuthException('No fue posible autenticar con Spotify: $error');
    }
    return json;
  }

  SpotifyAuthSession _toSession(
    Map<String, dynamic> json, {
    String? refreshTokenFallback,
  }) {
    final expiresIn = (json['expires_in'] as num? ?? 3600).toInt();
    final scopeString = (json['scope'] ?? '') as String;
    return SpotifyAuthSession(
      accessToken: (json['access_token'] ?? '') as String,
      tokenType: (json['token_type'] ?? 'Bearer') as String,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      refreshToken:
          (json['refresh_token'] as String?) ?? refreshTokenFallback,
      scopes: scopeString.isEmpty ? SpotifyConfig.scopes : scopeString.split(' '),
    );
  }

  String _generateRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String _createCodeChallenge(String verifier) {
    final bytes = ascii.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }
}
