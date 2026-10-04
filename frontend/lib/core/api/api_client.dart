import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../result/result.dart';

/// Thin dio wrapper: adds the bearer token and maps failures to [AppException].
class ApiClient {
  ApiClient({
    required String? Function() accessToken,
    required Future<void> Function() onUnauthorized,
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: '${AppConfig.apiBaseUrl}/',
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 15),
             ),
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = accessToken();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) await onUnauthorized();
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;

  Future<dynamic> get(String path) => _send(() => _dio.get(path));

  Future<dynamic> post(String path, [Object? data]) =>
      _send(() => _dio.post(path, data: data));

  Future<dynamic> patch(String path, Object data) =>
      _send(() => _dio.patch(path, data: data));

  Future<void> delete(String path) => _send(() => _dio.delete(path));

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      return (await request()).data;
    } on DioException catch (error) {
      throw _toException(error);
    }
  }

  AppException _toException(DioException error) {
    final status = error.response?.statusCode;
    if (status == null) {
      return const AppException(
        'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ตหรือเปิด backend',
      );
    }
    if (status == 401) {
      return AppException('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่', status);
    }
    final data = error.response?.data;
    if (data is Map && data.isNotEmpty) {
      final detail = data['detail'] ?? data.values.first;
      final text = detail is List ? detail.join(', ') : detail.toString();
      return AppException(text, status);
    }
    return AppException('เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ ($status)', status);
  }
}
