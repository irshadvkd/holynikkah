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
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.white,
      appBar: AppBar(
        backgroundColor: appBarBackgroundColor ?? (backgroundColor ?? Colors.white),
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: leadingIconColor ?? const Color(0xFF000000),
          ),
        ),
        actions: actions,
        systemOverlayStyle: systemOverlayStyle ??
            ((backgroundColor != null && backgroundColor!.computeLuminance() < 0.5)
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark),
        centerTitle: true,
        title: Text(
          title,
          style: AppTypography.marcellus(
            color: titleColor ?? Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: child,
    );
  }
}
