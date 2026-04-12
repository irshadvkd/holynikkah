import 'dart:io';
import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/router/app_router.dart';
import 'package:holynikkah/core/services/navigation_guard.dart';
import 'package:holynikkah/core/services/user_journey_tracker.dart';
import 'package:holynikkah/core/theme/context_extension.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/core/utils/validation_utils.dart';
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

  // Sample data - replace with your actual data source
  final List<String> states = [
    'Andhra Pradesh',
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: true,
        title: Text(
          "${widget.isVip ? 'VIP ' : ''}REGISTRATION",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
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
                            border: Border.all(color: Colors.white24),
                            image: _profileImage != null
                                ? DecorationImage(
                                    image: FileImage(_profileImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _profileImage == null
                              ? Padding(
                                  padding: EdgeInsets.all(24.sp),
                                  child: SvgPicture.asset(
                                    AppConstants.icons.user,
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
                              color: Color(0xFFFFD700),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.black,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          value: "Male",
                          groupValue: gender,
                          activeColor: AppColors.brandYellowDark,
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
                          activeColor: AppColors.brandYellowDark,
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

                SizedBox(height: 12.h),

                /// NAME
                ValidatedTextField(
                  controller: _nameController,
                  hintText: 'Your Name',
                  type: TextFieldType.name,
                  fieldName: 'Name',
                  textCapitalization: TextCapitalization.words,
                ),

                SizedBox(height: 12.h),

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

                SizedBox(height: 12.h),

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

                SizedBox(height: 12.h),

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

                SizedBox(height: 12.h),

                /// INFORMATION (OVAL SHAPE)
                OvalTextField(
                  controller: _informationController,
                  hintText: 'Information (10-500 characters)',
                  maxLines: 4,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: InputFormatters.informationFormatter(
                    maxLength: 500,
                  ),
                  validator: (value) => ValidationUtils.validateLength(
                    value,
                    minLength: 10,
                    maxLength: 500,
                    fieldName: 'Information',
                  ),
                ),

                SizedBox(height: 30.h),

                /// CONTINUE BUTTON
                GradientBorderContainer(
                  borderRadius: 25.r,
                  onTap: _continue,
                  child: Text(
                    'Continue',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 20.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Continue button action
  void _continue() async {
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

    if (cityNotifier.value == null) {
      CommonSnackBar.showError(context, 'Please select city');
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

      // CommonSnackBar.showSuccess(
      //   context,
      //   'Registration completed successfully!',
      // );

      await context.read<AuthProvider>().setLoggedIn();

      // Single navigation with delay and proper guard
      Future.delayed(const Duration(milliseconds: 800), () async {
        if (!mounted) return;

        // Replace the full stack with Home, landing on the "profile" tab.
        // (In current HomeScreen, tab index 1 is the user/profile section.)
        final PageRouteInfo nextRoute = HomeRoute(initialIndex: 0);

        final success = await context.navigationGuard.navigateTo(
          context,
          nextRoute,
          replaceAll: true,
          trigger: 'registration_complete',
          data: {'isVip': widget.isVip, 'registrationCompleted': true},
        );

        if (success) {
          // Complete the registration journey
          await UserJourneyTracker().completeJourney(
            finalData: {'isVip': widget.isVip, 'nextRoute': 'home'},
          );
        }

        final success1 = await context.navigationGuard.navigateTo(
          context,
          nextRoute,
        );


      });
    }
  }
}
