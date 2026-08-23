import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/api/api_exception.dart';
import 'package:holynikkah/core/api/api_response.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/modules/template/models/saved_template.dart';
import 'package:holynikkah/modules/template/models/template_definition.dart';
import 'package:holynikkah/modules/template/models/template_summary.dart';
import 'package:holynikkah/modules/template/services/template_cache.dart';

/// Read-only template API for the app.
///
/// Implements the documented caching contract:
///  * stores the server `ETag` and replays it as `If-None-Match`
///  * `304 Not Modified` → reuse the cached JSON (saves bandwidth)
///  * network failure → fall back to the last good cached copy (offline)
///
/// The app never touches the `/admin/*` endpoints — those are admin-only.
class TemplateService {
  TemplateService._();

  static final TemplateService instance = TemplateService._();

  static const String _tag = 'TemplateService';

  final TemplateCache _cache = TemplateCache.instance;

  /// `GET /templates?type={tier}&status=published` — lightweight picker list.
  Future<ApiResponse<TemplateListResult>> fetchTemplates({
    String? type,
    String status = 'published',
  }) {
    final query = <String, dynamic>{
      'status': status,
      if (type != null && type.isNotEmpty) 'type': type,
    };
    final cacheKey = 'list_${type ?? 'all'}_$status';

    AppLogger.info('Fetching templates type=$type status=$status', tag: _tag);

    return _getCached<TemplateListResult>(
      path: AppConstants.urls.templates,
      queryParameters: query,
      cacheKey: cacheKey,
      parser: TemplateListResult.fromJson,
    );
  }

  /// `GET /templates/{id}` — full definition for the renderer.
  Future<ApiResponse<TemplateDefinition>> fetchTemplate(String id) {
    AppLogger.info('Fetching template $id', tag: _tag);

    return _getCached<TemplateDefinition>(
      path: AppConstants.urls.templateById(id),
      cacheKey: 'template_$id',
      parser: TemplateDefinition.fromJson,
    );
  }

  // ─── Saved (user-filled) templates — authenticated, uncached ────────────────

  /// `GET /{tier}-users/templates/saved` — the user's saved templates.
  Future<ApiResponse<SavedTemplateListResult>> fetchSavedTemplates({
    required bool isVip,
    int pageSize = 20,
  }) {
    AppLogger.info('Fetching saved templates (vip=$isVip)', tag: _tag);
    return ApiClient.instance.get<SavedTemplateListResult>(
      AppConstants.urls.savedTemplates(isVip),
      queryParameters: {'pageSize': pageSize},
      parser: SavedTemplateListResult.fromJson,
    );
  }

  /// `GET /{tier}-users/templates/saved/{id}` — saved values + full definition.
  Future<ApiResponse<SavedTemplateDetail>> fetchSavedTemplate({
    required bool isVip,
    required String id,
  }) {
    AppLogger.info('Fetching saved template $id (vip=$isVip)', tag: _tag);
    return ApiClient.instance.get<SavedTemplateDetail>(
      AppConstants.urls.savedTemplateById(isVip, id),
      parser: SavedTemplateDetail.fromJson,
    );
  }

  /// `GET /{tier}-users/templates/saved/default` — the current/default one.
  Future<ApiResponse<SavedTemplateDetail>> fetchDefaultSavedTemplate({
    required bool isVip,
  }) {
    return ApiClient.instance.get<SavedTemplateDetail>(
      AppConstants.urls.savedTemplateDefault(isVip),
      parser: SavedTemplateDetail.fromJson,
    );
  }

