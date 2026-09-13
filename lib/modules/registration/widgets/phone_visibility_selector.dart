import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/theme/context_extension.dart';
import 'package:holynikkah/modules/registration/models/phone_visibility.dart';

class PhoneVisibilitySelector extends StatelessWidget {
  const PhoneVisibilitySelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.titleColor,
    this.descriptionColor,
  });

  final PhoneVisibility value;
  final ValueChanged<PhoneVisibility> onChanged;
  final Color? titleColor;
  final Color? descriptionColor;

  String _description(PhoneVisibility option) {
    return switch (option) {
      PhoneVisibility.visibleToAll =>
        'Your mobile number is visible to everyone on your profile.',
      PhoneVisibility.onRequest =>
        'Your number is hidden by default and only shared when you approve a request.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Phone number visibility',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Phone visibility',
                style: AppTypography.marcellus(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: titleColor ?? AppColors.inputText,
                ),
              ),
              SizedBox(width: 6.w),
              Tooltip(
                message:
                    'Choose whether your number is public or shared only on request',
                triggerMode: TooltipTriggerMode.tap,
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 16.sp,
                  color: titleColor != null
                      ? titleColor!.withValues(alpha: 0.7)
                      : AppColors.inputHint,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            height: 50.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50.r),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF303036).withValues(alpha: 0.7),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SegmentButton(
                    label: PhoneVisibility.visibleToAll.label,
                    icon: Icons.visibility_outlined,
                    isSelected: value == PhoneVisibility.visibleToAll,
                    isFirst: true,
                    onTap: () => onChanged(PhoneVisibility.visibleToAll),
                  ),
                ),
                Container(
                  width: 1,
                  height: 30.h,
                  color: AppColors.inputText,
                ),
                Expanded(
                  child: _SegmentButton(
                    label: PhoneVisibility.onRequest.label,
                    icon: Icons.mark_email_unread_outlined,
                    isSelected: value == PhoneVisibility.onRequest,
                    isLast: true,
                    onTap: () => onChanged(PhoneVisibility.onRequest),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _description(value),
              key: ValueKey(value),
              style: AppTypography.marcellus(
                fontSize: 12.sp,
                height: 1.35,
                color: descriptionColor ?? AppColors.inputHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF0E1F16);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.horizontal(
          left: isFirst ? Radius.circular(50.r) : Radius.zero,
          right: isLast ? Radius.circular(50.r) : Radius.zero,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? Radius.circular(50.r) : Radius.zero,
            right: isLast ? Radius.circular(50.r) : Radius.zero,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? _primary : Colors.transparent,
              borderRadius: BorderRadius.horizontal(
                left: isFirst ? Radius.circular(50.r) : Radius.zero,
                right: isLast ? Radius.circular(50.r) : Radius.zero,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18.sp,
                  color: isSelected ? Colors.white : AppColors.inputHint,
                ),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.marcellus(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.inputText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
