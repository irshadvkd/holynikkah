import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/modules/category/models/category_model.dart';

class VipCategoryCard extends StatefulWidget {
  const VipCategoryCard({
    super.key,
    required this.category,
    required this.tierIndex,
    required this.isSelected,
    required this.isSelectionRequired,
    required this.onTap,
    this.animationIndex = 0,
  });

  final Categories category;
  final int tierIndex;
  final bool isSelected;
  final bool isSelectionRequired;
  final VoidCallback onTap;
  final int animationIndex;

  @override
  State<VipCategoryCard> createState() => _VipCategoryCardState();
}

class _VipCategoryCardState extends State<VipCategoryCard>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _sheenController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );

    Future<void>.delayed(
      Duration(milliseconds: 50 + widget.animationIndex * 80),
      () {
        if (mounted) _entryController.forward();
      },
    );
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _sheenController.repeat();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _sheenController.dispose();
    super.dispose();
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

  static const List<Map<String, Color>> _defaultTierPalettes = [
    {
      'start': Color(0xFF12315A),
      'end': Color(0xFF0B2242),
      'text': Color(0xFFE8D28A),
    },
    {
      'start': Color(0xFFF0863A),
      'end': Color(0xFFDE690A),
      'text': Color(0xFFFFE9D2),
    },
    {
      'start': Color(0xFFF6D949),
      'end': Color(0xFFEAC012),
      'text': Color(0xFF5B4A05),
    },
    {
      'start': Color(0xFFA9DBE2),
      'end': Color(0xFF7FBFC9),
      'text': Color(0xFF8A5A17),
    },
    {
      'start': Color(0xFFF5A0BB),
      'end': Color(0xFFE8688F),
      'text': Color(0xFFFFE9F0),
    },
    {
      'start': Color(0xFF5FC28D),
      'end': Color(0xFF3B9C68),
      'text': Color(0xFFE9FFF3),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final tierLabel =
        'Tier ${(widget.tierIndex + 1).toString().padLeft(2, '0')} · Class';
    final netWorth = _formatNetWorth(widget.category.networth);
    final crownCount = widget.tierIndex + 1;

    final defaultPalette = _defaultTierPalettes[
        widget.tierIndex.clamp(0, _defaultTierPalettes.length - 1)];

    final gradientColors = [
      _parseColor(widget.category.bgColor, defaultPalette['start']!),
      _parseColor(widget.category.gradientEndColor, defaultPalette['end']!),
    ];
    final textColor = _parseColor(widget.category.textColor, defaultPalette['text']!);
    final classNameColor = _parseColor(widget.category.textColor, defaultPalette['text']!);
    final crownColor = _parseColor(widget.category.textColor, defaultPalette['text']!);

    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 14.h * (1 - _entryController.value)),
          child: Opacity(
            opacity: _entryController.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.isSelectionRequired ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFFF3D68A) // NormalCategoryColors.gold1
                  : const Color(0x38FFFAF0), // glass line border
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              if (widget.isSelected)
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19.r),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: const Alignment(-0.9, -1),
                        end: const Alignment(0.9, 1),
                        colors: gradientColors,
                        stops: const [0, 0.7],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1,
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                _SheenOverlay(
                  controller: _sheenController,
                  borderRadius: 19.r,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 20.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tierLabel,
                              style: AppTypography.cormorantGaramond(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: textColor.withValues(alpha: 0.8),
                              ),
                            ),
                            SizedBox(height: 9.h),
                            Text(
                              widget.category.name ?? '',
                              style: AppTypography.cormorantGaramond(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                                letterSpacing: 0.2,
                                color: classNameColor,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            _CrownRow(
                              count: crownCount,
                              color: crownColor,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 56.h,
                        margin: EdgeInsets.symmetric(horizontal: 12.w),
                        color: textColor.withValues(alpha: 0.35),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'NET WORTH',
                              style: AppTypography.cormorantGaramond(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.6,
                                color: textColor.withValues(alpha: 0.75),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              netWorth,
                              textAlign: TextAlign.right,
                              style: AppTypography.cormorantGaramond(
                                fontSize: 16.5.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.isSelectionRequired) ...[
                        SizedBox(width: 16.w),
                        Icon(
                          widget.isSelected ? Icons.check_circle_rounded : Icons.add_rounded,
                          color: widget.isSelected
                              ? const Color(0xFFF3D68A)
                              : Colors.white.withValues(alpha: 0.6),
                          size: 24.sp,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatNetWorth(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('-', '–')
        .trim();
  }
}

class _SheenOverlay extends StatelessWidget {
  const _SheenOverlay({
    required this.controller,
    required this.borderRadius,
  });

  final AnimationController controller;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        final sweep = t < 0.18 ? t / 0.18 : 1.0;
        final left = -0.6 + sweep * 1.9;
        return Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return Stack(
                    children: [
                      Positioned(
                        left: width * left,
                        top: -constraints.maxHeight * 0.5,
                        child: Transform.rotate(
                          angle: 0.14,
                          child: Container(
                            width: width * 0.4,
                            height: constraints.maxHeight * 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: 0.16),
                                  Colors.transparent,
                                ],
                                stops: const [0.2, 0.5, 0.8],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CrownRow extends StatelessWidget {
  const _CrownRow({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        count,
        (_) => Padding(
          padding: EdgeInsets.only(right: 3.w),
          child: SvgPicture.asset(
            AppConstants.icons.crown,
            width: 11.sp,
            height: 11.sp,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
