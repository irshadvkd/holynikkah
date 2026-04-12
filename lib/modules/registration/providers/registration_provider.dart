import 'package:flutter/material.dart';
import 'package:holynikkah/modules/registration/models/category_model.dart';
import 'package:holynikkah/modules/registration/models/registration_model.dart';
import 'package:holynikkah/modules/registration/services/registration_service.dart';

class RegistrationProvider extends ChangeNotifier {
  final RegistrationService _service = RegistrationService.instance;
  
  // Registration data
  String _profileId = '';
  String _name = '';
  String _phoneNumber = '';
  String _information = '';
  bool _isVip = false;
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  
  // Categories
  List<Categories> _categories = [];
  bool _categoriesLoading = false;
  
  // OTP
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _isLoading = false;

  // Getters
  String get profileId => _profileId;
  String get name => _name;
  String get phoneNumber => _phoneNumber;
  String get information => _information;
  bool get isVip => _isVip;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedSubcategoryId => _selectedSubcategoryId;
  List<Categories> get categories => _categories;
  bool get categoriesLoading => _categoriesLoading;
  bool get otpSent => _otpSent;
  bool get otpVerified => _otpVerified;
  bool get isLoading => _isLoading;

  void updateProfileId(String value) {
    _profileId = value;
    notifyListeners();
  }

  void updateName(String value) {
    _name = value;
    notifyListeners();
  }

  void updatePhoneNumber(String value) {
    _phoneNumber = value;
    notifyListeners();
  }

  void updateInformation(String value) {
    _information = value;
    notifyListeners();
  }

  void setVipStatus(bool isVip) {
    _isVip = isVip;
    notifyListeners();
  }

  void selectCategory(String categoryId, [String? subcategoryId]) {
    _selectedCategoryId = categoryId;
    _selectedSubcategoryId = subcategoryId;
    notifyListeners();
  }

  Future<void> loadCategories(String type) async {
    _categoriesLoading = true;
    notifyListeners();

    _categories = await _service.getCategories(type);
    _categoriesLoading = false;
    notifyListeners();
  }

  Future<bool> sendOtp() async {
    _isLoading = true;
    notifyListeners();
    
    final success = await _service.sendOtp(_phoneNumber);
    _otpSent = success;
    _isLoading = false;
    notifyListeners();
    
    return success;
  }

  Future<bool> verifyOtp(String otp) async {
    _isLoading = true;
    notifyListeners();
    
    final success = await _service.verifyOtp(_phoneNumber, otp);
    _otpVerified = success;
    _isLoading = false;
    notifyListeners();
    
    return success;
  }

  Future<bool> submitRegistration() async {
    _isLoading = true;
    notifyListeners();
    
    final registration = RegistrationModel(
      profileId: _profileId,
      name: _name,
      phoneNumber: _phoneNumber,
      information: _information,
      isVip: _isVip,
      categoryId: _selectedCategoryId,
      subcategoryId: _selectedSubcategoryId,
    );
    
    final success = await _service.submitRegistration(registration);
    _isLoading = false;
    notifyListeners();
    
    return success;
  }

  void reset() {
    _profileId = '';
    _name = '';
    _phoneNumber = '';
    _information = '';
    _isVip = false;
    _selectedCategoryId = null;
    _selectedSubcategoryId = null;
    _otpSent = false;
    _otpVerified = false;
    _isLoading = false;
    notifyListeners();
  }
}