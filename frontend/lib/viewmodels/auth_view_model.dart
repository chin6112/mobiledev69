import 'package:flutter/foundation.dart';

import '../repositories/auth_repository.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository);

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.unknown;
  bool _busy = false;
  String? _error;

  AuthStatus get status => _status;
  bool get busy => _busy;
  String? get error => _error;
  CurrentUser? get user => _repository.currentUser;
  String? get accessToken => _repository.accessToken;

  Future<void> restore() async {
    final restored = await _repository.restoreSession();
    _status = restored ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> login() async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.startLogin();
    } on Exception catch (error) {
      _error = error.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Returns true when the provider callback produced a valid session.
  Future<bool> completeLogin(Uri callbackUri) async {
    _error = null;
    try {
      await _repository.completeLogin(callbackUri);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on Exception catch (error) {
      _error = error.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    await _repository.logout();
  }

  Future<void> sessionExpired() async {
    if (_status != AuthStatus.authenticated) return;
    await _repository.clearSession();
    _status = AuthStatus.unauthenticated;
    _error = 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';
    notifyListeners();
  }
}
