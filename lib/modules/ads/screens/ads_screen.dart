import 'dart:math' as math;
import 'package:flutter/material.dart';

class AdsScreen extends StatelessWidget {
  const AdsScreen({super.key});

  static const List<_OrbitItem> _orbitItems = [
    _OrbitItem(label: 'REPLENISH EXCEPT\nHIS OWN', angleDeg: 310),
    _OrbitItem(label: 'AURA', angleDeg: 345),
    _OrbitItem(label: 'SHAADI VIBES', angleDeg: 20),
    _OrbitItem(label: 'SPACE 4 ADVERTISEMENT', angleDeg: 55),
    _OrbitItem(label: 'SPACE 4 ADVERTISEMENT', angleDeg: 89),
    _OrbitItem(label: 'ANTIAGING', angleDeg: 275),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final center = Offset(60, size.height / 2);

    const double orbitRadiusX = 200;
    const double orbitRadiusY = 190;
    const double mainRadius = 140;
    const double smallRadius = 32;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.topLeft,
        children: [
          /// ── Orbit ring ─────────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _OrbitPainter(
                center: center,
                radiusX: orbitRadiusX,
                radiusY: orbitRadiusY,
              ),
            ),
          ),

          /// ── Orbit Items ────────────────────────────
          ..._orbitItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final angle = item.angleDeg * math.pi / 180;

            final globeCenter =
                center +
                Offset(
                  orbitRadiusX * math.cos(angle),
                  orbitRadiusY * math.sin(angle),
                );

            return _OrbitGlobe(
              center: globeCenter,
              radius: smallRadius,
              label: item.label,
              angleDeg: item.angleDeg,
              index: index,
            );
          }),

          /// ── Center Image ───────────────────────────
          Positioned(
            left: center.dx - mainRadius,
            top: center.dy - mainRadius,
            child: Image.asset(
              'assets/icons/ads/prayers.png',
              width: mainRadius * 2,
              height: mainRadius * 2,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────

class _OrbitItem {
  final String label;
  final double angleDeg;

  const _OrbitItem({required this.label, required this.angleDeg});
}

/// ─────────────────────────────────────────────

class _OrbitGlobe extends StatelessWidget {
  final Offset center;
  final double radius;
  final String label;
  final double angleDeg;
  final int index;

  const _OrbitGlobe({
    required this.center,
    required this.radius,
    required this.label,
    required this.angleDeg,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final angleRad = angleDeg * math.pi / 180;

    /// Direction vector
    final dx = math.cos(angleRad);
    final dy = math.sin(angleRad);

    /// Distance of label from globe
    const double labelDistance = 14;

    /// Smart alignment
    TextAlign textAlign;
    if (dx > 0.3) {
      textAlign = TextAlign.left;
    } else if (dx < -0.3) {
      textAlign = TextAlign.right;
    } else {
      textAlign = TextAlign.center;
    }

    return Stack(
      children: [
        /// Globe
        Positioned(
          left: center.dx - radius,
          top: center.dy - radius,
          child: Image.asset(
            'assets/icons/ads/globe1.png',
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.contain,
          ),
        ),

        /// Label (🔥 FIXED POSITION)
        /// Label (🔥 Rotated along orbit)
        Positioned(
          left:
              center.dx +
              (radius + labelDistance) * dx -
              (index == 1
                  ? 45
                  : index == 2
                  ? 25
                  : 30),
          top: center.dy + (radius + labelDistance) * dy - 12,
          child: Transform.rotate(
            angle: _getReadableAngle(angleRad),
            child: SizedBox(
              width: 110,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _getReadableAngle(double angle) {
    double rotation = angle + math.pi / 2;

    /// Prevent upside-down text
    if (rotation > math.pi / 2 && rotation < 3 * math.pi / 2) {
      rotation += math.pi;
    }

    return 0;
  }
}

/// ─────────────────────────────────────────────

class _OrbitPainter extends CustomPainter {
  final Offset center;
  final double radiusX;
  final double radiusY;

  const _OrbitPainter({
    required this.center,
    required this.radiusX,
    required this.radiusY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radiusX * 2, height: radiusY * 2),
      Paint()
        ..color = const Color(0xFF2A5FA0).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.radiusX != radiusX ||
        oldDelegate.radiusY != radiusY;
  }
}
