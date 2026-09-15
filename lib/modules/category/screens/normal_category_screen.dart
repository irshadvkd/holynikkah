import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/modules/category/widgets/animated_pattern_background.dart';
import 'package:holynikkah/modules/category/widgets/normal_category_card.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';
import 'package:holynikkah/modules/category/controller/category_provider.dart';
import 'package:holynikkah/modules/login/screens/login_screen.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/registration/providers/registration_provider.dart';
import 'package:holynikkah/modules/registration/services/normal_category_service.dart';
import 'package:provider/provider.dart';

class NormalCategoryColors {
  static const Color background = Color(0xFF241A10);
  static const Color inkDeep = Color(0xFF120E08);
  static const Color ink = Color(0xFF1A140C);
  static const Color gold1 = Color(0xFFF3D68A);
  static const Color gold2 = Color(0xFFC9973F);
  static const Color gold3 = Color(0xFF8A6A2A);
  static const Color cream = Color(0xFFFFFAF0);
  static const Color taupe = Color(0xFFA68A72);
  static const Color sage = Color(0xFF6F8F5F);
  static const Color glassLine = Color(0x38FFFAF0);
  static const Color cardBg = Color(0x3D120E08);
  static const Color cardSelectedBg = Color(0xFF382917);
}

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
  bool _isSubmitting = false;

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
      backgroundColor: NormalCategoryColors.cream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedPatternBackground(
            backgroundImage: 'assets/images/moroccan_pattern.jpg',
            fit: BoxFit.none,
            repeat: ImageRepeat.repeat,
            scale: 1.5,
            veilColor: NormalCategoryColors.ink.withValues(alpha: 0.35),
            animationDuration: const Duration(seconds: 15),
          ),
          SafeArea(
            child: Consumer<RegistrationProvider>(
              builder: (context, provider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    if (provider.categoriesLoading)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: NormalCategoryColors.gold2,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: GridView.builder(
                            padding: EdgeInsets.only(top: 4.h, bottom: 16.h),
                            itemCount: provider.categories.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.98,
                                  crossAxisSpacing: 14.w,
                                  mainAxisSpacing: 14.h,
                                ),
                            itemBuilder: (context, index) {
                              final category = provider.categories[index];
                              final isSelected = widget.isSelectionRequired &&
                                  (provider.selectedCategoryIds
                                          .contains(category.catId) ||
                                      provider.selectedCategoryId ==
                                          category.catId);
                              return NormalCategoryCard(
                                category: category,
                                isSelected: isSelected,
                                index: index,
                                onTap: () =>
                                    _toggleCategory(category.catId ?? ""),
                                isSelectionRequired: widget.isSelectionRequired,
                              );
                            },
                          ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                      child: _buildActionButton(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 6.h, 24.w, 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'CHOOSE CATEGORY',
                style: AppTypography.cormorantGaramond(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.0,
                  height: 1.0,
                  color: const Color(0xFFF3D68A).withValues(alpha: 0.9),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFC9973F).withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Register',
                style: AppTypography.italiana(
                  fontSize: 34.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  height: 1.1,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.75),
                      offset: const Offset(0, 2),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 6.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999.r),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      NormalCategoryColors.gold1,
                      NormalCategoryColors.gold2,
                      NormalCategoryColors.gold3,
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'FREE',
                  style: AppTypography.marcellus(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                    color: NormalCategoryColors.inkDeep,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildActionButton() {
    final title = widget.isSelectionRequired ? "Continue" : "Next";

    return GestureDetector(
      onTap: _isSubmitting
          ? null
          : (widget.isSelectionRequired ? _continueWithCategory : _goToLogin),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.r),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              NormalCategoryColors.gold1,
              NormalCategoryColors.gold2,
              Color(0xFFD98F3F),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: NormalCategoryColors.gold2.withValues(alpha: 0.4),
              offset: const Offset(0, 8),
              blurRadius: 18,
              spreadRadius: -4,
            ),
          ],
        ),
        child: _isSubmitting
            ? Center(
                child: SizedBox(
                  height: 20.h,
                  width: 20.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      NormalCategoryColors.inkDeep,
                    ),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTypography.marcellus(
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.14,
                      color: NormalCategoryColors.inkDeep,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18.sp,
                    color: NormalCategoryColors.inkDeep,
                  ),
                ],
              ),
      ),
    );
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(type: "normal"),
      ),
    );
  }

  void _toggleCategory(String categoryId) {
    final provider = context.read<RegistrationProvider>();
    provider.toggleCategory(categoryId);
  }

  Future<void> _continueWithCategory() async {
    final provider = context.read<RegistrationProvider>();
    final selectedCategoryIds = provider.selectedCategoryIds.isNotEmpty
        ? provider.selectedCategoryIds
        : (provider.selectedCategoryId != null
            ? [provider.selectedCategoryId!]
            : <String>[]);

    if (selectedCategoryIds.isEmpty) {
      CommonSnackBar.showError(
        context,
        'Please select at least one category to continue',
      );
      return;
    }

    final categoryIdInts = selectedCategoryIds
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toList();

    if (categoryIdInts.isEmpty) {
      CommonSnackBar.showError(context, 'Invalid category selected');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await context.read<AuthProvider>().ensureApiTokenFor(isVip: false);

      final result = await NormalCategoryService.instance.selectCategory(
        categoryIds: categoryIdInts,
      );

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

      final userData = result.data?['user'] is Map<String, dynamic>
          ? result.data!['user'] as Map<String, dynamic>
          : (result.data is Map<String, dynamic> && result.data!.containsKey('hn_id'))
              ? result.data
              : null;

      if (userData != null) {
        await context.read<AuthProvider>().updateStoredNormalUser(userData);
        if (!mounted) return;
      }

      await context.read<AuthProvider>().updateStoredNormalCategorySelected(
        true,
      );
      if (!mounted) return;
      await context.read<CategoryProvider>().setNormalSelected(true);
      widget.onNavigate?.call(1);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
