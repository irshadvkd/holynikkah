import 'package:flutter/material.dart';

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

  // Getters
  bool get isVipProfile => _isVipProfile;
  String get profileId => _profileId;
  String get name => _name;
  String get phoneNumber => _phoneNumber;
  String get information => _information;
  String get gender => _gender;
  String? get state => _state;
  String? get district => _district;
  String? get city => _city;
  String? get profileImagePath => _profileImagePath;

  // Setters
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
    notifyListeners();
  }
}