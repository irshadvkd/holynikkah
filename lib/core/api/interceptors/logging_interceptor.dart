import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';

/// Logs request/response metadata using [AppLogger].
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({this.logBody = true});

  final bool logBody;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode || AppConstants.enableReleaseLogs) {
      AppLogger.info(
        '→ ${options.method} ${options.uri}',
        tag: 'API',
      );
      if (logBody && options.data != null) {
        AppLogger.debug('Request body: ${options.data}', tag: 'API');
      }
      if (options.queryParameters.isNotEmpty) {
        AppLogger.debug(
          'Query params: ${options.queryParameters}',
          tag: 'API',
        );
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode || AppConstants.enableReleaseLogs) {
      final statusCode = response.statusCode ?? 0;
      final message =
          '← $statusCode ${response.requestOptions.method} '
          '${response.requestOptions.uri}';

      if (statusCode >= 200 && statusCode < 300) {
        AppLogger.success(message, tag: 'API');
      } else {
        AppLogger.warning(message, tag: 'API');
      }

      if (logBody && response.data != null) {
        AppLogger.debug('Response body: ${response.data}', tag: 'API');
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final detail = err.message ?? err.error?.toString() ?? 'Unknown error';
    AppLogger.error(
      '✗ ${err.requestOptions.method} ${err.requestOptions.uri} — $detail',
      tag: 'API',
      error: err,
      stackTrace: err.stackTrace,
    );
    handler.next(err);
  }
}
