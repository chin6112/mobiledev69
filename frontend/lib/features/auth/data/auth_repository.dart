import '../../../core/auth/auth_service.dart';
import '../../../core/result/result.dart';
import '../domain/current_user.dart';

class AuthRepository {
  AuthRepository(this._service);

  final AuthService _service;

  String? get accessToken => _service.accessToken;

  Future<bool> restoreSession() => _service.restore();

  Future<Result<void>> startLogin() => Result.guard(_service.startLogin);

  Future<Result<void>> completeLogin(Uri callbackUri) =>
      Result.guard(() => _service.completeLogin(callbackUri));

  Future<void> logout() => _service.logout();

  Future<void> clearSession() => _service.clearSession();

  CurrentUser? get currentUser {
    if (!_service.hasCredential) return null;
    final claims = _service.idTokenClaims;
    final username =
        (claims['preferred_username'] ?? claims['name'] ?? claims['sub'] ?? '')
            .toString();
    return CurrentUser(
      id: int.tryParse(claims['sub']?.toString() ?? ''),
      username: username,
      displayName: (claims['name'] ?? username).toString(),
    );
  }
}
