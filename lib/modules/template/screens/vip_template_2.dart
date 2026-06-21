import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';
import 'package:holynikkah/core/widgets/common_text_field.dart';
import 'package:holynikkah/modules/template/screens/common_image_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class VipTemplateTwoScreen extends StatefulWidget {
  const VipTemplateTwoScreen({super.key});

  @override
  State<VipTemplateTwoScreen> createState() => _VipTemplateTwoScreenState();
}

class _VipTemplateTwoScreenState extends State<VipTemplateTwoScreen> {
  /// User selected image
  File? selectedImage;

  /// Description controller
  final TextEditingController descriptionController = TextEditingController();

  /// Global key for saving widget
  final GlobalKey previewContainerKey = GlobalKey();

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
    return Scaffold(
      backgroundColor: Colors.black,

      // appBar: AppBar(
      //   backgroundColor: Colors.black,
      //   elevation: 0,
      //   centerTitle: true,
      //   title: Text(
      //     "VIP Template 1",
      //     style: GoogleFonts.inter(
      //       color: Colors.white,
      //       fontSize: 18.sp,
      //       fontWeight: FontWeight.w700,
      //     ),
      //   ),
      // ),
      body: Column(
        children: [
          /// Preview Area
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

                      /// White Description Box
                      Positioned(
                        bottom: 16.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 12.h,
                          ),
                          width: MediaQuery.of(context).size.width * .7,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            descriptionController.text.isEmpty
                                ? "Type your description here..."
                                : descriptionController.text,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontSize: 15.sp,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// Bottom Controls
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
      //           CommonTextField(
      //             controller: descriptionController,
      //             hintText: "Enter description",
      //             maxLines: 4,
      //             onChanged: (value) {
      //   setState(() {});
      // },
      //           ),

                // /// Description Field
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  onChanged: (value) {
                    setState(() {});
                  },
                  style: GoogleFonts.inter(color: Colors.black, fontSize: 14.sp),
                  decoration: InputDecoration(
                    hintText: "Enter Description",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                /// Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52.h,
                        child: ElevatedButton(
                          onPressed: pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF032544),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                          child: Text(
                            "Upload Image",
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

                SizedBox(height: 10.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
