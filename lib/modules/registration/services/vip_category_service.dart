import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/modules/registration/models/vip_category_select_model.dart';

class VipCategoryService {
  VipCategoryService._();

  static final VipCategoryService instance = VipCategoryService._();

  Future<VipCategorySelectResponse> selectCategory(int vipCategoryId) async {
    AppLogger.info(
      'Selecting VIP category id=$vipCategoryId',
      tag: 'VipCategoryService',
    );

    final response = await ApiClient.instance.post<dynamic>(
      AppConstants.urls.vipCategorySelect,
      data: {'vip_category_id': vipCategoryId},
      parser: (json) => json,
    );

    final rawBody = response.success ? response.data : response.error?.data;
    final parsed = VipCategorySelectResponse.fromJson(rawBody);

    if (parsed.status) {
      AppLogger.success(
        'VIP category selected: $vipCategoryId',
        tag: 'VipCategoryService',
      );
      return parsed;
    }

    final message = parsed.message.isNotEmpty
        ? parsed.message
        : response.message ?? 'Failed to select category';

    AppLogger.warning(
      'VIP category selection failed: $message',
      tag: 'VipCategoryService',
    );

    return VipCategorySelectResponse(
      status: false,
      message: message,
      data: parsed.data,
    );
  }
}
