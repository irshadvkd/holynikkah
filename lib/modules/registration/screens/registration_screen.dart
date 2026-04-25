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
import 'package:holynikkah/core/widgets/gradient_border.dart';
import 'package:holynikkah/core/widgets/widgets.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/registration/providers/registration_provider.dart';
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
  final _informationController = TextEditingController();
  String gender = "";
  final ValueNotifier<String?> stateNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> districtNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> cityNotifier = ValueNotifier<String?>(null);

  /// Loading state
  bool _isLoading = false;

  // Sample data - replace with your actual data source
  final List<String> states = [
    'Karnataka',
    'Kerala',
    'Tamil Nadu',
    'Telangana',
    'Maharashtra',
    'Gujarat',
    'Rajasthan',
    'Uttar Pradesh',
    'West Bengal',
  ];

  final Map<String, List<String>> districts = {
    'Karnataka': ['Bangalore Urban', 'Mysore', 'Mangalore', 'Hubli'],
    'Kerala': ['Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Thrissur'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Salem'],
    'Telangana': ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar'],
  };

  final Map<String, List<String>> cities = {
    'Bangalore Urban': ['Bangalore', 'Whitefield', 'Electronic City'],
    'Mysore': ['Mysore City', 'Mandya', 'Chamarajanagar'],
    'Chennai': ['Chennai City', 'Tambaram', 'Velachery'],
    'Hyderabad': ['Hyderabad City', 'Secunderabad', 'Gachibowli'],
  };

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
    });

    /// Generate random profile id
    _profileIdController.text = generateProfileId();

    /// Load phone number from previous screen
    if (widget.phoneNumber != null) {
      _phoneController.text = widget.phoneNumber!;
    } else {
      _loadPhoneNumber();
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
    if (phoneNumber != null) {
      _phoneController.text = phoneNumber;
    }
  }

  /// Pick profile image
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  @override
  void dispose() {
    stateNotifier.dispose();
    districtNotifier.dispose();
    cityNotifier.dispose();
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
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF303036).withOpacity(.7),
                        offset: Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
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
                CommonDropdown<String>(
                  hintText: 'Select State',
                  valueListenable: stateNotifier,
                  items: states,
                  itemLabel: (state) => state,
                  onChanged: (value) {
                    stateNotifier.value = value;
                    districtNotifier.value = null;
                    cityNotifier.value = null;
                  },
                ),

                SizedBox(height: 16.h),

                /// DISTRICT DROPDOWN
                ValueListenableBuilder<String?>(
                  valueListenable: stateNotifier,
                  builder: (context, selectedState, child) {
                    return CommonDropdown<String>(
                      hintText: 'Select District',
                      valueListenable: districtNotifier,
                      items: selectedState != null
                          ? (districts[selectedState] ?? [])
                          : [],
                      itemLabel: (district) => district,
                      onChanged: (value) {
                        districtNotifier.value = value;
                        cityNotifier.value = null;
                      },
                    );
                  },
                ),

                SizedBox(height: 16.h),

                /// CITY DROPDOWN
                ValueListenableBuilder<String?>(
                  valueListenable: districtNotifier,
                  builder: (context, selectedDistrict, child) {
                    return CommonDropdown<String>(
                      hintText: 'Select City',
                      valueListenable: cityNotifier,
                      items: selectedDistrict != null
                          ? (cities[selectedDistrict] ?? [])
                          : [],
                      itemLabel: (city) => city,
                      onChanged: (value) {
                        cityNotifier.value = value;
                      },
                    );
                  },
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
          'hasCity': cityNotifier.value != null,
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

      if (cityNotifier.value == null) {
        setState(() {
          _isLoading = false;
        });
        CommonSnackBar.showError(context, 'Please select city');
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
            'state': stateNotifier.value,
            'district': districtNotifier.value,
            'city': cityNotifier.value,
            'informationLength': _informationController.text.trim().length,
          },
        );

        if (widget.isVip) {
          await context.read<AuthProvider>().setVipLoggedIn();
        } else {
          await context.read<AuthProvider>().setNormalLoggedIn();
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
