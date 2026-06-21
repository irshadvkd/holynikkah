import 'package:holynikkah/core/api/api_exception.dart';

/// Standard wrapper for all API call results.
class ApiResponse<T> {
  const ApiResponse._({
    required this.success,
    this.data,
    this.statusCode,
    this.message,
    this.error,
  });

  final bool success;
  final T? data;
  final int? statusCode;
  final String? message;
  final ApiException? error;

  factory ApiResponse.success({
    required T data,
    int? statusCode,
    String? message,
  }) {
    return ApiResponse._(
      success: true,
      data: data,
      statusCode: statusCode,
      message: message,
    );
  }

  factory ApiResponse.failure(ApiException error) {
    return ApiResponse._(
      success: false,
      statusCode: error.statusCode,
      message: error.message,
      error: error,
    );
  }

  /// Returns [data] or throws [error].
  T get requireData {
    if (success && data != null) return data as T;
    throw error ?? ApiException(message: message ?? 'No data available');
  }
}
