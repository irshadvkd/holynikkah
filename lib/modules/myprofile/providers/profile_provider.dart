import 'package:flutter/material.dart';
import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';

class ProfileProvider extends ChangeNotifier {
  bool _isVipProfile = false;
  String _profileId = '';
  String _name = '';
  String _phoneNumber = '';
  String _information = '';
  String _gender = '';
  String? _state;
  String? _district;
  String? _city;
  String? _profileImagePath;

  // Separate states for VIP and Normal fetched from server
  String _vipProfileId = '';
  String _normalProfileId = '';
  String _vipName = '';
  String _normalName = '';
  String _vipPhoneNumber = '';
  String _normalPhoneNumber = '';
  String _vipInformation = '';
  String _normalInformation = '';
  String _vipGender = '';
  String _normalGender = '';
  String? _vipState;
  String? _normalState;
  String? _vipDistrict;
  String? _normalDistrict;
  String? _vipCity;
  String? _normalCity;
  String? _vipProfileImagePath;
  String? _normalProfileImagePath;

  bool _isFetching = false;

  // Getters
  bool get isVipProfile => _isVipProfile;
  bool get isFetching => _isFetching;
  String get vipHnId => _vipProfileId;
  String get normalHnId => _normalProfileId;

  String get profileId {
    if (_isVipProfile) {
      return _vipProfileId.isNotEmpty ? _vipProfileId : _profileId;
    } else {
      return _normalProfileId.isNotEmpty ? _normalProfileId : _profileId;
    }
  }

  String get name {
    if (_isVipProfile) {
      return _vipName.isNotEmpty ? _vipName : _name;
    } else {
      return _normalName.isNotEmpty ? _normalName : _name;
    }
  }

  String get phoneNumber {
    if (_isVipProfile) {
      return _vipPhoneNumber.isNotEmpty ? _vipPhoneNumber : _phoneNumber;
    } else {
      return _normalPhoneNumber.isNotEmpty ? _normalPhoneNumber : _phoneNumber;
    }
  }

  String get information {
    if (_isVipProfile) {
      return _vipInformation.isNotEmpty ? _vipInformation : _information;
    } else {
      return _normalInformation.isNotEmpty ? _normalInformation : _information;
    }
  }

  String get gender {
    if (_isVipProfile) {
      return _vipGender.isNotEmpty ? _vipGender : _gender;
    } else {
      return _normalGender.isNotEmpty ? _normalGender : _gender;
    }
  }

  String? get state => _isVipProfile ? (_vipState ?? _state) : (_normalState ?? _state);
  String? get district => _isVipProfile ? (_vipDistrict ?? _district) : (_normalDistrict ?? _district);
  String? get city => _isVipProfile ? (_vipCity ?? _city) : (_normalCity ?? _city);

  String? get profileImagePath {
    return _isVipProfile ? (_vipProfileImagePath ?? _profileImagePath) : (_normalProfileImagePath ?? _profileImagePath);
  }

  bool get isProfileImageNetwork {
    final path = profileImagePath;
    if (path == null || path.isEmpty) return false;
    return path.startsWith('http') || (!path.startsWith('/') && !path.startsWith('assets/'));
  }

  String get profileImageNetworkUrl {
    final path = profileImagePath ?? '';
    if (path.startsWith('http')) return path;
    final base = AppConstants.urls.imageBaseUrl;
    final cleanBase = base.endsWith('/') ? base : '$base/';
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$cleanBase$cleanPath';
  }

  // Tier-specific accessors
  String getName(bool isVip) {
    final val = isVip ? _vipName : _normalName;
    return val.isNotEmpty ? val : _name;
  }

  String getPhone(bool isVip) {
    final val = isVip ? _vipPhoneNumber : _normalPhoneNumber;
    return val.isNotEmpty ? val : _phoneNumber;
  }

  String getGender(bool isVip) {
    final val = isVip ? _vipGender : _normalGender;
    return val.isNotEmpty ? val : _gender;
  }

  String? getState(bool isVip) {
    final val = isVip ? _vipState : _normalState;
    return val ?? _state;
  }

  String? getDistrict(bool isVip) {
    final val = isVip ? _vipDistrict : _normalDistrict;
    return val ?? _district;
  }

  String? getCity(bool isVip) {
    final val = isVip ? _vipCity : _normalCity;
    return val ?? _city;
  }

  String getInfo(bool isVip) {
    final val = isVip ? _vipInformation : _normalInformation;
    return val.isNotEmpty ? val : _information;
  }

  String? getProfileImagePath(bool isVip) {
    final val = isVip ? _vipProfileImagePath : _normalProfileImagePath;
    return val ?? _profileImagePath;
  }

  // Setters (backward compatibility / local updates)
  void setVipProfile(bool isVip) {
    _isVipProfile = isVip;
    notifyListeners();
  }

  void updateProfileId(String id) {
    _profileId = id;
    notifyListeners();
  }

  void updateName(String name) {
    _name = name;
    notifyListeners();
  }

