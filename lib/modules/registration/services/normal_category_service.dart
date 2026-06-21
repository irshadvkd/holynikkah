import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/modules/registration/models/normal_category_select_model.dart';

class NormalCategoryService {
  NormalCategoryService._();

  static final NormalCategoryService instance = NormalCategoryService._();

  Future<NormalCategorySelectResponse> selectCategory(int categoryId) async {
    AppLogger.info(
      'Selecting normal category id=$categoryId',
      tag: 'NormalCategoryService',
    );

    final response = await ApiClient.instance.post<dynamic>(
      AppConstants.urls.normalCategorySelect,
      data: {'category_id': categoryId},
      parser: (json) => json,
    );

    final rawBody = response.success ? response.data : response.error?.data;
    final parsed = NormalCategorySelectResponse.fromJson(rawBody);

    if (parsed.status) {
      AppLogger.success(
        'Normal category selected: $categoryId',
        tag: 'NormalCategoryService',
      );
      return parsed;
    }

    final message = parsed.message.isNotEmpty
        ? parsed.message
        : response.message ?? 'Failed to select category';

    AppLogger.warning(
      'Normal category selection failed: $message',
      tag: 'NormalCategoryService',
    );

    return NormalCategorySelectResponse(
      status: false,
      message: message,
      data: parsed.data,
    );
  }
}
