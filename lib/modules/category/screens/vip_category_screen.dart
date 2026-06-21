import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/widgets/common_button.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';
import 'package:holynikkah/core/widgets/gradient_border.dart';
import 'package:holynikkah/modules/category/controller/category_provider.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/login/screens/login_screen.dart';
import 'package:holynikkah/modules/registration/providers/registration_provider.dart';
import 'package:holynikkah/modules/registration/services/vip_category_service.dart';
import 'package:holynikkah/modules/registration/widgets/category_card.dart';
import 'package:provider/provider.dart';

class VipCategoryScreen extends StatefulWidget {
  final bool isSelectionRequired;
  final Function(int)? onNavigate;
  const VipCategoryScreen({
    super.key,
    required this.isSelectionRequired,
    this.onNavigate,
  });

  @override
  State<VipCategoryScreen> createState() => _VipCategoryScreenState();
}

class _VipCategoryScreenState extends State<VipCategoryScreen> {
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegistrationProvider>().clearRegistrationData();
      context.read<RegistrationProvider>().setVipStatus(true);
      context.read<RegistrationProvider>().loadCategories('vip');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 56,
        titleSpacing: 32,
        title: Text(
          "VIP REGISTER",
          style: GoogleFonts.balooDa2(
            color: Colors.black,
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: Consumer<RegistrationProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Align(
              //   alignment: Alignment.centerRight,
              //   child: Container(
              //     width: 85.w,
              //     height: 35.w,
              //     margin: EdgeInsets.only(bottom: 16.h, top: 8.h, right: 32.w),
              //     alignment: Alignment.center,
              //     decoration: BoxDecoration(
              //       color: Color(0xFFFAC60C),
              //       borderRadius: BorderRadius.circular(10),
              //       border: Border.all(color: Colors.black),
              //     ),
              //     child: Text(
              //       "PAID",
              //       style: GoogleFonts.inter(
              //         fontSize: 20.sp,
              //         fontWeight: FontWeight.w600,
              //         color: Colors.black,
              //       ),
              //     ),
              //   ),
              // ),
              if (provider.categoriesLoading)
                Expanded(
                  child: const Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.categories.length,
                    itemBuilder: (context, index) {
                      final category = provider.categories[index];
                      return CategoryCard(
                        isVip: true,
                        category: category,
                        isSelectionRequired: widget.isSelectionRequired,
                        isSelected:
                            provider.selectedCategoryId == category.catId,
                        onTap: () => _selectCategory(category.catId ?? ""),
                      );
                    },
                  ),
                ),

              SizedBox(height: 16.h),

              // Padding(
              //   padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: GradientBorderContainer(
              //           borderRadius: 25.r,
              //           onTap: () {
              //             // Just close the modal without saving category selection
              //             if (widget.onNavigate != null) {
              //               widget.onNavigate!(0); // Stay on Profile tab
              //             }
              //           },
              //           child: Text(
              //             'Skip',
              //             style: GoogleFonts.inter(
              //               color: Color(0xFF000000),
              //               fontWeight: FontWeight.w500,
              //               fontSize: 20.sp,
              //             ),
              //           ),
              //         ),
              //       ),
              //       SizedBox(width: 10.w),
              //       Expanded(
              //         child: GradientBorderContainer(
              //           borderRadius: 25.r,
              //           onTap: () async {
              //             // Only save if a category is actually selected
              //             if (provider.selectedCategoryId != null) {
              //               await CategorySessionStorage()
              //                   .setCategorySelected(true);
              //               if (widget.onNavigate != null) {
              //                 widget.onNavigate!(0); // Stay on Profile tab
              //               }
              //             }
              //           },
              //           child: Text(
              //             'Continue',
              //             style: GoogleFonts.inter(
              //               color: Color(0xFF000000),
              //               fontWeight: FontWeight.w500,
              //               fontSize: 20.sp,
              //             ),
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // )
              if (widget.isSelectionRequired)
                CommonButton(
                  title: "Continue",
                  isLoading: _isSubmitting,
                  onTap: _isSubmitting ? () {} : _continueWithCategory,
                )
              else
                CommonButton(
                  title: "Next",
                  onTap: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(type: "vip"),
                      ),
                    );
                  },
                ),
              SizedBox(height: 16.h),
            ],
          );
        },
      ),
    );
  }

  void _selectCategory(String categoryId) {
    final provider = context.read<RegistrationProvider>();
    provider.selectCategory(categoryId);
  }

  Future<void> _continueWithCategory() async {
    final provider = context.read<RegistrationProvider>();
    final selectedCategoryId = provider.selectedCategoryId;

    if (selectedCategoryId == null) {
      CommonSnackBar.showError(
        context,
        'Please select category to continue',
      );
      return;
    }

    final vipCategoryId = int.tryParse(selectedCategoryId);
    if (vipCategoryId == null) {
      CommonSnackBar.showError(context, 'Invalid category selected');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await context.read<AuthProvider>().ensureApiTokenFor(isVip: true);

      final result =
          await VipCategoryService.instance.selectCategory(vipCategoryId);

      if (!mounted) return;

      if (!result.status) {
        CommonSnackBar.showError(
          context,
          result.message.isNotEmpty
              ? result.message
              : 'Failed to select category',
        );
        return;
      }

      await context.read<AuthProvider>().updateStoredVipCategorySelected(true);
      await context.read<CategoryProvider>().setVipSelected(true);
      widget.onNavigate?.call(0);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