  /// `POST /{tier}-users/templates/saved` — save filled template data.
  ///
  /// Multipart so the rendered [previewImage] PNG is uploaded alongside the
  /// field values (sent as a JSON-encoded `values` string per the API).
  Future<ApiResponse<SavedTemplate>> createSavedTemplate({
    required bool isVip,
    required String templateId,
    required String name,
    required Map<String, String> values,
    File? previewImage,
    Map<String, File>? slotImages,
    Map<String, String>? slots,
    bool? isDefault,
  }) async {
    AppLogger.info('Saving template $templateId (vip=$isVip)', tag: _tag);
    final map = <String, dynamic>{
      'templateId': templateId,
      'name': name,
      'values': jsonEncode(values),
      if (isDefault != null) 'isDefault': isDefault.toString(),
      if (previewImage != null)
        'previewImage': await _previewFile(previewImage),
      if (slots != null && slots.isNotEmpty) 'slots': jsonEncode(slots),
    };
    await _addSlotImages(map, slotImages);
    return ApiClient.instance.upload<SavedTemplate>(
      AppConstants.urls.savedTemplates(isVip),
      formData: FormData.fromMap(map),
      parser: _parseSaved,
    );
  }

  /// `PUT /{tier}-users/templates/saved/{id}` — update name/values/isDefault.
  ///
  /// Sent as `POST` with a `_method=PUT` field so the multipart [previewImage]
  /// upload survives the method override (matches the documented API).
  Future<ApiResponse<SavedTemplate>> updateSavedTemplate({
    required bool isVip,
    required String id,
    String? name,
    Map<String, String>? values,
    File? previewImage,
    Map<String, File>? slotImages,
    Map<String, String>? slots,
    bool? isDefault,
  }) async {
    AppLogger.info('Updating saved template $id (vip=$isVip)', tag: _tag);
    final map = <String, dynamic>{
      '_method': 'PUT',
      if (name != null) 'name': name,
      if (values != null) 'values': jsonEncode(values),
      if (isDefault != null) 'isDefault': isDefault.toString(),
      if (previewImage != null)
        'previewImage': await _previewFile(previewImage),
      if (slots != null) 'slots': jsonEncode(slots),
    };
    await _addSlotImages(map, slotImages);
    return ApiClient.instance.upload<SavedTemplate>(
      AppConstants.urls.savedTemplateById(isVip, id),
      formData: FormData.fromMap(map),
      parser: _parseSaved,
    );
  }

  Future<MultipartFile> _previewFile(File file) {
    return MultipartFile.fromFile(
      file.path,
      filename: 'preview.png',
      contentType: DioMediaType('image', 'png'),
    );
  }

  /// Adds one `slotImages[<slotId>]` multipart entry per newly picked photo.
  Future<void> _addSlotImages(
    Map<String, dynamic> map,
    Map<String, File>? slotImages,
  ) async {
    if (slotImages == null) return;
    for (final entry in slotImages.entries) {
      final ext = entry.value.path.split('.').last.toLowerCase();
      final subtype = ext == 'png' ? 'png' : 'jpeg';
      map['slotImages[${entry.key}]'] = await MultipartFile.fromFile(
        entry.value.path,
        filename: '${entry.key}.$subtype',
        contentType: DioMediaType('image', subtype),
      );
    }
  }

  /// `PATCH /{tier}-users/templates/saved/{id}/default` — set as default.
  Future<ApiResponse<void>> makeSavedTemplateDefault({
    required bool isVip,
    required String id,
  }) {
    return ApiClient.instance.patch<void>(
      AppConstants.urls.savedTemplateMakeDefault(isVip, id),
      parser: (_) {},
    );
  }

  /// `POST /{tier}-users/template/select` — persist the user's chosen template.
  ///
  /// [templateId] is the catalog template id (e.g. `vip_2`); sent as an int
  /// when numeric, otherwise as the raw string.
  Future<ApiResponse<bool>> selectTemplate({
    required bool isVip,
    required String templateId,
  }) {
    AppLogger.info('Selecting template id=$templateId (vip=$isVip)', tag: _tag);
    final parsed = int.tryParse(templateId);
    return ApiClient.instance.post<bool>(
      AppConstants.urls.templateSelect(isVip),
      data: {'template_id': parsed ?? templateId},
      parser: (json) {
        if (json is Map) {
          return json['status'] == true || json['success'] == true;
        }
        return true;
      },
    );
  }

