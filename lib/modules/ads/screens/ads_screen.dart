import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ads Screen with global scaling
/// Keeps UI proportions exactly same while enlarging visually
class AdsScreen extends StatelessWidget {
  const AdsScreen({super.key});

  /// Global scale factor
  /// Change this to enlarge or shrink UI
  static const double uiScale = 1.2; // 👈 Increase this (1.1 → 1.5)

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Transform.scale(
          scale: uiScale,
          alignment: Alignment.center,
          child: OverflowBox(
            maxWidth: double.infinity,
            child: Transform.translate(
              offset: Offset(-screenSize.width * 0.35, 0),
              child: SizedBox(
                width: screenSize.width * 1.5,
                height: screenSize.width * 1.2,
                child: _buildCircleUI(screenSize),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Main UI Builder (Separated for Clean Code)
  Widget _buildCircleUI(Size screenSize) {
    return Stack(
      alignment: Alignment.center,
      children: [
        /// Outer Ring
        SizedBox(
          width: screenSize.width * 1,
          height: screenSize.width * 1.2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              /// Outer Border Circle
              Container(
                width: screenSize.width * 0.8,
                height: screenSize.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[400]!, width: 3),
                ),
              ),

              /// Orbit Items
              ..._buildOrbitItems(screenSize),
            ],
          ),
        ),

        /// Inner Circle
        Container(
          width: screenSize.width * 0.5,
          height: screenSize.width * 0.5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[400]!,
            boxShadow: [
              /// Matches: 0px 4px 100px 67px #00000099 inset
              BoxShadow(
                offset: const Offset(0, 4),
                blurRadius: 100,
                spreadRadius: 67,
                color: const Color(0x99000000),
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'PRAYERS',
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Orbit Items Generator
  List<Widget> _buildOrbitItems(Size screenSize) {
    final labels = [
      'ANTIAGING',
      'GLOWTIPS',
      'AURA',
      'REPLENISH EXCEPT HIS OWN',
      'SPACE 4 AD',
      'SPACE 4 AD',
    ];

    return List.generate(6, (index) {
      final angle = (270 + index * 35) * math.pi / 180;
      final radius = screenSize.width * 0.4;

      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;

      return Positioned(
        left: screenSize.width / 2 + x - 30,
        top: screenSize.width * 0.6 + y - 30,
        child: Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            shape: BoxShape.circle,
          ),
          child: Text(
            labels[index],
            style: GoogleFonts.inter(fontSize: 10, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    });
  }
}
