import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openid_client/openid_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_config.dart';

/// Talks to the OIDC provider (Authorization Code + PKCE) and persists the
/// resulting credential in secure storage.
class AuthService {
  AuthService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _credentialKey = 'tripmate_oidc_credential';
  static const _pendingKey = 'tripmate_oidc_pending';

  final FlutterSecureStorage _storage;
  Credential? _credential;

  Credential? get credential => _credential;

  String? get accessToken {
    final credential = _credential;
    if (credential == null || _isExpired(credential)) return null;
    return credential.toJson()['token']?['access_token'] as String?;
  }

  Map<String, dynamic> get idTokenClaims =>
      _credential?.idToken.claims.toJson() ?? const {};

  Future<Client> _client() async {
    final issuer = await Issuer.discover(Uri.parse(AppConfig.issuerUrl));
    return Client(issuer, AppConfig.clientId);
  }

  // The provider's discovery document has no scopes_supported, so openid_client
  // drops its default scopes; add them explicitly.
  Flow _flow(Client client, {String? state, String? verifier}) =>
      Flow.authorizationCodeWithPKCE(
          client,
          state: state,
          codeVerifier: verifier,
        )
        ..scopes.addAll(const ['openid', 'profile', 'email'])
        ..redirectUri = Uri.parse(AppConfig.redirectUri);

  /// Redirects the browser to the OIDC provider's login page.
  Future<void> startLogin() async {
    try {
      final verifier = _randomString(64);
      final flow = _flow(await _client(), verifier: verifier);
      await _storage.write(
        key: _pendingKey,
        value: jsonEncode({'state': flow.state, 'verifier': verifier}),
      );
      await launchUrl(flow.authenticationUri, webOnlyWindowName: '_self');
    } on Exception catch (error) {
      throw AppException('เชื่อมต่อ OIDC server ไม่ได้: $error');
    }
  }

  /// Exchanges the authorization code in [callbackUri] for tokens.
  Future<void> completeLogin(Uri callbackUri) async {
    final params = callbackUri.queryParameters;
    if (params['error'] != null) {
      throw AppException(
        params['error_description'] ?? 'เข้าสู่ระบบไม่สำเร็จ (${params['error']})',
      );
    }
    final pending = await _storage.read(key: _pendingKey);
    if (pending == null) {
      throw const AppException('ไม่พบข้อมูลการเข้าสู่ระบบ กรุณาลองใหม่อีกครั้ง');
    }
    final data = jsonDecode(pending) as Map<String, dynamic>;
    try {
      final flow = _flow(
        await _client(),
        state: data['state'] as String,
        verifier: data['verifier'] as String,
      );
      final credential = await flow.callback(params);
      final errors = await credential.validateToken().toList();
      if (errors.isNotEmpty) {
        throw AppException('ID token ไม่ถูกต้อง: ${errors.first}');
      }
      await _storage.write(
        key: _credentialKey,
        value: jsonEncode(credential.toJson()),
      );
      _credential = credential;
    } on AppException {
      rethrow;
    } on Exception catch (error) {
      throw AppException('เข้าสู่ระบบไม่สำเร็จ: $error');
    } finally {
      await _storage.delete(key: _pendingKey);
    }
  }

  /// Loads a previously stored credential; returns false when none is valid.
  Future<bool> restore() async {
    final raw = await _storage.read(key: _credentialKey);
    if (raw == null) return false;
    try {
      final credential = Credential.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (_isExpired(credential)) {
        await clearSession();
        return false;
      }
      _credential = credential;
      return true;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  Future<void> clearSession() async {
    _credential = null;
    await _storage.delete(key: _credentialKey);
    await _storage.delete(key: _pendingKey);
  }

  /// Clears local tokens, then ends the session on the OIDC provider too.
  Future<void> logout() async {
    final logoutUri = _credential?.generateLogoutUrl(
      redirectUri: Uri.parse(AppConfig.postLogoutRedirectUri),
    );
    await clearSession();
    if (logoutUri != null) {
      await launchUrl(logoutUri, webOnlyWindowName: '_self');
    }
  }

  bool _isExpired(Credential credential) {
    final expiresAt = credential.toJson()['token']?['expires_at'];
    if (expiresAt is! num) return false;
    return DateTime.fromMillisecondsSinceEpoch(
      expiresAt.toInt() * 1000,
    ).isBefore(DateTime.now());
  }

  static String _randomString(int length) {
    const chars =
        '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }
}
