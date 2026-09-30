import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/widgets/common_button.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';
import 'package:holynikkah/modules/category/models/category_model.dart';
import 'package:holynikkah/modules/category/models/vip_tier_style.dart';
import 'package:holynikkah/modules/category/screens/normal_category_screen.dart';
import 'package:holynikkah/modules/category/widgets/animated_pattern_background.dart';
import 'package:holynikkah/modules/category/widgets/normal_category_card.dart';
import 'package:holynikkah/modules/category/widgets/vip_category_card.dart';
import 'package:holynikkah/modules/registration/services/registration_service.dart';

class CategorySelectScreen extends StatefulWidget {
  final bool isVip;
  final String? initialVipCategoryId;
  final List<String> initialNormalCategoryIds;

  const CategorySelectScreen({
    super.key,
    required this.isVip,
    this.initialVipCategoryId,
    this.initialNormalCategoryIds = const [],
  });

  @override
  State<CategorySelectScreen> createState() => _CategorySelectScreenState();
}

class _CategorySelectScreenState extends State<CategorySelectScreen> {
  List<Categories> _categories = [];
  bool _isLoading = true;

  Categories? _selectedVipCategory;
  final List<String> _selectedNormalCategoryIds = [];

  @override
  void initState() {
    super.initState();
    _selectedNormalCategoryIds.addAll(widget.initialNormalCategoryIds);
    _loadCategories();
  }

  int _getTierIndex(Categories category, int fallbackIndex) {
    final name = (category.name ?? '').toLowerCase();
    if (name.contains('middle') && !name.contains('upper')) {
      return 0; // Tier 1: Middle Class
    } else if (name.contains('upper')) {
      return 1; // Tier 2: Upper Middle Class
    } else if (name.contains('hni') ||
        (name.contains('rich') &&
            !name.contains('super') &&
            !name.contains('ultra'))) {
      return 2; // Tier 3: HNI (Rich)
    } else if (name.contains('super')) {
      return 3; // Tier 4: Super Rich
    } else if (name.contains('ultra')) {
      return 4; // Tier 5: Ultra Rich
    } else if (name.contains('billion')) {
      return 5; // Tier 6: Billionaire
    }
    if (category.sortOrder != null && category.sortOrder! > 0) {
      return category.sortOrder! - 1;
    }
    return fallbackIndex;
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final list = await RegistrationService.instance.getCategories(
        widget.isVip ? 'vip' : 'normal',
      );

      if (!mounted) return;

      setState(() {
        _categories = list;
        _isLoading = false;

        if (widget.isVip && widget.initialVipCategoryId != null) {
          for (final cat in list) {
            if (cat.catId?.toString() == widget.initialVipCategoryId.toString()) {
              _selectedVipCategory = cat;
              break;
            }
          }
        }
      });
    } catch (e) {
      AppLogger.warning(
        'Failed to load categories: $e',
        tag: 'CategorySelectScreen',
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onConfirm() {
    if (widget.isVip) {
      if (_selectedVipCategory == null) {
        CommonSnackBar.showError(context, 'Please select a VIP category');
        return;
      }
      Navigator.pop(context, {
        'vipCategory': _selectedVipCategory,
      });
    } else {
      if (_selectedNormalCategoryIds.isEmpty) {
        CommonSnackBar.showError(context, 'Please select at least one category');
        return;
      }
      final selectedList = _categories
          .where((c) => _selectedNormalCategoryIds.contains(c.catId))
          .toList();
      Navigator.pop(context, {
        'normalCategoryIds': List<String>.from(_selectedNormalCategoryIds),
        'normalCategories': selectedList,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVip = widget.isVip;

    final sortedCategories = isVip
        ? (List<Categories>.from(_categories)
          ..sort((a, b) {
            final tierA = _getTierIndex(a, 0);
            final tierB = _getTierIndex(b, 0);
            return tierA.compareTo(tierB);
          }))
        : _categories;

    return Scaffold(
      backgroundColor: isVip ? VipRegisterColors.ink : NormalCategoryColors.cream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedPatternBackground(
            backgroundImage: isVip
                ? 'assets/images/vip_category_bg.jpeg'
                : 'assets/images/moroccan_pattern.jpg',
            fit: isVip ? BoxFit.cover : BoxFit.none,
            repeat: isVip ? ImageRepeat.noRepeat : ImageRepeat.repeat,
            scale: 1.5,
            veilColor: isVip
                ? VipRegisterColors.ink.withValues(alpha: 0.35)
                : NormalCategoryColors.ink.withValues(alpha: 0.35),
            animationDuration: const Duration(seconds: 20),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isVip),
                if (_isLoading)
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: isVip
                            ? VipRegisterColors.goldDark
                            : NormalCategoryColors.gold2,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: isVip
                        ? ListView.separated(
                            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                            itemCount: sortedCategories.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(height: 16.h),
                            itemBuilder: (context, index) {
                              final category = sortedCategories[index];
                              final tierIndex = _getTierIndex(category, index);
                              final isSelected =
                                  _selectedVipCategory?.catId == category.catId;

                              return VipCategoryCard(
                                category: category,
                                tierIndex: tierIndex,
                                animationIndex: index,
                                isSelectionRequired: true,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedVipCategory = category;
                                  });
                                },
                              );
                            },
                          )
                        : Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: GridView.builder(
                              padding:
                                  EdgeInsets.only(top: 8.h, bottom: 16.h),
                              itemCount: sortedCategories.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.95,
                                crossAxisSpacing: 14.w,
                                mainAxisSpacing: 14.h,
                              ),
                              itemBuilder: (context, index) {
                                final category = sortedCategories[index];
                                final isSelected =
                                    _selectedNormalCategoryIds.contains(category.catId);

                                return NormalCategoryCard(
                                  category: category,
                                  isSelected: isSelected,
                                  index: index,
                                  isSelectionRequired: true,
                                  onTap: () {
                                    setState(() {
                                      final id = category.catId ?? '';
                                      if (id.isEmpty) return;
                                      if (_selectedNormalCategoryIds.contains(id)) {
                                        _selectedNormalCategoryIds.remove(id);
                                      } else {
                                        _selectedNormalCategoryIds.add(id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                  child: CommonButton(
                    title: 'Confirm Selection',
                    onTap: _onConfirm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isVip) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 24.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.goldLight,
                  size: 20.sp,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                isVip ? 'VIP CATEGORIES' : 'CHOOSE CATEGORY',
                style: AppTypography.cormorantGaramond(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                  color: AppColors.goldLight,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: 12.w, top: 4.h),
            child: Text(
              isVip
                  ? 'Select your VIP membership category'
                  : 'Select one or more categories for your profile',
              style: AppTypography.marcellus(
                fontSize: 13.sp,
                color: isVip
                    ? const Color(0xFFCBB388).withValues(alpha: 0.8)
                    : Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