  void updatePhoneNumber(String phone) {
    _phoneNumber = phone;
    notifyListeners();
  }

  void updateInformation(String info) {
    _information = info;
    notifyListeners();
  }

  void updateGender(String gender) {
    _gender = gender;
    notifyListeners();
  }

  void updateLocation(String? state, String? district, String? city) {
    _state = state;
    _district = district;
    _city = city;
    notifyListeners();
  }

  void updateProfileImage(String? imagePath) {
    _profileImagePath = imagePath;
    notifyListeners();
  }

  /// Fetch VIP and/or Normal profiles from backend
  Future<void> fetchProfiles({required AuthProvider authProvider}) async {
    if (_isFetching) return;
    _isFetching = true;
    notifyListeners();

    // 1. Fetch VIP profile if logged in
    if (authProvider.isVipLoggedIn) {
      try {
        await authProvider.ensureApiTokenFor(isVip: true);
        final response = await ApiClient.instance.get<dynamic>(
          '/vip-users/me',
          parser: (json) => json,
        );
        if (response.success && response.data != null) {
          final data = response.data['data'];
          if (data is Map) {
            _vipProfileId = data['hn_id']?.toString() ?? '';
            _vipName = data['name']?.toString() ?? '';
            _vipPhoneNumber = data['phone']?.toString() ?? '';
            _vipGender = data['gender']?.toString() ?? '';
            _vipInformation = data['information']?.toString() ?? '';

            if (data['state'] is Map) {
              _vipState = data['state']['name']?.toString();
            } else {
              _vipState = data['state_name']?.toString() ?? data['state']?.toString();
            }

            if (data['district'] is Map) {
              _vipDistrict = data['district']['name']?.toString();
            } else {
              _vipDistrict = data['district_name']?.toString() ?? data['district']?.toString();
            }

            _vipCity = data['city']?.toString();
            _vipProfileImagePath = data['profile_pic']?.toString();
          }
        }
      } catch (e) {
        AppLogger.warning('Failed to fetch VIP profile: $e', tag: 'ProfileProvider');
      }
    } else {
      _vipProfileId = '';
      _vipName = '';
      _vipPhoneNumber = '';
      _vipGender = '';
      _vipInformation = '';
      _vipState = null;
      _vipDistrict = null;
      _vipCity = null;
      _vipProfileImagePath = null;
    }

    // 2. Fetch Normal profile if logged in
    if (authProvider.isNormalLoggedIn) {
      try {
        await authProvider.ensureApiTokenFor(isVip: false);
        final response = await ApiClient.instance.get<dynamic>(
          '/normal-users/me',
          parser: (json) => json,
        );
        if (response.success && response.data != null) {
          final data = response.data['data'];
          if (data is Map) {
            _normalProfileId = data['hn_id']?.toString() ?? '';
            _normalName = data['name']?.toString() ?? '';
            _normalPhoneNumber = data['phone']?.toString() ?? '';
            _normalGender = data['gender']?.toString() ?? '';
            _normalInformation = data['information']?.toString() ?? '';

            if (data['state'] is Map) {
              _normalState = data['state']['name']?.toString();
            } else {
              _normalState = data['state_name']?.toString() ?? data['state']?.toString();
            }

            if (data['district'] is Map) {
              _normalDistrict = data['district']['name']?.toString();
            } else {
              _normalDistrict = data['district_name']?.toString() ?? data['district']?.toString();
            }

            _normalCity = data['city']?.toString();
            _normalProfileImagePath = data['profile_pic']?.toString();
          }
        }
      } catch (e) {
        AppLogger.warning('Failed to fetch Normal profile: $e', tag: 'ProfileProvider');
      }
    } else {
      _normalProfileId = '';
      _normalName = '';
      _normalPhoneNumber = '';
      _normalGender = '';
      _normalInformation = '';
      _normalState = null;
      _normalDistrict = null;
      _normalCity = null;
      _normalProfileImagePath = null;
    }

    if (authProvider.isVipLoggedIn && !authProvider.isNormalLoggedIn) {
      _isVipProfile = true;
    } else if (!authProvider.isVipLoggedIn && authProvider.isNormalLoggedIn) {
      _isVipProfile = false;
    }

    _isFetching = false;
    notifyListeners();
  }

  void clearProfile() {
    _isVipProfile = false;
    _profileId = '';
    _name = '';
    _phoneNumber = '';
    _information = '';
    _gender = '';
    _state = null;
    _district = null;
    _city = null;
    _profileImagePath = null;

    _vipProfileId = '';
    _vipName = '';
    _vipPhoneNumber = '';
    _vipGender = '';
    _vipInformation = '';
    _vipState = null;
    _vipDistrict = null;
    _vipCity = null;
    _vipProfileImagePath = null;

    _normalProfileId = '';
    _normalName = '';
    _normalPhoneNumber = '';
    _normalGender = '';
    _normalInformation = '';
    _normalState = null;
    _normalDistrict = null;
    _normalCity = null;
    _normalProfileImagePath = null;

    _isFetching = false;
    notifyListeners();
  }
}