class SpotifyConfig {
  static const clientId = String.fromEnvironment(
    'SPOTIFY_CLIENT_ID',
    defaultValue: 'f465a4bd24c344f7bf1e540f0868c48d',
  );
  static const redirectUri = String.fromEnvironment(
    'SPOTIFY_REDIRECT_URI',
    defaultValue: 'spotiquiz://callback',
  );
  static const scopes = <String>[
    'user-read-private',
    'user-top-read',
    'user-read-recently-played',
  ];

  static Uri get redirectUriObject => Uri.parse(redirectUri);
  static String get callbackScheme => redirectUriObject.scheme;
  static String get callbackHost => redirectUriObject.host;
  static bool get isConfigured => clientId.trim().isNotEmpty;
}
