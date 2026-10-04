import '../services/auth_service.dart';

class CurrentUser {
  const CurrentUser({required this.id, required this.name});

  final int? id;
  final String name;
}

class AuthRepository {
  AuthRepository(this._service);

  final AuthService _service;

  String? get accessToken => _service.accessToken;

  Future<bool> restoreSession() => _service.restore();

  Future<void> startLogin() => _service.startLogin();

  Future<void> completeLogin(Uri callbackUri) =>
      _service.completeLogin(callbackUri);

  Future<void> logout() => _service.logout();

  Future<void> clearSession() => _service.clearSession();

  CurrentUser? get currentUser {
    if (_service.credential == null) return null;
    final claims = _service.idTokenClaims;
    final name =
        claims['name'] ?? claims['preferred_username'] ?? claims['sub'];
    return CurrentUser(
      id: int.tryParse(claims['sub']?.toString() ?? ''),
      name: name?.toString() ?? 'ผู้ใช้',
    );
  }
}
