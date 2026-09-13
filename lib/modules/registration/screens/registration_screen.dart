import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/utils/routes.dart';
import 'package:holynikkah/core/services/user_journey_tracker.dart';
import 'package:holynikkah/core/utils/validation_utils.dart';
import 'package:holynikkah/core/widgets/common_app_bar.dart';
import 'package:holynikkah/core/widgets/widgets.dart';
import 'package:holynikkah/modules/category/controller/category_provider.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/registration/models/location_model.dart';
import 'package:holynikkah/modules/registration/models/phone_visibility.dart';
import 'package:holynikkah/modules/registration/models/vip_registration_model.dart';
import 'package:holynikkah/modules/registration/providers/registration_provider.dart';
import 'package:holynikkah/modules/registration/services/locations_service.dart';
import 'package:holynikkah/modules/registration/services/normal_registration_service.dart';
import 'package:holynikkah/modules/registration/services/vip_registration_service.dart';
import 'package:dio/dio.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/modules/registration/widgets/phone_visibility_selector.dart';
import 'package:holynikkah/modules/template/screens/common_image_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class RegistrationScreen extends StatefulWidget {
  final bool isVip;
  final String? phoneNumber;
  final String? prefilledName;
  final Map<String, dynamic>? prefillData;
  final String? email;

  const RegistrationScreen({
    super.key,
    required this.isVip,
    this.phoneNumber,
    this.prefilledName,
    this.prefillData,
    this.email,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  /// Form key
  final _formKey = GlobalKey<FormState>();

  /// Controllers
  final _profileIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _informationController = TextEditingController();
  String gender = "";
  PhoneVisibility _phoneVisibility = PhoneVisibility.visibleToAll;
  final ValueNotifier<LocationState?> stateNotifier =
      ValueNotifier<LocationState?>(null);
  final ValueNotifier<LocationDistrict?> districtNotifier =
      ValueNotifier<LocationDistrict?>(null);

  /// Location data from API
  List<LocationState> _states = [];
  List<LocationDistrict> _districts = [];
  bool _statesLoading = false;
  bool _districtsLoading = false;

  /// Loading state
  bool _isLoading = false;

  /// Secure storage
  final _storage = const FlutterSecureStorage();

  /// Image picker
  final ImagePicker _picker = ImagePicker();

  /// Selected profile image
  File? _profileImage;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();

    /// Clear any previous registration data except VIP status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RegistrationProvider>();
      provider.clearRegistrationData();
      provider.setVipStatus(widget.isVip);
      if (_phoneController.text.isNotEmpty) {
        provider.updatePhoneNumber(_phoneController.text);
      }
    });

    _profileIdController.text = generateProfileId();

    if (widget.email != null && widget.email!.isNotEmpty) {
      _emailController.text = widget.email!;
    }
    if (widget.phoneNumber != null) {
      _phoneController.text = widget.phoneNumber!;
    }
    if (widget.prefilledName != null && widget.prefilledName!.isNotEmpty) {
      _nameController.text = widget.prefilledName!;
    }

    _loadUserData();
    _loadStates();
  }

  Future<void> _loadStates() async {
    setState(() => _statesLoading = true);

    final states = await LocationsService.instance.getStates();

    if (!mounted) return;

    setState(() {
      _states = states;
      _statesLoading = false;
    });

    if (states.isEmpty) {
      CommonSnackBar.showError(context, 'Failed to load states');
      return;
    }

    // Prefill state and district if available from other registration tier
    if (widget.prefillData != null) {
      final stateId = widget.prefillData!['state_id'];
      if (stateId != null) {
        LocationState? matchedState;
        for (final s in states) {
          if (s.id == stateId || s.id.toString() == stateId.toString()) {
            matchedState = s;
            break;
          }
        }
        if (matchedState != null) {
          stateNotifier.value = matchedState;
          await _loadDistricts(matchedState.id);
          final districtId = widget.prefillData!['district_id'];
          if (districtId != null && _districts.isNotEmpty) {
            for (final d in _districts) {
              if (d.id == districtId || d.id.toString() == districtId.toString()) {
                districtNotifier.value = d;
                break;
              }
            }
          }
        }
      }
    }
  }

  Future<void> _loadDistricts(int stateId) async {
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

    if (districts.isEmpty) {
      CommonSnackBar.showError(context, 'Failed to load districts');
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

  /// Generate profile id like HN483920
  String generateProfileId() {
    final random = Random();
    int number = 100000 + random.nextInt(900000);
    return "HN$number";
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

  Future<void> _downloadImageToTemp(String url) async {
    try {
      final resolvedUrl = _resolveImageUrl(url);
      final response = await Dio().get<List<int>>(
        resolvedUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200 && response.data != null && mounted) {
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}/prefilled_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await file.writeAsBytes(response.data!);
        if (mounted && _profileImage == null) {
          setState(() {
            _profileImage = file;
          });
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to cache prefilled image: $e', tag: 'RegistrationScreen');
    }
  }

  /// Load phone number and Google user details from secure storage and prefillData
  Future<void> _loadUserData() async {
    final phoneNumber = await _storage.read(key: 'phone_number');
    final googleName = await _storage.read(key: 'google_name');
    final googleEmail = await _storage.read(key: 'google_email');
    final googlePhoto = await _storage.read(key: 'google_photo');

    String? imageUrlToDownload;

    if (!mounted) return;
    setState(() {
      if (phoneNumber != null && phoneNumber.isNotEmpty && _phoneController.text.isEmpty) {
        _phoneController.text = phoneNumber;
      }
      if (googleName != null && googleName.isNotEmpty && _nameController.text.isEmpty) {
        _nameController.text = googleName;
      }
      if (googleEmail != null && googleEmail.isNotEmpty && _emailController.text.isEmpty) {
        _emailController.text = googleEmail;
      }
      if (googlePhoto != null && googlePhoto.isNotEmpty && _profileImageUrl == null && _profileImage == null) {
        _profileImageUrl = googlePhoto;
        imageUrlToDownload = googlePhoto;
      }

      // Prefill from prefillData (e.g. from existing VIP or Normal registration)
      if (widget.prefillData != null) {
        final p = widget.prefillData!;
        if (p['email'] != null && p['email'].toString().isNotEmpty && _emailController.text.isEmpty) {
          _emailController.text = p['email'].toString();
        }
        if (p['name'] != null && p['name'].toString().isNotEmpty && _nameController.text.isEmpty) {
          _nameController.text = p['name'].toString();
        }
        if (p['phone'] != null && p['phone'].toString().isNotEmpty && _phoneController.text.isEmpty) {
          _phoneController.text = p['phone'].toString();
        }
        if (p['city'] != null && p['city'].toString().isNotEmpty) {
          _cityController.text = p['city'].toString();
        }

        // Info / Information prefill
        final infoVal = p['info'] ?? p['information'];
        if (infoVal != null && infoVal.toString().isNotEmpty && _informationController.text.isEmpty) {
          _informationController.text = infoVal.toString();
        }

        // Gender prefill (UI uses "Male" and "Female")
        if (p['gender'] != null && p['gender'].toString().isNotEmpty) {
          final g = p['gender'].toString().trim().toLowerCase();
          if (g == 'male') {
            gender = "Male";
          } else if (g == 'female') {
            gender = "Female";
          }
        }

        // Phone visibility (mob_visibility) prefill
        if (p['mob_visibility'] != null) {
          final mv = p['mob_visibility'];
          final bool isVisible = mv == true || mv.toString() == 'true' || mv == 1 || mv.toString() == '1';
          _phoneVisibility = PhoneVisibility.fromMobVisibility(isVisible);
        }

        // Profile image prefill
        final imgVal = p['image_url'] ?? p['image_path'] ?? p['profile_pic'] ?? p['image'];
        if (imgVal != null && imgVal.toString().isNotEmpty && imgVal.toString() != 'null') {
          _profileImageUrl = imgVal.toString();
          imageUrlToDownload = imgVal.toString();
        }
      }
    });

    if (imageUrlToDownload != null && imageUrlToDownload!.isNotEmpty) {
      _downloadImageToTemp(imageUrlToDownload!);
    }

    if (_phoneController.text.isNotEmpty) {
      context.read<RegistrationProvider>().updatePhoneNumber(_phoneController.text);
    }
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

  /// Pick profile image
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    if (image == null) return;

    final croppedImage = await CommonImageCropper.cropImage(
      imagePath: image.path,
      ratioX: 1,
      ratioY: 1,
    );

    if (croppedImage == null) return;

    setState(() {
      _profileImage = croppedImage;
      _profileImageUrl = null;
    });
  }

  @override
  void dispose() {
    _profileIdController.dispose();
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
      child: Stack(
        children: [
          CommonAppBar(
      title: "${widget.isVip ? 'VIP ' : ''}REGISTRATION",
      gradient: AppColors.darkGreenGradient,
      backgroundColor: AppColors.secondary,
      titleColor: Colors.white,
      leadingIconColor: AppColors.goldLight,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                                    ? DecorationImage(
                                        image: NetworkImage(_resolveImageUrl(_profileImageUrl!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                          ),
                          child: (_profileImage == null &&
                                  (_profileImageUrl == null || _profileImageUrl!.isEmpty))
                              ? Padding(
                                  padding: EdgeInsets.all(0.sp),
                                  child: SvgPicture.asset(
                                    "assets/icons/profile.svg",
                                    fit: BoxFit.fill,
                                  ),
                                )
                              : null,
                        ),

                        /// Camera icon
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

                SizedBox(height: 16.h),

                Center(
                  child: Text(
                    'Upload profile photo',
                    style: AppTypography.marcellus(
                      color: AppColors.textMuted,
                      fontSize: 14.sp,
                    ),
                  ),
                ),

                SizedBox(height: 40.h),

                /// GENDER SELECTION
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
                          value: "Male",
                          groupValue: gender,
                          activeColor: AppColors.secondary,
                          onChanged: (value) {
                            setState(() {
                              gender = "Male";
                            });
                          },
                          title: Text(
                            "Male",
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
                          value: "Female",
                          groupValue: gender,
                          activeColor: AppColors.secondary,
                          onChanged: (value) {
                            setState(() {
                              gender = "Female";
                            });
                          },
                          title: Text(
                            "Female",
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

                /// VERIFIED EMAIL
                ValidatedTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  type: TextFieldType.email,
                  fieldName: 'Email',
                  readOnly: true,
                  suffixIcon: _verifiedEmailSuffix(),
                ),

                SizedBox(height: 16.h),

                /// PHONE NUMBER
                ValidatedTextField(
                  controller: _phoneController,
                  hintText: 'Phone Number',
                  type: TextFieldType.phone,
                  fieldName: 'Phone Number',
                  keyboardType: TextInputType.phone,
                ),

                SizedBox(height: 16.h),

                /// PHONE VISIBILITY (sample UI)
                PhoneVisibilitySelector(
                  value: _phoneVisibility,
                  titleColor: Colors.white,
                  descriptionColor: AppColors.textMuted,
                  onChanged: (value) {
                    setState(() => _phoneVisibility = value);
                  },
                ),

                SizedBox(height: 16.h),

                /// NAME
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

                /// INFORMATION (OVAL SHAPE)
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

                SizedBox(height: 32.h),

                // Continue Button
                CommonButton(
                  title: 'Continue',
                  isLoading: _isLoading,
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  onTap: _continue,
                ),

                SizedBox(height: 36.h),
              ],
            ),
          ),
        ),
      ),
    ),
    if (_isLoading)
      Positioned.fill(
        child: AbsorbPointer(
          absorbing: true,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                // Blurred glass backdrop using theme background/overlay
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: AppColors.background.withValues(alpha: 0.82),
                    ),
                  ),
                ),

                // Theme-matching modal card using AppColors tokens
                Center(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 36.w),
                    padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 28.h),
                    decoration: BoxDecoration(
                      gradient: AppColors.darkGreenGradient,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: AppColors.inputBorder,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 58.sp,
                              height: 58.sp,
                              child: CircularProgressIndicator(
                                strokeWidth: 3.0,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.15),
                              ),
                            ),
                            Icon(
                              Icons.workspace_premium_rounded,
                              size: 26.sp,
                              color: AppColors.goldLight,
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          "Creating Your Profile",
                          textAlign: TextAlign.center,
                          style: AppTypography.marcellus(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.4,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "${widget.isVip ? 'VIP ' : ''}Registration in progress...",
                          textAlign: TextAlign.center,
                          style: AppTypography.marcellus(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
  ],
),
);
  }

  /// Continue button action
  void _continue() async {
    if (_isLoading) return;

    // Validate fields before activating overlay loader
    if (gender.isEmpty) {
      CommonSnackBar.showError(context, 'Please select gender');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      CommonSnackBar.showError(context, 'Please enter your name');
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

    if (_informationController.text.isEmpty) {
      CommonSnackBar.showError(context, 'Please enter about yourself');
      return;
    }

    if (_informationController.text.trim().length < 25) {
      CommonSnackBar.showError(
        context,
        'Information should be minimum 25 characters',
      );
      return;
    }

    if (_informationController.text.trim().length > 500) {
      CommonSnackBar.showError(
        context,
        'Information must not exceed 500 characters',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      CommonSnackBar.showError(
        context,
        'Please check and complete all required fields correctly',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool isSuccess = false;

    try {
      // Track registration step
      await UserJourneyTracker().trackRegistrationFlow(
        isVip: widget.isVip,
        step: 'form_validation',
        data: {
          'hasGender': gender.isNotEmpty,
          'hasName': _nameController.text.trim().isNotEmpty,
          'hasState': stateNotifier.value != null,
          'hasDistrict': districtNotifier.value != null,
          'hasCity': _cityController.text.trim().isNotEmpty,
          'hasInformation': _informationController.text.isNotEmpty,
        },
      );

      // If all validations pass
      if (true) {
        final provider = context.read<RegistrationProvider>();

        // Update provider data
        provider.setVipStatus(widget.isVip);
        provider.updateProfileId(_profileIdController.text);
        provider.updateName(_nameController.text);
        provider.updatePhoneNumber(_phoneController.text);
        provider.updateInformation(_informationController.text);

        // Track successful form completion
        await UserJourneyTracker().trackRegistrationFlow(
          isVip: widget.isVip,
          step: 'form_completed',
          data: {
            'name': _nameController.text.trim(),
            'state': stateNotifier.value?.name,
            'district': districtNotifier.value?.name,
            'city': _cityController.text.trim(),
            'informationLength': _informationController.text.trim().length,
          },
        );

        if (widget.isVip) {
          final result = await VipRegistrationService.instance.register(
            VipRegistrationRequest(
              phoneNumber: _phoneController.text.trim(),
              fullName: _nameController.text.trim(),
              gender: gender,
              stateId: stateNotifier.value!.id,
              districtId: districtNotifier.value!.id,
              city: _cityController.text.trim(),
              information: _informationController.text.trim(),
              mobVisibility: _phoneVisibility.mobVisibility,
              profilePicPath: _profileImage?.path,
              email: _emailController.text.trim().isNotEmpty
                  ? _emailController.text.trim()
                  : null,
            ),
          );

          if (!result.status) {
            if (mounted) {
              CommonSnackBar.showError(
                context,
                result.message.isNotEmpty
                    ? result.message
                    : 'Registration failed. Please try again.',
              );
            }
            return;
          }

          await context.read<AuthProvider>().setVipLoggedIn(
            token: result.token,
            user: result.user,
          );
          await context.read<CategoryProvider>().applyVipCategoryFromUser(
            result.user,
          );
        } else {
          final result = await NormalRegistrationService.instance.register(
            VipRegistrationRequest(
              phoneNumber: _phoneController.text.trim(),
              fullName: _nameController.text.trim(),
              gender: gender,
              stateId: stateNotifier.value!.id,
              districtId: districtNotifier.value!.id,
              city: _cityController.text.trim(),
              information: _informationController.text.trim(),
              mobVisibility: _phoneVisibility.mobVisibility,
              profilePicPath: _profileImage?.path,
              email: _emailController.text.trim().isNotEmpty
                  ? _emailController.text.trim()
                  : null,
            ),
          );

          if (!result.status) {
            if (mounted) {
              CommonSnackBar.showError(
                context,
                result.message.isNotEmpty
                    ? result.message
                    : 'Registration failed. Please try again.',
              );
            }
            return;
          }

          await context.read<AuthProvider>().setNormalLoggedIn(
            token: result.token,
            user: result.user,
          );
          await context.read<CategoryProvider>().applyNormalCategoryFromUser(
            result.user,
          );
        }

        isSuccess = true;

        // Single navigation with delay and proper guard
        Future.delayed(const Duration(milliseconds: 800), () async {
          if (!mounted) return;

          Navigator.of(context).pushNamedAndRemoveUntil(
            Routes.home,
            (route) => false,
            arguments: {'initialIndex': widget.isVip ? 0 : 1},
          );
        });
      }
    } catch (e) {
      if (mounted) {
        CommonSnackBar.showError(
          context,
          'Registration failed. Please try again.',
        );
      }
    } finally {
      if (mounted && !isSuccess) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
