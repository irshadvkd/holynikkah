import 'package:dio/dio.dart';

/// Injects `Authorization` header when a token is available.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.getToken, this.onUnauthorized});

  final String? Function() getToken;
  final void Function({String? message})? onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = getToken();
    if (token != null && token.isNotEmpty) {
      options.headers.putIfAbsent('Authorization', () => 'Bearer $token');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      String? message;
      final body = err.response?.data;
      if (body is Map) {
        message = body['message'] ?? body['error'] ?? body['detail'];
      }
      onUnauthorized?.call(message: message);
    }
    handler.next(err);
  }
}

