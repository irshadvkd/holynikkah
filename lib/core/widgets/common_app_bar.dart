import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_typography.dart';

class CommonAppBar extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? backgroundColor;
  final Color? appBarBackgroundColor;
  final Color? leadingIconColor;
  final Color? titleColor;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final List<Widget>? actions;
  final Gradient? gradient;

  const CommonAppBar({
    super.key,
    required this.title,
    required this.child,
    this.backgroundColor,
    this.appBarBackgroundColor,
    this.leadingIconColor,
    this.titleColor,
    this.systemOverlayStyle,
    this.actions,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = gradient != null ||
        (backgroundColor != null && backgroundColor!.computeLuminance() < 0.5);

    final scaffold = Scaffold(
      backgroundColor: gradient != null
          ? Colors.transparent
          : (backgroundColor ?? Colors.white),
      appBar: AppBar(
        backgroundColor: gradient != null
            ? (appBarBackgroundColor ?? Colors.transparent)
            : (appBarBackgroundColor ?? (backgroundColor ?? Colors.white)),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: leadingIconColor ??
                (isDark ? Colors.white : const Color(0xFF000000)),
          ),
        ),
        actions: actions,
        systemOverlayStyle: systemOverlayStyle ??
            (isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark),
        centerTitle: true,
        title: Text(
          title,
          style: AppTypography.marcellus(
            color: titleColor ?? (isDark ? Colors.white : Colors.black),
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: child,
    );

    if (gradient != null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: gradient),
        child: scaffold,
      );
    }

    return scaffold;
  }
}
