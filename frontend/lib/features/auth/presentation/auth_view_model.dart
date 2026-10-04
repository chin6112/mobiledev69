import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';
import '../domain/current_user.dart';

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

  Future<void> restore() async {
    final restored = await _repository.restoreSession();
    _status = restored ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> login() async {
    _busy = true;
    _error = null;
    notifyListeners();
    final result = await _repository.startLogin();
    _error = result.errorMessage;
    _busy = false;
    notifyListeners();
  }

  Future<bool> completeLogin(Uri callbackUri) async {
    final result = await _repository.completeLogin(callbackUri);
    _error = result.errorMessage;
    _status = _error == null
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    notifyListeners();
    return _error == null;
  }

  Future<void> logout() async {
    _status = AuthStatus.unauthenticated;
    _error = null;
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
