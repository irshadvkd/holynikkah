import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/modules/registration/models/location_model.dart';

class LocationsService {
  LocationsService._();

  static final LocationsService instance = LocationsService._();

  Future<List<LocationState>> getStates() async {
    AppLogger.info('Fetching active states', tag: 'LocationsService');

    final response = await ApiClient.instance.get<List<LocationState>>(
      AppConstants.urls.locationStates,
      parser: LocationsResponse.parseStates,
    );

    if (response.success && response.data != null) {
      AppLogger.success(
        'States loaded: ${response.data!.length}',
        tag: 'LocationsService',
      );
      return response.data!;
    }

    AppLogger.warning(
      'Failed to load states: ${response.message}',
      tag: 'LocationsService',
    );
    return [];
  }

  Future<List<LocationDistrict>> getDistricts(int stateId) async {
    AppLogger.info(
      'Fetching districts for state_id=$stateId',
      tag: 'LocationsService',
    );

    final response = await ApiClient.instance.get<List<LocationDistrict>>(
      AppConstants.urls.locationDistricts,
      queryParameters: {'state_id': stateId},
      parser: LocationsResponse.parseDistricts,
    );

    if (response.success && response.data != null) {
      AppLogger.success(
        'Districts loaded: ${response.data!.length}',
        tag: 'LocationsService',
      );
      return response.data!;
    }

    AppLogger.warning(
      'Failed to load districts: ${response.message}',
      tag: 'LocationsService',
    );
    return [];
  }
}
