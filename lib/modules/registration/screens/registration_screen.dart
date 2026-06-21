import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/utils/routes.dart';
import 'package:holynikkah/core/services/navigation_guard.dart';
import 'package:holynikkah/core/services/user_journey_tracker.dart';
import 'package:holynikkah/core/theme/context_extension.dart';
import 'package:holynikkah/core/utils/constants.dart';
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
import 'package:holynikkah/modules/registration/widgets/phone_visibility_selector.dart';
import 'package:holynikkah/modules/template/screens/common_image_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class RegistrationScreen extends StatefulWidget {
  final bool isVip;
  final String? phoneNumber;

  const RegistrationScreen({super.key, required this.isVip, this.phoneNumber});

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

    if (widget.phoneNumber != null) {
      _phoneController.text = widget.phoneNumber!;
    } else {
      _loadPhoneNumber();
    }

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

  /// Load phone number from secure storage
  Future<void> _loadPhoneNumber() async {
    final phoneNumber = await _storage.read(key: 'phone_number');
    if (phoneNumber != null && mounted) {
      setState(() {
        _phoneController.text = phoneNumber;
      });
      context.read<RegistrationProvider>().updatePhoneNumber(phoneNumber);
    }
  }

  Widget _verifiedPhoneSuffix() {
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
            style: GoogleFonts.inter(
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
    });
  }

  @override
  void dispose() {
    _profileIdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _informationController.dispose();
    stateNotifier.dispose();
    districtNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CommonAppBar(
      title: "${widget.isVip ? 'VIP ' : ''}REGISTRATION",
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
                            border: Border.all(color: Colors.black26),
                            image: _profileImage != null
                                ? DecorationImage(
                                    image: FileImage(_profileImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _profileImage == null
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
                            padding: EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF032544),
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
                    style: GoogleFonts.inter(
                      color: Colors.grey,
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
                        color: Color(0xFF303036).withOpacity(.7),
                        offset: Offset(0, 4),
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
                          activeColor: Color(0xFF032544),
                          onChanged: (value) {
                            setState(() {
                              gender = "Male";
                            });
                          },
                          title: Text(
                            "Male",
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inputText,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        color: AppColors.inputText,
                        height: 30,
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          value: "Female",
                          groupValue: gender,
                          activeColor: Color(0xFF032544),
                          onChanged: (value) {
                            setState(() {
                              gender = "Female";
                            });
                          },
                          title: Text(
                            "Female",
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inputText,
                            ),
                          ),
                        ),
                      ),
                    ],
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                /// VERIFIED PHONE
                CustomTextField(
                  controller: _phoneController,
                  hintText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  readOnly: true,
                  suffixIcon: _verifiedPhoneSuffix(),
                ),

                SizedBox(height: 16.h),

                /// PHONE VISIBILITY (sample UI)
                PhoneVisibilitySelector(
                  value: _phoneVisibility,
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

                SizedBox(height: 30.h),
                Center(
                  child: CommonButton(
                    title: "Continue",
                    isLoading: _isLoading,
                    onTap: _continue,
                  ),
                ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Continue button action
  void _continue() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

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

      if (gender.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        CommonSnackBar.showError(context, 'Please select gender');
        return;
      }

      if (_nameController.text.trim().isEmpty) {
        setState(() {
          _isLoading = false;
        });
        CommonSnackBar.showError(context, 'Please enter your name');
        return;
      }

      if (stateNotifier.value == null) {
        setState(() {
          _isLoading = false;
        });
        CommonSnackBar.showError(context, 'Please select state');
        return;
      }

      if (districtNotifier.value == null) {
        setState(() {
          _isLoading = false;
        });
        CommonSnackBar.showError(context, 'Please select district');
        return;
      }

      if (_cityController.text.trim().isEmpty) {
        setState(() {
          _isLoading = false;
        });
        CommonSnackBar.showError(context, 'Please enter city');
        return;
      }

      if (_informationController.text.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        CommonSnackBar.showError(context, 'Please enter about yourself');
        return;
      }

      if (_informationController.text.trim().length < 25) {
        setState(() {
          _isLoading = false;
        });
        CommonSnackBar.showError(
          context,
          'Information should be minimum 25 characters',
        );
        return;
      }

      if (_informationController.text.trim().length > 500) {
        setState(() {
          _isLoading = false;
        });
        CommonSnackBar.showError(
          context,
          'Information must not exceed 500 characters',
        );
        return;
      }

      // If all validations pass
      if (_formKey.currentState!.validate()) {
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
