import 'package:dio/dio.dart';

/// Injects `Authorization` header when a token is available.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.getToken});

  final String? Function() getToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = getToken();
    if (token != null && token.isNotEmpty) {
      options.headers.putIfAbsent('Authorization', () => 'Bearer $token');
    }
    handler.next(options);
  }
}
