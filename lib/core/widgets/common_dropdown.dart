import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class CommonDropdown<T> extends StatelessWidget {
  final String hintText;
  final ValueNotifier<T?> valueListenable;
  final List<T> items;
  final Function(T?) onChanged;
  final String Function(T) itemLabel;
  final String? Function(T?)? validator;

  const CommonDropdown({
    super.key,
    required this.hintText,
    required this.valueListenable,
    required this.items,
    required this.onChanged,
    required this.itemLabel,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<T>(
          isExpanded: true,
          hint: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              hintText,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          items: items
              .map((item) => DropdownItem<T>(
                    value: item,
                    height: 50.h,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        itemLabel(item),
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ))
              .toList(),
          valueListenable: valueListenable,
          onChanged: onChanged,
          buttonStyleData: ButtonStyleData(
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25.r),
              color: Colors.white,
            ),
          ),
          iconStyleData: IconStyleData(
            icon: const Icon(Icons.keyboard_arrow_down),
            iconSize: 24.sp,
            iconEnabledColor: Colors.black45,
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 200.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.r),
              color: Colors.white,
            ),
          ),
          menuItemStyleData: MenuItemStyleData(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
          ),
        ),
      ),
    );
  }
}