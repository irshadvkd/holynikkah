import 'package:flutter/material.dart';

/// A production-ready gradient border container
/// matching complex CSS border-image + shadow + background gradient
class GradientBorderContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsets padding;
  final VoidCallback onTap;

  const GradientBorderContainer({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.borderWidth = 1,
    this.padding = const EdgeInsets.all(12),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),

          /// 🔹 Box Shadow
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000), // #00000040
              offset: Offset(0, 4),
              blurRadius: 4,
            ),
          ],

          /// 🔹 Gradient Border (outer)
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF000000),
              Color(0x33000000), // rgba(0,0,0,0.2)
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(borderWidth),
          child: Container(
            width: double.infinity,
            padding: padding,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius - borderWidth),

              /// 🔹 Background Gradient
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFFAC60C), Color(0xFF947507)],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
