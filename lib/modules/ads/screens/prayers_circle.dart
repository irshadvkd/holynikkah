import 'package:flutter/material.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/theme/app_typography.dart';

class PrayersCircle extends StatelessWidget {
  const PrayersCircle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 198,
      height: 198,
      decoration: BoxDecoration(
        shape: BoxShape.circle,

        // Equivalent to:
        // box-shadow:
        // 0 0 0 1px rgba(201,162,75,0.45),
        // 0 0 70px rgba(20,80,63,0.5),
        // inset 0 0 46px rgba(0,0,0,0.4);
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(201, 162, 75, 0.45),
            blurRadius: 0,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Color.fromRGBO(20, 80, 63, 0.5),
            blurRadius: 70,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.4),
            blurRadius: 46,
            spreadRadius: -8,
          ),
        ],

        // CSS radial gradients
        gradient: const RadialGradient(
          center: Alignment(0.32, 0.44),
          radius: 0.85,
          colors: [
            Color(0x80231F8C), // highlight approximation
            Color(0x00231F8C),
          ],
          stops: [0.0, 0.45],
        ),
      ),

      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment(0.32, 0.44),
            radius: 1.0,
            colors: [Color(0xFF2C7A61), Color(0xFF14503F), Color(0xFF1B0509)],
            stops: [0.0, 0.48, 1.0],
          ),
        ),
        child: Center(
          child: Text(
            'Prayers',
            textAlign: TextAlign.center,
            style: AppTypography.marcellus(
              fontWeight: FontWeight.w600,
              fontSize: 23,
              letterSpacing: 0.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
