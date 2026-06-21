import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/theme/context_extension.dart';
import 'package:holynikkah/core/utils/validation_utils.dart';
import 'package:holynikkah/core/widgets/common_app_bar.dart';
import 'package:holynikkah/core/widgets/widgets.dart';
import 'package:holynikkah/modules/myprofile/providers/profile_provider.dart';
import 'package:holynikkah/modules/template/screens/common_image_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileUpdateScreen extends StatefulWidget {
  const ProfileUpdateScreen({super.key});

  @override
  State<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _informationController = TextEditingController();
  String gender = "";
  final ValueNotifier<String?> stateNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> districtNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> cityNotifier = ValueNotifier<String?>(null);
  bool _isLoading = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

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

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final provider = context.read<ProfileProvider>();
    _nameController.text = provider.name;
    _phoneController.text = provider.phoneNumber;
    _informationController.text = provider.information;
    gender = provider.gender;
    stateNotifier.value = provider.state;
    districtNotifier.value = provider.district;
    cityNotifier.value = provider.city;
  }

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
    stateNotifier.dispose();
    districtNotifier.dispose();
    cityNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CommonAppBar(
      title: "PROFILE UPDATE",
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            border: Border.all(color: AppColors.inputBorder),
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
                    'Update profile photo',
                    style: GoogleFonts.inter(
                      color: AppColors.inputHint,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                SizedBox(height: 40.h),
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
                    color: AppColors.inputFill,
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
                ValidatedTextField(
                  controller: _nameController,
                  hintText: 'Your Name',
                  type: TextFieldType.name,
                  fieldName: 'Name',
                  textCapitalization: TextCapitalization.words,
                ),
                SizedBox(height: 16.h),
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
                ValidatedTextField(
                  controller: _informationController,
                  hintText: 'Information (25-500 characters)',
                  maxLines: 4,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
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
                    title: "Update Profile",
                    isLoading: _isLoading,
                    onTap: _updateProfile,
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

  void _updateProfile() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
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

      if (_informationController.text.trim().length < 25) {
        CommonSnackBar.showError(
          context,
          'Information should be minimum 25 characters',
        );
        return;
      }

      if (_formKey.currentState!.validate()) {
        final provider = context.read<ProfileProvider>();
        
        provider.setVipProfile(false);
        provider.updateName(_nameController.text);
        provider.updatePhoneNumber(_phoneController.text);
        provider.updateInformation(_informationController.text);
        provider.updateGender(gender);
        provider.updateLocation(
          stateNotifier.value,
          districtNotifier.value,
          cityNotifier.value,
        );
        
        if (_profileImage != null) {
          provider.updateProfileImage(_profileImage!.path);
        }

        CommonSnackBar.showSuccess(context, 'Profile updated successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      CommonSnackBar.showError(context, 'Update failed. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}