import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/modules/category/models/category_model.dart';

/// A card widget representing a normal category with custom gradient styling,
/// icon, and selection state.
class NormalCategoryCard extends StatelessWidget {
  final Categories category;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;
  final bool isSelectionRequired;

  const NormalCategoryCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.index,
    required this.onTap,
    required this.isSelectionRequired,
  });

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Color _parseColor(String? hex, Color defaultColor) {
    if (hex == null || hex.isEmpty) return defaultColor;
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return defaultColor;
    }
  }

  IconData _getIconData(String? iconName, IconData defaultIcon) {
    switch (iconName?.toLowerCase()) {
      case 'home':
        return Icons.home_outlined;
      case 'star':
        return Icons.star_outline_rounded;
      case 'business':
      case 'work':
        return Icons.business_center_outlined;
      case 'description':
      case 'document':
        return Icons.description_outlined;
      case 'person':
        return Icons.person_outline_rounded;
      default:
        return defaultIcon;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = [
      _parseColor(category.bgColor, const Color(0xFFA68A72)),
      _parseColor(category.gradientEndColor, const Color(0xFF7A6350)),
    ];
    final icon = _getIconData(category.icon, Icons.star_outline_rounded);
    final textColor = _parseColor(category.textColor, Colors.white);

    final number = '0${index + 1}';
    final name = _toTitleCase(category.name ?? '');

    return GestureDetector(
      onTap: isSelectionRequired ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF3D68A) // NormalCategoryColors.gold1
                : const Color(0x38FFFAF0), // glass line border
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFFF3D68A).withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 2,
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: textColor, size: 20.sp),
                ),
                if (isSelectionRequired)
                  Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.add_rounded,
                    color: isSelected
                        ? const Color(0xFFF3D68A)
                        : Colors.white.withValues(alpha: 0.6),
                    size: 22.sp,
                  ),
              ],
            ),
            const Spacer(),
            Text(
              number,
              style: AppTypography.marcellus(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.88,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              name,
              style: AppTypography.marcellus(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.08,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
