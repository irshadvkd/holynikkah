import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
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
      label: 'REPLENISH\nEXCEPT HIS OWN',
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
      label: 'SHAADI\nVIBES',
      angleDeg: 17.5,
      title: 'Shadi Vibes',
      feedUrl: AppConstants.urls.shadiVibesFeed,
      viewUrlPrefix: '/shadi-vibes',
    ),
    _OrbitItem(
      label: 'SPACE 4\nADVERTISEMENT',
      angleDeg: 52.5,
      title: 'Space Advertisement',
      feedUrl: AppConstants.urls.spaceAd1Feed,
      viewUrlPrefix: '/advertisement1',
    ),
    _OrbitItem(
      label: 'SPACE 4\nADVERTISEMENT',
      angleDeg: 87.5,
      title: 'Space Advertisement',
      feedUrl: AppConstants.urls.spaceAd2Feed,
      viewUrlPrefix: '/advertisement2',
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
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          // Responsive scale factor based on reference screen size (390 x 720)
          final scaleX = width / 390.0;
          final scaleY = height / 720.0;
          final scale = math.min(scaleX, scaleY).clamp(0.65, 2.5);

          final centerX = 58.5 * scale;
          final centerY = height / 2;
          final center = Offset(centerX, centerY);

          final double orbitRadiusX = 240.0 * scale;
          final double orbitRadiusY = 230.0 * scale;
          final double mainRadius = 230.0 * scale;
          final double smallRadius = 40.0 * scale;
          final double rimRadius = 175.0 * scale;

          return Stack(
            alignment: Alignment.topLeft,
            children: [
              // 1. Base Background Image (combines radial gradient and Khatam pattern)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/ads_bg.png',
                  fit: BoxFit.cover,
                ),
              ),

              // 3. Rotating Astrolabe Rim (Circle + 24 Ticks, spinning slowly)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _RotatingRimPainter(
                        center: center,
                        rimRadius: rimRadius,
                        animationValue: _animationController.value,
                        scale: scale,
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
                    scale: scale,
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
                          viewUrlBuilder: (id) =>
                              AppConstants.urls.prayersView(id),
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

              // 7. Prayers Text Overlay (Centered on the circle)
              Positioned(
                left: center.dx - mainRadius + (30 * scale),
                top: center.dy - mainRadius - (4 * scale),
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
                            viewUrlBuilder: (id) =>
                                AppConstants.urls.prayersView(id),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Prayers',
                      style: AppTypography.cormorantGaramond(
                        fontSize: (30 * scale).clamp(18.0, 56.0),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
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
                  scale: scale,
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
                          viewUrlBuilder: (id) =>
                              "${item.viewUrlPrefix}/$id/views",
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          );
        },
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
  final double scale;
  final String label;
  final double angleDeg;
  final int index;
  final VoidCallback onTap;

  const _OrbitGlobe({
    required this.center,
    required this.radius,
    required this.scale,
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
    final double labelDistance = 14 * scale;
    final double labelWidth = 135 * scale;
    final double fontSize = (11.5 * scale).clamp(9.0, 22.0);

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
              ? center.dx + (radius + labelDistance) * dx - (65 * scale)
              : index == 1
              ? center.dx + (radius + labelDistance) * dx - (95 * scale)
              : index == 2
              ? center.dx + (radius + labelDistance) * dx - (45 * scale)
              : index == 3
              ? center.dx + (radius + labelDistance) * dx - (45 * scale)
              : index == 4
              ? center.dx + (radius + labelDistance) * dx - (95 * scale)
              : index == 5
              ? center.dx + (radius + labelDistance) * dx - (65 * scale)
              : center.dx + (radius + labelDistance) * dx,
          top: index == 0
              ? center.dy + (radius + labelDistance) * dy - (12 * scale)
              : index == 1
              ? center.dy + (radius + labelDistance) * dy - (36 * scale)
              : index == 2
              ? center.dy + (radius + labelDistance) * dy + (8 * scale)
              : index == 3
              ? center.dy + (radius + labelDistance) * dy - (28 * scale)
              : index == 4
              ? center.dy + (radius + labelDistance) * dy + (8 * scale)
              : index == 5
              ? center.dy + (radius + labelDistance) * dy
              : center.dy + (radius + labelDistance) * dy,
          child: Transform.rotate(
            angle: _getReadableAngle(angleRad),
            child: GestureDetector(
              onTap: onTap,
              child: SizedBox(
                width: labelWidth,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTypography.marcellus(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.textPrimary,
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
  final double scale;

  const _OrbitPainter({
    required this.center,
    required this.radiusX,
    required this.radiusY,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radiusX * 2, height: radiusY * 2),
      Paint()
        ..color = AppColors.primary
            .withValues(alpha: 0.35) // Gold soft color matching the theme
        ..style = PaintingStyle.stroke
        ..strokeWidth = (0.8 * scale).clamp(0.8, 2.0),
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.radiusX != radiusX ||
        oldDelegate.radiusY != radiusY ||
        oldDelegate.scale != scale;
  }
}

class _RotatingRimPainter extends CustomPainter {
  final Offset center;
  final double rimRadius;
  final double animationValue;
  final double scale;

  const _RotatingRimPainter({
    required this.center,
    required this.rimRadius,
    required this.animationValue,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animationValue * 2 * math.pi);

    // 1. Astrolabe rim circle
    final limbPaint = Paint()
      ..color = AppColors.primary
          .withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (0.7 * scale).clamp(0.7, 1.8);
    canvas.drawCircle(Offset.zero, rimRadius, limbPaint);

    // 2. 24 ticks around the circle
    final tickPaint = Paint()
      ..color = AppColors.primary
          .withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (1.0 * scale).clamp(1.0, 2.2);
    final majorTickPaint = Paint()
      ..color = AppColors.primary
          .withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (1.3 * scale).clamp(1.3, 2.8);

    for (int i = 0; i < 24; i++) {
      final double angle = i * (2 * math.pi / 24);
      final double cosA = math.cos(angle);
      final double sinA = math.sin(angle);

      final bool isMajor = (i % 6 == 0);
      final double tickLength = (isMajor ? 13.0 : 8.0) * scale;
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
        oldDelegate.center != center ||
        oldDelegate.rimRadius != rimRadius ||
        oldDelegate.scale != scale;
  }
}
