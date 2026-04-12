import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CommonBottomNav extends StatelessWidget {
  final List<BottomNavItem> items;
  final int currentIndex;
  final Function(int)? onTap;

  const CommonBottomNav({
    super.key,
    required this.items,
    this.currentIndex = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isActive = index == currentIndex;
          
          return GestureDetector(
            onTap: () => onTap?.call(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  color: isActive ? Colors.white : Colors.grey[400],
                  size: 20.sp,
                ),
                SizedBox(height: 2.h),
                Text(
                  item.label,
                  style: GoogleFonts.inter(
                    color: isActive ? Colors.white : Colors.grey[400],
                    fontSize: 9.sp,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;

  const BottomNavItem({
    required this.icon,
    required this.label,
  });
}