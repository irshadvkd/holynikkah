import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/widgets/gradient_border.dart';
import 'package:holynikkah/modules/category/controller/category_provider.dart';
import 'package:holynikkah/modules/login/screens/login_screen.dart';
import 'package:holynikkah/modules/registration/providers/registration_provider.dart';
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 56,
        titleSpacing: 32,
        title: Text(
          "VIP REGISTER",
          style: GoogleFonts.balooDa2(
            color: Colors.white,
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
              Container(
                width: 115.w,
                height: 35.w,
                margin: EdgeInsets.only(bottom: 16.h, top: 8.h),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(0xFFFAC60C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "PAID",
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
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
                Container(
                  width: 200.w,
                  margin: EdgeInsets.only(bottom: 8.h),
                  child: GradientBorderContainer(
                    borderRadius: 25.r,

                    /// 🔥 CONTINUE BUTTON (FINAL FIX)
                    onTap: () async {
                      if (provider.selectedCategoryId != null) {
                        /// 🔥 Update provider (THIS triggers UI instantly)
                        await context.read<CategoryProvider>().setVipSelected(
                          true,
                        );

                        /// 🔥 Stay on same tab
                        widget.onNavigate?.call(0);
                      }
                    },
                    child: Text(
                      'Continue',
                      style: GoogleFonts.inter(
                        color: Color(0xFF000000),
                        fontWeight: FontWeight.w500,
                        fontSize: 20.sp,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 200.w,
                  margin: EdgeInsets.only(bottom: 8.h),
                  child: GradientBorderContainer(
                    borderRadius: 25.r,
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(type: "vip"),
                        ),
                      );
                    },
                    child: Text(
                      'Next',
                      style: GoogleFonts.inter(
                        color: Color(0xFF000000),
                        fontWeight: FontWeight.w500,
                        fontSize: 20.sp,
                      ),
                    ),
                  ),
                ),
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
}
