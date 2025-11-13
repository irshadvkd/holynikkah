import 'package:flutter/material.dart';
import 'package:holynikkah/core/utils/constants.dart';

/// App logo widget for Splash and Auth screens
class LogoWidget extends StatelessWidget {
  final double size;
  const LogoWidget({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppConstants.icons.appLogoDark,
      width: size,
      height: size,
    );
  }
}
