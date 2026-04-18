import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/utils/routes.dart';
import 'package:holynikkah/core/widgets/gradient_border.dart';
import 'package:holynikkah/modules/category/controller/category_provider.dart';
import 'package:holynikkah/modules/category/widgets/normal_category_card.dart';
import 'package:holynikkah/modules/login/screens/login_screen.dart';
import 'package:holynikkah/modules/registration/models/category_model.dart';
import 'package:holynikkah/modules/registration/providers/registration_provider.dart';
import 'package:holynikkah/modules/registration/widgets/category_card.dart';
import 'package:provider/provider.dart';

class NormalCategoryScreen extends StatefulWidget {
  final bool isSelectionRequired;
  final Function(int)? onNavigate;
  const NormalCategoryScreen({
    super.key,
    required this.isSelectionRequired,
    this.onNavigate,
  });

  @override
  State<NormalCategoryScreen> createState() => _NormalCategoryScreenState();
}

class _NormalCategoryScreenState extends State<NormalCategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegistrationProvider>().clearRegistrationData();
      context.read<RegistrationProvider>().setVipStatus(false);
      context.read<RegistrationProvider>().loadCategories("normal");
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
          "REGISTER",
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
                  "FREE",
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
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                    child: GridView.builder(
                      itemCount: provider.categories.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5.h,
                        crossAxisSpacing: 16.sp,
                        mainAxisSpacing: 16.sp,
                      ),
                      itemBuilder: (context, index) {
                        final category = provider.categories[index];
                        // return _buildCategoryCard(category, provider);
                        return CategoryCard(
                          isVip: false,
                          category: category,
                          isSelectionRequired: widget.isSelectionRequired,
                          textStyle: GoogleFonts.inter(
                            color: Color(0xFFFFFFFF),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          isSelected: provider.selectedCategoryIds.contains(
                            category.catId,
                          ),
                          onTap: () => _selectCategory(category.catId ?? ""),
                        );
                      },
                    ),
                  ),
                ),
              SizedBox(height: 16.h),

              // SearchCategoryCard(
              //   category: Categories(
              //     catId: "search_category",
              //     icon: "",
              //     name: "SEARCH BY LOCATION",
              //     networth: "",
              //   ),
              //   padding: EdgeInsets.symmetric(
              //     vertical: 50.h,
              //     horizontal: 32.h,
              //   ),
              //   textStyle: GoogleFonts.inter(
              //     color: Color(0xFFFFFFFF),
              //     fontSize: 13.sp,
              //     fontWeight: FontWeight.w500,
              //   ),
              //   isSelected:
              //       provider.selectedCategoryId == "search_category",
              //   onTap: () => _selectCategory("search_category"),
              // ),
              // SizedBox(height: 16.h),
              // Padding(
              //   padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: GradientBorderContainer(
              //           borderRadius: 25.r,
              //           onTap: () {
              //             Navigator.of(context).pushNamed(Routes.login);
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
              //             if (provider.selectedCategoryId != null) {
              //               if (widget.isSelectionRequired) {
              //                 await context
              //                     .read<CategoryProvider>()
              //                     .setNormalSelected(true);
              //                 widget.onNavigate?.call(1);
              //               } else {
              //                 Navigator.of(context).pushNamed(Routes.login);
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
              // ),
              if (widget.isSelectionRequired)
                Container(
                  width: 200.w,
                  margin: EdgeInsets.only(bottom: 8.h),
                  child: GradientBorderContainer(
                    borderRadius: 25.r,

                    /// 🔥 CONTINUE BUTTON (FINAL FIX)
                    onTap: () async {
                      if (provider.selectedCategoryIds.isNotEmpty) {
                        /// 🔥 Update provider (THIS triggers UI instantly)
                        await context
                            .read<CategoryProvider>()
                            .setNormalSelected(true);

                        /// 🔥 Stay on same tab
                        widget.onNavigate?.call(1);
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
                          builder: (context) => LoginScreen(type: "normal"),
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

  Widget _buildCategoryCard(
    Categories category,
    RegistrationProvider provider,
  ) {
    final isSelected = provider.selectedCategoryIds.contains(category.catId);

    return GestureDetector(
      onTap: () => _selectCategory(category.catId ?? ""),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color.fromRGBO(31, 36, 33, 0.94),
              Color.fromRGBO(199, 199, 199, 0.6768),
            ],
          ),
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF5F5F5),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Colors.green : Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 8.h),
            Expanded(
              child: Text(
                category.name ?? "",
                style: GoogleFonts.inter(
                  color: Color(0xFFFFFFFF),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectCategory(String categoryId) {
    final provider = context.read<RegistrationProvider>();
    provider.selectCategory(categoryId);
  }

  void _continue(context) async {
    print("hhe");
    final provider = context.read<RegistrationProvider>();
    final success = await provider.submitRegistration();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration completed successfully!')),
      );
      Navigator.of(context).pushNamed(Routes.home);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Registration failed')));
    }
  }
}
