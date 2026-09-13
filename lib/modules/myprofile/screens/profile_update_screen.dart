import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:holynikkah/core/api/api_client.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/core/utils/validation_utils.dart';
import 'package:holynikkah/core/widgets/common_app_bar.dart';
import 'package:holynikkah/core/widgets/common_button.dart';
import 'package:holynikkah/core/widgets/common_dropdown.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';
import 'package:holynikkah/core/widgets/validated_text_field.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/myprofile/providers/profile_provider.dart';
import 'package:holynikkah/modules/registration/models/location_model.dart';
import 'package:holynikkah/modules/registration/models/phone_visibility.dart';
import 'package:holynikkah/modules/registration/services/locations_service.dart';
import 'package:holynikkah/modules/registration/widgets/phone_visibility_selector.dart';
import 'package:holynikkah/modules/template/screens/common_image_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileUpdateScreen extends StatefulWidget {
  final bool isVip;

  const ProfileUpdateScreen({
    super.key,
    this.isVip = false,
  });

  @override
  State<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _informationController = TextEditingController();

  String gender = '';
  PhoneVisibility _phoneVisibility = PhoneVisibility.visibleToAll;

  final ValueNotifier<LocationState?> stateNotifier =
      ValueNotifier<LocationState?>(null);
  final ValueNotifier<LocationDistrict?> districtNotifier =
      ValueNotifier<LocationDistrict?>(null);

  List<LocationState> _states = [];
  List<LocationDistrict> _districts = [];
  bool _statesLoading = false;
  bool _districtsLoading = false;
  bool _isLoading = false;

  File? _profileImage;
  String? _profileImageUrl;
  bool _hasNewImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadStates();
  }

  void _loadProfileData() {
    final provider = context.read<ProfileProvider>();
    final isVip = widget.isVip;

    _nameController.text = provider.getName(isVip);
    _phoneController.text = provider.getPhone(isVip);
    _informationController.text = provider.getInfo(isVip);
    _cityController.text = provider.getCity(isVip) ?? '';

    final g = provider.getGender(isVip).trim().toLowerCase();
    if (g == 'male') {
      gender = 'Male';
    } else if (g == 'female') {
      gender = 'Female';
    } else {
      gender = provider.getGender(isVip);
    }

    final imagePath = provider.getProfileImagePath(isVip);
    if (imagePath != null && imagePath.isNotEmpty) {
      if (imagePath.startsWith('/') && !imagePath.startsWith('/api')) {
        _profileImage = File(imagePath);
      } else {
        _profileImageUrl = imagePath;
      }
    }

    // Load email & mob_visibility from stored user
    final auth = context.read<AuthProvider>();
    auth.getStoredUser(isVip: isVip).then((user) {
      if (user != null && mounted) {
        final email = user['email']?.toString();
        if (email != null && email.isNotEmpty && _emailController.text.isEmpty) {
          setState(() {
            _emailController.text = email;
          });
        }
        if (user['mob_visibility'] != null) {
          final mv = user['mob_visibility'];
          final isVisible = mv == true ||
              mv.toString() == 'true' ||
              mv == 1 ||
              mv.toString() == '1';
          setState(() {
            _phoneVisibility = PhoneVisibility.fromMobVisibility(isVisible);
          });
        }
      }
    });
  }

  Future<void> _loadStates() async {
    setState(() => _statesLoading = true);

    final states = await LocationsService.instance.getStates();

    if (!mounted) return;

    setState(() {
      _states = states;
      _statesLoading = false;
    });

    final provider = context.read<ProfileProvider>();
    final currentStateName = provider.getState(widget.isVip)?.trim();
    final currentDistrictName = provider.getDistrict(widget.isVip)?.trim();

    if (currentStateName != null && currentStateName.isNotEmpty) {
      LocationState? matchedState;
      for (final s in states) {
        if (s.name.toLowerCase() == currentStateName.toLowerCase()) {
          matchedState = s;
          break;
        }
      }
      if (matchedState != null) {
        stateNotifier.value = matchedState;
        await _loadDistricts(matchedState.id, preselectName: currentDistrictName);
      }
    }
  }

  Future<void> _loadDistricts(int stateId, {String? preselectName}) async {
    setState(() {
      _districtsLoading = true;
      _districts = [];
    });

    final districts = await LocationsService.instance.getDistricts(stateId);

    if (!mounted) return;

    setState(() {
      _districts = districts;
      _districtsLoading = false;
    });

    if (preselectName != null && preselectName.isNotEmpty) {
      for (final d in districts) {
        if (d.name.toLowerCase() == preselectName.toLowerCase()) {
          districtNotifier.value = d;
          break;
        }
      }
    }
  }

  void _onStateChanged(LocationState? value) {
    stateNotifier.value = value;
    districtNotifier.value = null;
    _cityController.clear();

    if (value != null) {
      _loadDistricts(value.id);
    } else {
      setState(() => _districts = []);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image == null) return;

    final croppedImage = await CommonImageCropper.cropImage(
      imagePath: image.path,
      ratioX: 1,
      ratioY: 1,
      compressQuality: 85,
    );

    if (croppedImage == null) return;

    setState(() {
      _profileImage = croppedImage;
      _profileImageUrl = null;
      _hasNewImage = true;
    });
  }

  String _resolveImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final base = AppConstants.urls.imageBaseUrl;
    final cleanBase = base.endsWith('/') ? base : '$base/';
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$cleanBase$cleanPath';
  }

  Widget _verifiedEmailSuffix() {
    return Padding(
      padding: EdgeInsets.only(right: 12.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            color: const Color(0xFF2E7D32),
            size: 22.sp,
          ),
          SizedBox(width: 4.w),
          Text(
            'Verified',
            style: AppTypography.marcellus(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitUpdate() async {
    if (_isLoading) return;

    if (gender.isEmpty) {
      CommonSnackBar.showError(context, 'Please select gender');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      CommonSnackBar.showError(context, 'Please enter your name');
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      CommonSnackBar.showError(context, 'Please enter phone number');
      return;
    }

    if (stateNotifier.value == null) {
      CommonSnackBar.showError(context, 'Please select state');
      return;
    }

    if (districtNotifier.value == null) {
      CommonSnackBar.showError(context, 'Please select district');
      return;
    }

    if (_cityController.text.trim().isEmpty) {
      CommonSnackBar.showError(context, 'Please enter city');
      return;
    }

    if (_informationController.text.trim().length < 25) {
      CommonSnackBar.showError(
        context,
        'Information must be between 25 and 500 characters',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final isVip = widget.isVip;

      await auth.ensureApiTokenFor(isVip: isVip);

      final endpoint = isVip
          ? '/vip-users/update-profile'
          : '/normal-users/update-profile';

      final formDataMap = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gender': gender.toLowerCase(),
        'state_id': stateNotifier.value!.id,
        'district_id': districtNotifier.value!.id,
        'city': _cityController.text.trim(),
        'info': _informationController.text.trim(),
        'mob_visibility': _phoneVisibility.mobVisibility ? '1' : '0',
      };

      if (_emailController.text.trim().isNotEmpty) {
        formDataMap['email'] = _emailController.text.trim();
      }

      if (_profileImage != null && _hasNewImage) {
        final filename = _profileImage!.path.split('/').last;
        formDataMap['image'] = await MultipartFile.fromFile(
          _profileImage!.path,
          filename: filename,
        );
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await ApiClient.instance.upload<dynamic>(
        endpoint,
        formData: formData,
        parser: (json) => json,
      );

      Map<String, dynamic>? updatedUser;
      if (response.success && response.data != null) {
        final body = response.data;
        if (body is Map) {
          final inner = body['data'];
          if (inner is Map) {
            updatedUser = Map<String, dynamic>.from(inner);
          } else {
            updatedUser = Map<String, dynamic>.from(body);
          }
        }
      }

      if (!mounted) return;

      if (!response.success || updatedUser == null) {
        final errorMsg = response.message?.isNotEmpty == true
            ? response.message!
            : (response.error?.message ?? 'Failed to update profile on server.');
        CommonSnackBar.showError(context, errorMsg);
        return;
      }

      context.read<ProfileProvider>().applyUserData(updatedUser, isVip: isVip);
      if (_hasNewImage && _profileImage != null) {
        context.read<ProfileProvider>().updateProfileImage(_profileImage!.path, isVip: isVip);
      }
      if (isVip) {
        await auth.updateStoredVipUser(updatedUser);
      } else {
        await auth.updateStoredNormalUser(updatedUser);
      }

      if (mounted) {
        CommonSnackBar.showSuccess(context, 'Profile updated successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      AppLogger.error('Failed to update profile: $e', tag: 'ProfileUpdateScreen');
      if (mounted) {
        CommonSnackBar.showError(context, 'Failed to update profile. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _informationController.dispose();
    stateNotifier.dispose();
    districtNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: CommonAppBar(
        title: widget.isVip ? 'EDIT VIP PROFILE' : 'EDIT PROFILE',
        gradient: AppColors.darkGreenGradient,
        backgroundColor: AppColors.secondary,
        titleColor: Colors.white,
        leadingIconColor: AppColors.goldLight,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.h),

                  /// PROFILE IMAGE
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            height: 116.sp,
                            width: 116.sp,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              image: _profileImage != null
                                  ? DecorationImage(
                                      image: FileImage(_profileImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : (_profileImageUrl != null &&
                                          _profileImageUrl!.isNotEmpty)
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            _resolveImageUrl(_profileImageUrl!),
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                            ),
                            child: (_profileImage == null &&
                                    (_profileImageUrl == null ||
                                        _profileImageUrl!.isEmpty))
                                ? Padding(
                                    padding: EdgeInsets.all(0.sp),
                                    child: SvgPicture.asset(
                                      'assets/icons/profile.svg',
                                      fit: BoxFit.fill,
                                    ),
                                  )
                                : null,
                          ),

                          /// Camera icon overlay
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.goldMain,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  Center(
                    child: Text(
                      'Tap to change photo',
                      style: AppTypography.marcellus(
                        color: AppColors.textMuted,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),

                  SizedBox(height: 28.h),

                  /// GENDER SELECTION PILL
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF303036).withValues(alpha: 0.7),
                          offset: const Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50.r),
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              value: 'Male',
                              groupValue: gender,
                              activeColor: AppColors.secondary,
                              onChanged: (value) {
                                setState(() => gender = 'Male');
                              },
                              title: Text(
                                'Male',
                                style: AppTypography.marcellus(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            color: AppColors.black.withValues(alpha: 0.2),
                            height: 30,
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              value: 'Female',
                              groupValue: gender,
                              activeColor: AppColors.secondary,
                              onChanged: (value) {
                                setState(() => gender = 'Female');
                              },
                              title: Text(
                                'Female',
                                style: AppTypography.marcellus(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  /// EMAIL (Read-only verified)
                  if (_emailController.text.isNotEmpty) ...[
                    ValidatedTextField(
                      controller: _emailController,
                      hintText: 'Email',
                      type: TextFieldType.email,
                      fieldName: 'Email',
                      readOnly: true,
                      suffixIcon: _verifiedEmailSuffix(),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  /// PHONE NUMBER
                  ValidatedTextField(
                    controller: _phoneController,
                    hintText: 'Phone Number',
                    type: TextFieldType.phone,
                    fieldName: 'Phone Number',
                    keyboardType: TextInputType.phone,
                  ),

                  SizedBox(height: 16.h),

                  /// PHONE VISIBILITY
                  PhoneVisibilitySelector(
                    value: _phoneVisibility,
                    titleColor: Colors.white,
                    descriptionColor: AppColors.textMuted,
                    onChanged: (value) {
                      setState(() => _phoneVisibility = value);
                    },
                  ),

                  SizedBox(height: 16.h),

                  /// FULL NAME
                  ValidatedTextField(
                    controller: _nameController,
                    hintText: 'Your Name',
                    type: TextFieldType.name,
                    fieldName: 'Name',
                    textCapitalization: TextCapitalization.words,
                  ),

                  SizedBox(height: 16.h),

                  /// STATE DROPDOWN
                  CommonDropdown<LocationState>(
                    hintText: _statesLoading
                        ? 'Loading states...'
                        : _states.isEmpty
                            ? 'No states available'
                            : 'Select State',
                    searchHintText: 'Search state...',
                    noResultsText: 'No state found',
                    enabled: !_statesLoading && _states.isNotEmpty,
                    valueListenable: stateNotifier,
                    items: _states,
                    itemLabel: (state) => state.name,
                    onChanged: _onStateChanged,
                  ),

                  SizedBox(height: 16.h),

                  /// DISTRICT DROPDOWN
                  ValueListenableBuilder<LocationState?>(
                    valueListenable: stateNotifier,
                    builder: (context, selectedState, child) {
                      return CommonDropdown<LocationDistrict>(
                        hintText: selectedState == null
                            ? 'Select state first'
                            : _districtsLoading
                                ? 'Loading districts...'
                                : _districts.isEmpty
                                    ? 'No districts available'
                                    : 'Select District',
                        searchHintText: 'Search district...',
                        noResultsText: 'No district found',
                        enabled: selectedState != null &&
                            !_districtsLoading &&
                            _districts.isNotEmpty,
                        valueListenable: districtNotifier,
                        items: selectedState != null ? _districts : [],
                        itemLabel: (district) => district.name,
                        onChanged: (value) {
                          districtNotifier.value = value;
                          _cityController.clear();
                        },
                      );
                    },
                  ),

                  SizedBox(height: 16.h),

                  /// CITY
                  ValidatedTextField(
                    controller: _cityController,
                    hintText: 'City',
                    type: TextFieldType.general,
                    fieldName: 'City',
                    textCapitalization: TextCapitalization.words,
                  ),

                  SizedBox(height: 16.h),

                  /// INFORMATION (BIO)
                  ValidatedTextField(
                    controller: _informationController,
                    hintText: 'Information (25-500 characters)',
                    maxLines: 4,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    customFormatters: InputFormatters.informationFormatter(
                      maxLength: 500,
                    ),
                    customValidator: (value) => ValidationUtils.validateLength(
                      value,
                      minLength: 25,
                      maxLength: 500,
                      fieldName: 'Information',
                    ),
                  ),

                  SizedBox(height: 28.h),

                  /// SAVE CHANGES BUTTON
                  CommonButton(
                    title: 'Save Changes',
                    isLoading: _isLoading,
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    onTap: _submitUpdate,
                  ),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}