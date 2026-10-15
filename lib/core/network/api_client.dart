import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../errors/app_failure.dart';

/// Thin Dio wrapper. Returns decoded JSON and converts every failure to [AppFailure].
class ApiClient {
  ApiClient({Dio? dio, String? baseUrl})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 8),
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 12),
              headers: {'Accept': 'application/json'},
            ),
          );

  final Dio _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body}) =>
      _send(() => _dio.post<dynamic>(path, data: body));

  Future<dynamic> patch(String path, {Object? body}) =>
      _send(() => _dio.patch<dynamic>(path, data: body));

  Future<dynamic> put(String path, {Object? body}) =>
      _send(() => _dio.put<dynamic>(path, data: body));

  Future<dynamic> delete(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.delete<dynamic>(path, queryParameters: query));

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      return (await request()).data;
    } on DioException catch (e) {
      throw _map(e);
    } catch (_) {
      throw AppFailure.unknown;
    }
  }

  AppFailure _map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppFailure.timeout;
      case DioExceptionType.connectionError:
        return AppFailure.network;
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        if (status == 404) return AppFailure.notFound;
        if (status >= 400 && status < 500) {
          return AppFailure(
            FailureKind.invalid,
            _serverMessage(e.response?.data) ??
                'Girdiğin bilgileri kontrol et.',
          );
        }
        return AppFailure.server;
      default:
        return AppFailure.unknown;
    }
  }

  /// Validation messages from the API are already Turkish; show the first one.
  String? _serverMessage(dynamic data) {
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      if (m is List && m.isNotEmpty) {
        return null; // class-validator English text: use the generic copy
      }
      if (m is String) return m;
    }
    return null;
  }
}
