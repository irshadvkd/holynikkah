/// Typed API errors mapped from [DioException] and other network failures.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.type = ApiExceptionType.unknown,
    this.data,
    this.originalError,
  });

  final String message;
  final int? statusCode;
  final ApiExceptionType type;
  final dynamic data;
  final Object? originalError;

  @override
  String toString() =>
      'ApiException($type, status: $statusCode, message: $message)';
}

enum ApiExceptionType {
  timeout,
  noInternet,
  cancelled,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  parseError,
  unknown,
}
