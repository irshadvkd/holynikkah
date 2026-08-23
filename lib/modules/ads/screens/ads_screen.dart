import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'package:holynikkah/modules/ads/screens/common_ad_feed_screen.dart';

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  static final List<_OrbitItem> _orbitItems = [
    _OrbitItem(
      label: 'ANTIAGING',
      angleDeg: 272.5,
      title: 'Antiaging',
      feedUrl: AppConstants.urls.antiagingFeed,
      viewUrlPrefix: '/antiaging',
    ),
    _OrbitItem(
      label: 'REPLENISH EXCEPT\nHIS OWN',
      angleDeg: 307.5,
      title: 'Replenish Except His Own',
      feedUrl: AppConstants.urls.replenishFeed,
      viewUrlPrefix: '/replenish-except-his-own',
    ),
    _OrbitItem(
      label: 'AURA',
      angleDeg: 342.5,
      title: 'Aura',
      feedUrl: AppConstants.urls.auraFeed,
      viewUrlPrefix: '/aura',
    ),
    _OrbitItem(
      label: 'SHADI\nVIBES',
      angleDeg: 17.5,
      title: 'Shadi Vibes',
      feedUrl: AppConstants.urls.shadiVibesFeed,
      viewUrlPrefix: '/shadi-vibes',
    ),
    _OrbitItem(
      label: 'SPACE 4 ADVERTISEMENT',
      angleDeg: 52.5,
      title: 'Space Advertisement',
      feedUrl: AppConstants.urls.spaceAd1Feed,
      viewUrlPrefix: '/space-ad-1',
    ),
    _OrbitItem(
      label: 'SPACE 4 ADVERTISEMENT',
      angleDeg: 87.5,
      title: 'Space Advertisement',
      feedUrl: AppConstants.urls.spaceAd2Feed,
      viewUrlPrefix: '/space-ad-2',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 160),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomNavHeight = kBottomNavigationBarHeight;
    final usableHeight =
        size.height - bottomNavHeight - MediaQuery.of(context).padding.bottom;

    final center = Offset(60, usableHeight / 2);

    const double orbitRadiusX = 240;
    const double orbitRadiusY = 230;
    const double mainRadius = 230;
    const double smallRadius = 40;

    return Scaffold(
      body: Stack(
        alignment: Alignment.topLeft,
        children: [
          // 1. Base Background Image (combines radial gradient and Khatam pattern)
          Positioned.fill(
            child: Image.asset('assets/images/ads_bg1.png', fit: BoxFit.cover),
          ),

          // 3. Rotating Astrolabe Rim (Circle + 24 Ticks, spinning slowly)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _RotatingRimPainter(
                    center: center,
                    animationValue: _animationController.value,
                  ),
                );
              },
            ),
          ),

          // 4. Static Orbit Ring (Styled Gold/Brass)
          Positioned.fill(
            child: CustomPaint(
              painter: _OrbitPainter(
                center: center,
                radiusX: orbitRadiusX,
                radiusY: orbitRadiusY,
              ),
            ),
          ),

          // 6. Center Circle (Prayers - Background Image)
          Positioned(
            left: center.dx - mainRadius,
            top: center.dy - mainRadius,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommonAdFeedScreen(
                      title: 'Prayers',
                      feedUrl: AppConstants.urls.prayersFeed,
                      viewUrlBuilder: (id) => AppConstants.urls.prayersView(id),
                    ),
                  ),
                );
              },
              child: Image.asset(
                'assets/icons/ads/prayers.png',
                width: mainRadius * 2,
                height: mainRadius * 2,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 7. Prayers Text Overlay (Centered exactly on the circle)
          Positioned(
            left: center.dx - mainRadius + 30,
            top: center.dy - mainRadius,
            width: mainRadius * 2,
            height: mainRadius * 2,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommonAdFeedScreen(
                        title: 'Prayers',
                        feedUrl: AppConstants.urls.prayersFeed,
                        viewUrlBuilder: (id) => AppConstants.urls.prayersView(id),
                      ),
                    ),
                  );
                },
                child: Text(
                  'Prayers',
                  style: GoogleFonts.fraunces(
                    fontSize: 27,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF6EFE2), // Ivory text color
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),

          // 5. Orbit Items (Globes)
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommonAdFeedScreen(
                      title: item.title,
                      feedUrl: item.feedUrl,
                      viewUrlBuilder: (id) => "${item.viewUrlPrefix}/$id/views",
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _OrbitItem {
  final String label;
  final double angleDeg;
  final String title;
  final String feedUrl;
  final String viewUrlPrefix;

  const _OrbitItem({
    required this.label,
    required this.angleDeg,
    required this.title,
    required this.feedUrl,
    required this.viewUrlPrefix,
  });
}

class _OrbitGlobe extends StatelessWidget {
  final Offset center;
  final double radius;
  final String label;
  final double angleDeg;
  final int index;
  final VoidCallback onTap;

  const _OrbitGlobe({
    required this.center,
    required this.radius,
    required this.label,
    required this.angleDeg,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final angleRad = angleDeg * math.pi / 180;
    final dx = math.cos(angleRad);
    final dy = math.sin(angleRad);
    const double labelDistance = 14;

    return Stack(
      children: [
        // Dynamic HD rendered Globe Orb
        Positioned(
          left: center.dx - radius,
          top: center.dy - radius,
          child: GestureDetector(
            onTap: onTap,
            child: Image.asset(
              'assets/icons/ads/orbit.png',
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          left: index == 0
              ? center.dx + (radius + labelDistance) * dx - 55
              : index == 1
              ? center.dx + (radius + labelDistance) * dx - 85
              : index == 2
              ? center.dx + (radius + labelDistance) * dx - 45
              : index == 3
              ? center.dx + (radius + labelDistance) * dx - 40
              : index == 4
              ? center.dx + (radius + labelDistance) * dx - 85
              : index == 5
              ? center.dx + (radius + labelDistance) * dx - 55
              : center.dx + (radius + labelDistance) * dx,
          top: index == 0
              ? center.dy + (radius + labelDistance) * dy - 12
              : index == 1
              ? center.dy + (radius + labelDistance) * dy - 32
              : index == 2
              ? center.dy + (radius + labelDistance) * dy + 8
              : index == 3
              ? center.dy + (radius + labelDistance) * dy - 28
              : index == 4
              ? center.dy + (radius + labelDistance) * dy + 8
              : index == 5
              ? center.dy + (radius + labelDistance) * dy
              : center.dy + (radius + labelDistance) * dy,
          child: Transform.rotate(
            angle: _getReadableAngle(angleRad),
            child: GestureDetector(
              onTap: onTap,
              child: SizedBox(
                width: 110,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Color(0xFFF6EFE2), // Ivory readable color on dark bg
                    height: 1.3,
                  ),
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
        ..color = const Color(0xFFE7CE8C)
            .withValues(alpha: 0.35) // Gold soft color matching the theme
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8, // Reverted back to original
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.radiusX != radiusX ||
        oldDelegate.radiusY != radiusY;
  }
}

class _RotatingRimPainter extends CustomPainter {
  final Offset center;
  final double animationValue;

  const _RotatingRimPainter({
    required this.center,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animationValue * 2 * math.pi);

    const double rimRadius =
        175.0; // Positioned in between the center core (140) and outer globes (230/240)

    // 1. Astrolabe rim circle (radius 175)
    final limbPaint = Paint()
      ..color = const Color(0xFFE7CE8C)
          .withValues(alpha: 0.22) // stroke="rgba(231,206,140,0.22)"
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7; // Reverted back to original
    canvas.drawCircle(Offset.zero, rimRadius, limbPaint);

    // 2. 24 ticks around the circle
    final tickPaint = Paint()
      ..color = const Color(0xFFE7CE8C)
          .withValues(alpha: 0.5) // stroke="rgba(231,206,140,0.5)"
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0; // Reverted back to original
    final majorTickPaint = Paint()
      ..color = const Color(0xFFE7CE8C)
          .withValues(alpha: 0.75) // stroke="rgba(231,206,140,0.75)"
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3; // Reverted back to original

    for (int i = 0; i < 24; i++) {
      final double angle = i * (2 * math.pi / 24);
      final double cosA = math.cos(angle);
      final double sinA = math.sin(angle);

      final bool isMajor = (i % 6 == 0);
      final double tickLength = isMajor ? 13.0 : 8.0;
      final Paint currentPaint = isMajor ? majorTickPaint : tickPaint;

      final double startR = rimRadius;
      final double endR = rimRadius - tickLength;

      canvas.drawLine(
        Offset(startR * cosA, startR * sinA),
        Offset(endR * cosA, endR * sinA),
        currentPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RotatingRimPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.center != center;
  }
}
