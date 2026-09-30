import 'package:dio/dio.dart';
import 'package:holynikkah/core/api/api_exception.dart';
import 'package:holynikkah/core/api/api_response.dart';
import 'package:holynikkah/core/api/interceptors/auth_interceptor.dart';
import 'package:holynikkah/core/api/interceptors/curl_interceptor.dart';
import 'package:holynikkah/core/api/interceptors/logging_interceptor.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';

/// Central HTTP client for all network requests.
///
/// Usage:
/// ```dart
/// final response = await ApiClient.instance.get<Map<String, dynamic>>(
///   AppConstants.urls.login,
///   parser: (json) => json as Map<String, dynamic>,
/// );
/// ```
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  bool _initialized = false;
  String? _authToken;
  void Function({String? message})? onUnauthorized;

  Dio get dio {
    if (!_initialized) init();
    return _dio;
  }

  /// Configure Dio with base URL, timeouts, and interceptors.
  void init({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    bool enableLogging = true,
    bool enableCurl = true,
    Map<String, dynamic>? defaultHeaders,
  }) {
    if (_initialized) return;

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConstants.urls.base,
        connectTimeout: connectTimeout ?? AppConstants.misc.apiTimeout,
        receiveTimeout: receiveTimeout ?? AppConstants.misc.apiTimeout,
        sendTimeout: sendTimeout ?? AppConstants.misc.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?defaultHeaders,
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(
        getToken: () => _authToken,
        onUnauthorized: ({String? message}) => onUnauthorized?.call(message: message),
      ),
      if (enableLogging) LoggingInterceptor(),
      if (enableCurl) CurlInterceptor(),
    ]);

    _initialized = true;
    AppLogger.info('ApiClient initialized', tag: 'API');
  }

  void setAuthToken(String? token) => _authToken = token;

  String? get authToken => _authToken;

  // ─── HTTP verbs ───────────────────────────────────────────────────────────

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? parser,
  }) {
    return _request<T>(
      () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      parser: parser,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? parser,
  }) {
    return _request<T>(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      parser: parser,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? parser,
  }) {
    return _request<T>(
      () => _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      parser: parser,
    );
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? parser,
  }) {
    return _request<T>(
      () => _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      parser: parser,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? parser,
  }) {
    return _request<T>(
      () => _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      parser: parser,
    );
  }

  Future<ApiResponse<T>> upload<T>(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    T Function(dynamic json)? parser,
  }) {
    final uploadOptions = (options ?? Options()).copyWith(
      headers: {
        ...?options?.headers,
        'Accept': 'application/json',
      },
    );
    return _request<T>(
      () => _dio.post<dynamic>(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: uploadOptions,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      ),
      parser: parser,
    );
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  Future<ApiResponse<T>> _request<T>(
    Future<Response<dynamic>> Function() call, {
    T Function(dynamic json)? parser,
  }) async {
    try {
      final response = await call();
      return _handleResponse<T>(response, parser: parser);
    } on DioException catch (e) {
      return ApiResponse.failure(_mapDioException(e));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Unexpected API error',
        tag: 'API',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResponse.failure(
        ApiException(
          message: e.toString(),
          type: ApiExceptionType.unknown,
          originalError: e,
        ),
      );
    }
  }

  ApiResponse<T> _handleResponse<T>(
    Response<dynamic> response, {
    T Function(dynamic json)? parser,
  }) {
    final statusCode = response.statusCode ?? 0;
    final body = response.data;

    if (statusCode >= 200 && statusCode < 300) {
      try {
        final T parsed = parser != null
            ? parser(body)
            : body as T;
        return ApiResponse.success(data: parsed, statusCode: statusCode);
      } catch (e, stackTrace) {
        AppLogger.error(
          'Failed to parse response',
          tag: 'API',
          error: e,
          stackTrace: stackTrace,
        );
        return ApiResponse.failure(
          ApiException(
            message: 'Failed to parse response',
            statusCode: statusCode,
            type: ApiExceptionType.parseError,
            data: body,
            originalError: e,
          ),
        );
      }
    }

    if (statusCode == 401) {
      final msg = _extractErrorMessage(body);
      onUnauthorized?.call(message: msg);
    }

    return ApiResponse.failure(
      ApiException(
        message: _extractErrorMessage(body) ?? 'Request failed',
        statusCode: statusCode,
        type: _typeFromStatusCode(statusCode),
        data: body,
      ),
    );
  }

  ApiException _mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timed out. Please try again.',
          type: ApiExceptionType.timeout,
          originalError: error,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'No internet connection.',
          type: ApiExceptionType.noInternet,
          originalError: error,
        );
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request was cancelled.',
          type: ApiExceptionType.cancelled,
          originalError: error,
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final body = error.response?.data;
        if (statusCode == 401) {
          final msg = _extractErrorMessage(body);
          onUnauthorized?.call(message: msg);
        }
        return ApiException(
          message: _extractErrorMessage(body) ?? error.message ?? 'Server error',
          statusCode: statusCode,
          type: _typeFromStatusCode(statusCode ?? 0),
          data: body,
          originalError: error,
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        final original = error.error;
        if (original is FormatException) {
          return ApiException(
            message: 'Server returned an invalid response. Please try again.',
            type: ApiExceptionType.parseError,
            originalError: error,
          );
        }
        return ApiException(
          message: error.message ?? error.error?.toString() ?? 'An unexpected error occurred.',
          type: ApiExceptionType.unknown,
          originalError: error,
        );
    }
  }

  ApiExceptionType _typeFromStatusCode(int statusCode) {
    return switch (statusCode) {
      400 => ApiExceptionType.badRequest,
      401 => ApiExceptionType.unauthorized,
      403 => ApiExceptionType.forbidden,
      404 => ApiExceptionType.notFound,
      >= 500 => ApiExceptionType.serverError,
      _ => ApiExceptionType.unknown,
    };
  }

  String? _extractErrorMessage(dynamic body) {
    if (body is Map) {
      final message = body['message'] ?? body['error'] ?? body['detail'];
      if (message is String) return message;
      if (message != null) return message.toString();
    }
    if (body is String && body.isNotEmpty) return body;
    return null;
  }
}
