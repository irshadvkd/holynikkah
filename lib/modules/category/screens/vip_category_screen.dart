import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/router/app_router.dart';
import 'package:holynikkah/core/services/category_session_storage.dart';
import 'package:holynikkah/core/widgets/gradient_border.dart';
import 'package:holynikkah/modules/home/screens/home_screen.dart';
import 'package:holynikkah/modules/registration/providers/registration_provider.dart';
import 'package:holynikkah/modules/registration/widgets/category_card.dart';
import 'package:provider/provider.dart';

@RoutePage()
class VipCategoryScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const VipCategoryScreen({super.key, this.onNavigate});

  @override
  State<VipCategoryScreen> createState() => _VipCategoryScreenState();
}

class _VipCategoryScreenState extends State<VipCategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegistrationProvider>().loadCategories('vip');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<RegistrationProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Row(
              //   children: [
              //     Expanded(
              //       child: Container(
              //         height: 67.h,
              //         alignment: Alignment.center,
              //         padding: EdgeInsets.symmetric(horizontal: 16.w),
              //         decoration: BoxDecoration(
              //           color: Color(0xFF57B957),
              //           borderRadius: BorderRadius.circular(1.r),
              //         ),
              //         child: Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           mainAxisAlignment: MainAxisAlignment.center,
              //           children: [
              //             Text(
              //               'With Categorize',
              //               style: GoogleFonts.inter(
              //                 color: Color(0xFFFFFFFF),
              //                 fontSize: 15.sp,
              //                 fontWeight: FontWeight.w600,
              //               ),
              //             ),
              //             Text(
              //               '(Visible Categorised profile only)',
              //               style: GoogleFonts.inter(
              //                 color: Color(0xFFFFFFFF),
              //                 fontSize: 11.sp,
              //                 fontWeight: FontWeight.w600,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //     ),
              //     Expanded(
              //       child: Container(
              //         height: 67.h,
              //         alignment: Alignment.center,
              //         padding: EdgeInsets.symmetric(horizontal: 12.w),
              //         decoration: BoxDecoration(
              //           color: Color(0xFFC42929),
              //           borderRadius: BorderRadius.circular(1.r),
              //         ),
              //         child: Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           mainAxisAlignment: MainAxisAlignment.center,
              //           children: [
              //             Text(
              //               'Without Categorize',
              //               style: GoogleFonts.inter(
              //                 color: Color(0xFFFFFFFF),
              //                 fontSize: 15.sp,
              //                 fontWeight: FontWeight.w600,
              //               ),
              //             ),
              //             Text(
              //               '(Visible all profiles)',
              //               style: GoogleFonts.inter(
              //                 color: Color(0xFFFFFFFF),
              //                 fontSize: 11.sp,
              //                 fontWeight: FontWeight.w600,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
              // SizedBox(height: 16.h),
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
                        isSelected:
                            provider.selectedCategoryId == category.catId,
                        onTap: () => _selectCategory(category.catId ?? ""),
                      );
                    },
                  ),
                ),

              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                child: Row(
                  children: [
                    Expanded(
                      child: GradientBorderContainer(
                        borderRadius: 25.r,
                        onTap: () {
                          // Just close the modal without saving category selection
                          if (widget.onNavigate != null) {
                            widget.onNavigate!(0); // Stay on Profile tab
                          }
                        },
                        child: Text(
                          'Skip',
                          style: GoogleFonts.inter(
                            color: Color(0xFF000000),
                            fontWeight: FontWeight.w500,
                            fontSize: 20.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: GradientBorderContainer(
                        borderRadius: 25.r,
                        onTap: () async {
                          // Only save if a category is actually selected
                          if (provider.selectedCategoryId != null) {
                            await CategorySessionStorage().setCategorySelected(true);
                            if (widget.onNavigate != null) {
                              widget.onNavigate!(0); // Stay on Profile tab
                            }
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
                    ),
                  ],
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
