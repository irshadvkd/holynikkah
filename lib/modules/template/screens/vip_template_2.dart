import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';
import 'package:holynikkah/modules/template/screens/common_image_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class VipTemplateTwoScreen extends StatefulWidget {
  const VipTemplateTwoScreen({super.key});

  @override
  State<VipTemplateTwoScreen> createState() => _VipTemplateTwoScreenState();
}

class _VipTemplateTwoScreenState extends State<VipTemplateTwoScreen> {
  /// Page controller for the two-step (form -> preview) flow
  final PageController pageController = PageController();

  /// User selected image
  File? selectedImage;

  /// Form fields
  final TextEditingController titleController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController idealController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController educationController = TextEditingController();
  final TextEditingController financialController = TextEditingController();
  final TextEditingController placeController = TextEditingController();

  /// Form key for validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Global key for saving widget
  final GlobalKey previewContainerKey = GlobalKey();

  /// Status bar style for the white form page
  static const SystemUiOverlayStyle _lightStatusBar = SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  /// Current status bar style (defaults to the white form page)
  SystemUiOverlayStyle _statusBarStyle = _lightStatusBar;

  @override
  void initState() {
    super.initState();
    pageController.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    if (_statusBarStyle != _lightStatusBar) {
      setState(() => _statusBarStyle = _lightStatusBar);
    }
  }

  @override
  void dispose() {
    pageController.removeListener(_onPageScroll);
    pageController.dispose();
    titleController.dispose();
    ageController.dispose();
    idealController.dispose();
    heightController.dispose();
    educationController.dispose();
    financialController.dispose();
    placeController.dispose();
    super.dispose();
  }

  /// Pick image from gallery
  Future<void> pickImage() async {
    final picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    if (image == null) return;

    /// Crop image
    final croppedImage = await CommonImageCropper.cropImage(
      imagePath: image.path,
    );

    if (croppedImage == null) return;

    setState(() {
      selectedImage = croppedImage;
    });
  }

  /// Go to preview page
  void goToPreview() {
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (selectedImage == null) {
      CommonSnackBar.showError(context, 'Please upload an image');
      return;
    }

    FocusScope.of(context).unfocus();
    pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Back to the form page
  void goToForm() {
    pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Save template image
  Future<void> saveTemplate() async {
    try {
      RenderRepaintBoundary boundary =
          previewContainerKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3);

      final byteData = await image.toByteData(format: ImageByteFormat.png);

      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();

      final file = File('${directory.path}/vip_template.png');

      await file.writeAsBytes(pngBytes);

      CommonSnackBar.showSuccess(context, 'Template saved successfully');

      debugPrint(file.path);
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _statusBarStyle,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: PageView(
          controller: pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildFormPage(),
            _buildPreviewPage(),
          ],
        ),
      ),
    );
  }

  /// ─────────────────────────────────────────────
  /// PAGE 1 : Form
  /// ─────────────────────────────────────────────
  Widget _buildFormPage() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
        children: [
          /// Header
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                ),
                Expanded(
                  child: Text(
                    "Create VIP Template",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF032544),
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: 40.w),
              ],
            ),
          ),

          /// Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      label: "Title",
                      controller: titleController,
                    ),
                    _buildField(
                      label: "വയസ്സ്",
                      controller: ageController,
                      keyboardType: TextInputType.number,
                    ),
                    _buildField(
                      label: "ആദർശം",
                      controller: idealController,
                    ),
                    _buildField(
                      label: "ഉയരം",
                      controller: heightController,
                    ),
                    _buildField(
                      label: "വിദ്യാഭ്യാസം",
                      controller: educationController,
                    ),
                    _buildField(
                      label: "സാമ്പത്തികം",
                      controller: financialController,
                    ),
                    _buildField(
                      label: "സ്ഥലം",
                      controller: placeController,
                    ),

                    SizedBox(height: 8.h),

                    /// Image upload
                    Text(
                      "Image",
                      style: GoogleFonts.inter(
                        color: Colors.black87,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 180.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14.r),
                                child: Image.file(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 40.sp,
                                    color: const Color(0xFF032544),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    "Upload Image",
                                    style: GoogleFonts.inter(
                                      color: Colors.black54,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
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

          /// Preview button
          Padding(
            padding: EdgeInsets.all(16.w),
            child: SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: goToPreview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF032544),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  "Preview",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// Single labeled text field
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansMalayalam(
              color: Colors.black87,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? "Required" : null,
            style: GoogleFonts.inter(color: Colors.black, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: "Enter $label",
              hintStyle: GoogleFonts.notoSansMalayalam(
                color: Colors.grey.shade500,
                fontSize: 13.sp,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ─────────────────────────────────────────────
  /// PAGE 2 : Preview
  /// ─────────────────────────────────────────────
  Widget _buildPreviewPage() {
    return Container(
      color: Colors.white,
      child: SafeArea(
      child: Column(
      children: [
        /// Header
        Padding(
          padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: goToForm,
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              ),
              Expanded(
                child: Text(
                  "Preview",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF032544),
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 40.w),
            ],
          ),
        ),

        /// Preview area
        Expanded(
          child: Center(
            child: RepaintBoundary(
              key: previewContainerKey,
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    /// Background Image
                    Positioned.fill(
                      child: selectedImage != null
                          ? Image.file(selectedImage!, fit: BoxFit.cover)
                          : Image.asset(
                              "assets/sample/template/vip_1_image.png",
                              fit: BoxFit.cover,
                            ),
                    ),

                    /// White Details Box
                    Positioned(
                      bottom: 16.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                        width: MediaQuery.of(context).size.width * .75,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (titleController.text.trim().isNotEmpty) ...[
                              Text(
                                titleController.text,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.notoSansMalayalam(
                                  color: const Color(0xFF032544),
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 8.h),
                            ],
                            _previewRow("വയസ്സ്", ageController.text),
                            _previewRow("ആദർശം", idealController.text),
                            _previewRow("ഉയരം", heightController.text),
                            _previewRow("വിദ്യാഭ്യാസം", educationController.text),
                            _previewRow("സാമ്പത്തികം", financialController.text),
                            _previewRow("സ്ഥലം", placeController.text),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        /// Bottom controls
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: goToForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF032544),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      "Edit",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: SizedBox(
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: saveTemplate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      "Save",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      ),
      ),
    );
  }

  /// Single label : value row inside the preview box
  Widget _previewRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label : ",
            style: GoogleFonts.notoSansMalayalam(
              color: Colors.black87,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.notoSansMalayalam(
                color: Colors.black87,
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
