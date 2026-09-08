import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/modules/category/widgets/animated_pattern_background.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';
import 'package:holynikkah/modules/category/controller/category_provider.dart';
import 'package:holynikkah/modules/category/models/vip_tier_style.dart';
import 'package:holynikkah/modules/category/widgets/vip_category_card.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/login/screens/login_screen.dart';
import 'package:holynikkah/modules/registration/providers/registration_provider.dart';
import 'package:holynikkah/modules/registration/services/vip_category_service.dart';
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
      backgroundColor: VipRegisterColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedPatternBackground(
            backgroundImage: 'assets/images/vip_category_bg.jpeg',
            fit: BoxFit.cover,
            repeat: ImageRepeat.noRepeat,
            veilColor: VipRegisterColors.ink.withValues(alpha: 0.35),
          ),
          SafeArea(
            bottom: false,
            child: Consumer<RegistrationProvider>(
                builder: (context, provider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      if (provider.categoriesLoading)
                        Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: VipRegisterColors.goldDark,
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 8.h),
                            itemCount: provider.categories.length,
                            separatorBuilder: (_, __) => SizedBox(height: 16.h),
                            itemBuilder: (context, index) {
                              final category = provider.categories[index];
                              final tierIndex = int.tryParse(
                                    category.catId ?? '${index + 1}',
                                  ) ??
                                  (index + 1);
                              return VipCategoryCard(
                                category: category,
                                tierIndex: tierIndex - 1,
                                animationIndex: index,
                                isSelectionRequired:
                                    widget.isSelectionRequired,
                                isSelected: widget.isSelectionRequired &&
                                    provider.selectedCategoryId ==
                                        category.catId,
                                onTap: () =>
                                    _selectCategory(category.catId ?? ''),
                              );
                            },
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
      padding: EdgeInsets.fromLTRB(24.w, 6.h, 24.w, 22.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'MEMBERSHIP DIRECTORY',
                style: AppTypography.marcellus(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.0,
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
          SizedBox(height: 8.h),
          RichText(
            text: TextSpan(
              style: AppTypography.marcellus(
                fontSize: 34.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.75),
                    offset: const Offset(0, 2),
                    blurRadius: 12,
                  ),
                ],
              ),
              children: [
                TextSpan(
                  text: 'VIP ',
                  style: AppTypography.marcellus(color: const Color(0xFFF3D68A)),
                ),
                TextSpan(
                  text: 'Register',
                  style: AppTypography.marcellus(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectCategory(String categoryId) {
    context.read<RegistrationProvider>().selectCategory(categoryId);
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen(type: 'vip')),
    );
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

      final authProvider = context.read<AuthProvider>();
      final categoryProvider = context.read<CategoryProvider>();

      await authProvider.updateStoredVipCategorySelected(true);
      await categoryProvider.setVipSelected(true);
      if (!mounted) return;
      widget.onNavigate?.call(0);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
              Color(0xFFF3D68A),
              Color(0xFFC9973F),
              Color(0xFFD98F3F),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC9973F).withValues(alpha: 0.4),
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
                      VipRegisterColors.ink,
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
                      color: VipRegisterColors.ink,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18.sp,
                    color: VipRegisterColors.ink,
                  ),
                ],
              ),
      ),
    );
  }
}
