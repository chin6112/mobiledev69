class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );
  static const issuerUrl = String.fromEnvironment(
    'OIDC_ISSUER',
    defaultValue: 'http://localhost:8000/openid',
  );
  static const redirectUri = String.fromEnvironment(
    'OIDC_REDIRECT_URI',
    defaultValue: 'http://localhost:50000/callback',
  );
  static const postLogoutRedirectUri = String.fromEnvironment(
    'OIDC_POST_LOGOUT_URI',
    defaultValue: 'http://localhost:50000/',
  );
  static const clientId = 'tripmate-flutter';
}

class AppException implements Exception {
  const AppException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