  /// `DELETE /{tier}-users/templates/saved/{id}`.
  Future<ApiResponse<void>> deleteSavedTemplate({
    required bool isVip,
    required String id,
  }) {
    return ApiClient.instance.delete<void>(
      AppConstants.urls.savedTemplateById(isVip, id),
      parser: (_) {},
    );
  }

  SavedTemplate _parseSaved(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);
    final root = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;
    return SavedTemplate.fromJson(root);
  }

  // ─── Internal: ETag-aware GET with offline fallback ─────────────────────────

  Future<ApiResponse<T>> _getCached<T>({
    required String path,
    required String cacheKey,
    required T Function(dynamic json) parser,
    Map<String, dynamic>? queryParameters,
    bool sendEtag = true,
  }) async {
    final dio = ApiClient.instance.dio;
    final cachedEtag = sendEtag ? await _cache.readEtag(cacheKey) : null;

    try {
      final response = await dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: Options(
          headers: {
            if (cachedEtag != null) 'If-None-Match': cachedEtag,
          },
          // Treat 304 as a valid (non-throwing) response.
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final status = response.statusCode ?? 0;

      // 304 — our cached copy is still valid.
      if (status == 304) {
        final cached = await _cache.readBody(cacheKey);
        if (cached != null) {
          AppLogger.success('304 for $cacheKey — using cache', tag: _tag);
          return ApiResponse.success(data: parser(cached), statusCode: 304);
        }
        // ETag existed but body was lost: re-fetch without the ETag once.
        AppLogger.warning('304 but no cached body for $cacheKey — refetching',
            tag: _tag);
        return _getCached<T>(
          path: path,
          cacheKey: cacheKey,
          parser: parser,
          queryParameters: queryParameters,
          sendEtag: false,
        );
      }

      // Fresh success — store new ETag + body.
      if (status >= 200 && status < 300) {
        final body = response.data;
        final etag = response.headers.value('etag');
        await _cache.write(cacheKey, body: body, etag: etag);
        AppLogger.success('Loaded $cacheKey (etag=${etag ?? 'none'})', tag: _tag);
        try {
          return ApiResponse.success(data: parser(body), statusCode: status);
        } catch (e, s) {
          AppLogger.error('Failed to parse $cacheKey', tag: _tag, error: e, stackTrace: s);
          return ApiResponse.failure(
            ApiException(
              message: 'Failed to parse template response',
              statusCode: status,
              type: ApiExceptionType.parseError,
              originalError: e,
            ),
          );
        }
      }

      // Error status — fall back to cache if we have it.
      final cached = await _cache.readBody(cacheKey);
      if (cached != null) {
        AppLogger.warning('HTTP $status for $cacheKey — using stale cache',
            tag: _tag);
        return ApiResponse.success(data: parser(cached), statusCode: status);
      }

      return ApiResponse.failure(
        ApiException(
          message: 'Request failed ($status)',
          statusCode: status,
          data: response.data,
        ),
      );
    } on DioException catch (e) {
      // Offline / timeout — serve last good copy if available.
      final cached = await _cache.readBody(cacheKey);
      if (cached != null) {
        AppLogger.warning('Network error for $cacheKey — using offline cache',
            tag: _tag);
        return ApiResponse.success(data: parser(cached));
      }
      return ApiResponse.failure(
        ApiException(
          message: e.type == DioExceptionType.connectionError
              ? 'No internet connection.'
              : (e.message ?? 'Network error'),
          type: ApiExceptionType.noInternet,
          originalError: e,
        ),
      );
    } catch (e, s) {
      AppLogger.error('Unexpected error loading $cacheKey',
          tag: _tag, error: e, stackTrace: s);
      final cached = await _cache.readBody(cacheKey);
      if (cached != null) {
        return ApiResponse.success(data: parser(cached));
      }
      return ApiResponse.failure(
        ApiException(message: e.toString(), originalError: e),
      );
    }
  }
}
