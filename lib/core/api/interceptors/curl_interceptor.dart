import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:holynikkah/core/api/curl_printer.dart';
import 'package:holynikkah/core/utils/app_logger.dart';

/// Prints a reproducible cURL command for every outgoing request (debug only).
class CurlInterceptor extends Interceptor {
  CurlInterceptor({this.maskSecrets = true});

  final bool maskSecrets;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final curl = CurlPrinter.fromRequest(
        options,
        maskSecrets: maskSecrets,
      );
      AppLogger.debug('cURL:\n$curl', tag: 'API_CURL');
    }
    handler.next(options);
  }
}
