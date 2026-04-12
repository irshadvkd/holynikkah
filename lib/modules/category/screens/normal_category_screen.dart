import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/router/app_router.dart';
import 'package:holynikkah/core/widgets/gradient_border.dart';
import 'package:holynikkah/modules/category/widgets/normal_category_card.dart';
import 'package:holynikkah/modules/registration/models/category_model.dart';
import 'package:holynikkah/modules/registration/providers/registration_provider.dart';
import 'package:holynikkah/modules/registration/widgets/category_card.dart';
import 'package:provider/provider.dart';

class NormalCategoryScreen extends StatefulWidget {
  const NormalCategoryScreen({super.key});

  @override
  State<NormalCategoryScreen> createState() => _NormalCategoryScreenState();
}

class _NormalCategoryScreenState extends State<NormalCategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegistrationProvider>().loadCategories("normal");
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Consumer<RegistrationProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: EdgeInsets.all(16.sp),
              child: Column(
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
                            textStyle: GoogleFonts.inter(
                              color: Color(0xFFFFFFFF),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            isSelected:
                                provider.selectedCategoryId == category.catId,
                            onTap: () => _selectCategory(category.catId ?? ""),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 16.h),
                  SearchCategoryCard(
                    category: Categories(
                      catId: "search_category",
                      icon: "",
                      name: "SEARCH BY LOCATION",
                      networth: "",
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: 50.h,
                      horizontal: 32.h,
                    ),
                    textStyle: GoogleFonts.inter(
                      color: Color(0xFFFFFFFF),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    isSelected:
                        provider.selectedCategoryId == "search_category",
                    onTap: () => _selectCategory("search_category"),
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
                              context.router.push(LoginRoute());
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
                            onTap: () {
                              if (provider.selectedCategoryId != null) {
                                context.router.push(LoginRoute());
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
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    Categories category,
    RegistrationProvider provider,
  ) {
    final isSelected = provider.selectedCategoryId == category.catId;

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
      context.router.push(HomeRoute());
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Registration failed')));
    }
  }
}
