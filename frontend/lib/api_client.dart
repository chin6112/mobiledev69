import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class TripMateApi {
  TripMateApi({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl;

  static const _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );
  static const _accessKey = 'tripmate_access_token';
  static const _refreshKey = 'tripmate_refresh_token';

  final String baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Map<String, String> _webStorage = {};

  Future<bool> get isAuthenticated async => (await _read(_accessKey)) != null;

  Future<void> register(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode != 201) {
      throw _exception(response);
    }
  }

  Future<void> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode != 200) {
      throw _exception(response);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    await _write(_accessKey, data['access'] as String);
    await _write(_refreshKey, data['refresh'] as String);
  }

  Future<void> logout() async {
    await _delete(_accessKey);
    await _delete(_refreshKey);
  }

  Future<List<Map<String, dynamic>>> getTrips() async {
    final response = await _authorizedRequest(
      (headers) => http.get(_uri('trips/'), headers: headers),
    );
    final data = jsonDecode(response.body);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createTrip({
    required String title,
    required String destination,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _authorizedRequest(
      (headers) => http.post(
        _uri('trips/'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'destination': destination,
          'start_date': startDate,
          'end_date': endDate,
        }),
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getSlots(int tripId) async {
    final response = await _authorizedRequest(
      (headers) => http.get(_uri('trips/$tripId/slots/'), headers: headers),
    );
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> bookSlot(int slotId) async {
    final response = await _authorizedRequest(
      (headers) => http.post(_uri('slots/$slotId/book/'), headers: headers),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getExpenses(int tripId) async {
    final response = await _authorizedRequest(
      (headers) => http.get(_uri('trips/$tripId/expenses/'), headers: headers),
    );
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createExpense({
    required int tripId,
    required String description,
    required double amount,
  }) async {
    final response = await _authorizedRequest(
      (headers) => http.post(
        _uri('trips/$tripId/expenses/'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode({'description': description, 'amount': amount}),
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getSettlement(int tripId) async {
    final response = await _authorizedRequest(
      (headers) => http.get(_uri('trips/$tripId/settlement/'), headers: headers),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['transfers'] as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getTasks(int tripId) async {
    final response = await _authorizedRequest(
      (headers) => http.get(_uri('trips/$tripId/tasks/'), headers: headers),
    );
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> updateTask({
    required int taskId,
    required bool isDone,
  }) async {
    final response = await _authorizedRequest(
      (headers) => http.patch(
        _uri('tasks/$taskId/'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode({'is_done': isDone}),
      ),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Uri _uri(String path) => Uri.parse('$baseUrl/$path');

  Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var response = await _withAccessToken(request);
    if (response.statusCode != 401) return response;

    final refresh = await _read(_refreshKey);
    if (refresh == null) throw _exception(response);
    final refreshed = await http.post(
      _uri('token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );
    if (refreshed.statusCode != 200) {
      await logout();
      throw _exception(refreshed);
    }
    await _write(
      _accessKey,
      (jsonDecode(refreshed.body) as Map<String, dynamic>)['access'] as String,
    );
    response = await _withAccessToken(request);
    return response;
  }

  Future<http.Response> _withAccessToken(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    final token = await _read(_accessKey);
    if (token == null) {
      throw const ApiException('กรุณาเข้าสู่ระบบก่อน', 401);
    }
    return request({'Authorization': 'Bearer $token'});
  }

  Future<String?> _read(String key) =>
      kIsWeb ? Future.value(_webStorage[key]) : _storage.read(key: key);

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      _webStorage[key] = value;
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      _webStorage.remove(key);
    } else {
      await _storage.delete(key: key);
    }
  }

  ApiException _exception(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiException(
        data['detail']?.toString() ?? 'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์',
        response.statusCode,
      );
    } catch (_) {
      return ApiException('เกิดข้อผิดพลาดจากเซิร์ฟเวอร์', response.statusCode);
    }
  }
}
