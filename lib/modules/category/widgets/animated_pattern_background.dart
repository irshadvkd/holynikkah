import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A reusable animated background widget that shows a repeating pattern image
/// animated slowly in circles, a veil overlay, and a sweeping diagonal shimmer.
class AnimatedPatternBackground extends StatefulWidget {
  final String backgroundImage;
  final double scale;
  final BoxFit fit;
  final ImageRepeat repeat;
  final Color veilColor;
  final List<Color>? shimmerColors;
  final List<double> shimmerStops;
  final Duration animationDuration;
  final Duration? shimmerDuration;

  const AnimatedPatternBackground({
    super.key,
    required this.backgroundImage,
    this.scale = 1.0,
    this.fit = BoxFit.cover,
    this.repeat = ImageRepeat.noRepeat,
    required this.veilColor,
    this.shimmerColors,
    this.shimmerStops = const [0.4, 0.48, 0.50, 0.52, 0.60],
    this.animationDuration = const Duration(seconds: 40),
    this.shimmerDuration,
  });

  @override
  State<AnimatedPatternBackground> createState() =>
      _AnimatedPatternBackgroundState();
}

class _AnimatedPatternBackgroundState extends State<AnimatedPatternBackground>
    with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: widget.shimmerDuration ?? const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedPatternBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationDuration != widget.animationDuration) {
      _backgroundController.duration = widget.animationDuration;
      if (!_backgroundController.isAnimating) {
        _backgroundController.repeat();
      }
    }
    final effectiveShimmerDuration =
        widget.shimmerDuration ?? const Duration(seconds: 24);
    final oldEffectiveShimmerDuration =
        oldWidget.shimmerDuration ?? const Duration(seconds: 24);
    if (oldEffectiveShimmerDuration != effectiveShimmerDuration) {
      _shimmerController.duration = effectiveShimmerDuration;
      if (!_shimmerController.isAnimating) {
        _shimmerController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackgroundDecoration(),
        _buildBackgroundVeil(),
        _buildShimmerDecoration(),
      ],
    );
  }

  Widget _buildBackgroundDecoration() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        final double t = _backgroundController.value * 2 * math.pi;
        final double dx = math.sin(t) * 20.0;
        final double dy = -math.cos(t) * 20.0;

        return Positioned.fill(
          child: Opacity(
            opacity: 1,
            child: Transform.scale(
              scale: 1.15,
              child: Transform.translate(
                offset: Offset(dx, dy),
                child: Image.asset(
                  widget.backgroundImage,
                  repeat: widget.repeat,
                  alignment: widget.repeat == ImageRepeat.repeat
                      ? Alignment(math.sin(t) * 0.08, -math.sin(t) * 0.08)
                      : Alignment.center,
                  scale: widget.scale,
                  fit: widget.fit,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundVeil() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: widget.veilColor,
        ),
      ),
    );
  }

  Widget _buildShimmerDecoration() {
    final List<Color> colors = widget.shimmerColors ?? [
      Colors.transparent,
      Colors.white.withValues(alpha: 0.10),
      Colors.white.withValues(alpha: 0.18),
      Colors.white.withValues(alpha: 0.10),
      Colors.transparent,
    ];
    final Duration effectiveShimmerDuration =
        widget.shimmerDuration ?? const Duration(seconds: 24);

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final double t = _shimmerController.value * 2 * math.pi;
        final double totalSecs =
            effectiveShimmerDuration.inMilliseconds.toDouble() / 1000.0;
        final double time = _shimmerController.value * totalSecs;

        // Determine background diagonal direction from cosine derivative of sine alignment
        final bool movingLeftToRight = math.cos(t) >= 0;

        // Calculate tau: time elapsed since the start of the current direction phase (each phase is half the duration)
        final double tau;
        if (movingLeftToRight) {
          if (time >= totalSecs * 0.75) {
            tau = time - (totalSecs * 0.75);
          } else {
            tau = time + (totalSecs * 0.25);
          }
        } else {
          tau = time - (totalSecs * 0.25);
        }

        // Shimmer sweeps over the first 12.5% of the phase duration, then remains off-screen (p = 1.0)
        final double sweepDuration = totalSecs * 0.125;
        final double p = tau < sweepDuration ? tau / sweepDuration : 1.0;

        final double cx;
        final double cy;
        if (movingLeftToRight) {
          // Sweep from top-left to bottom-right
          cx = -1.5 + p * 3.0;
          cy = -1.5 + p * 3.0;
        } else {
          // Sweep from bottom-right to top-left
          cx = 1.5 - p * 3.0;
          cy = 1.5 - p * 3.0;
        }

        final begin = Alignment(cx - 0.5, cy - 0.5);
        final end = Alignment(cx + 0.5, cy + 0.5);

        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: begin,
                  end: end,
                  colors: colors,
                  stops: widget.shimmerStops,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
