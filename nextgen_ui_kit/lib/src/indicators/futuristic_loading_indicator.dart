import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Visual style variations for [FuturisticLoadingIndicator].
enum FuturisticLoadingStyle {
  /// Dual counter-rotating neon rings with gap arcs and outer glow.
  dualRings,

  /// Futuristic cyber orbital rings with rotating satellite nodes.
  cyberOrbit,

  /// Breathing core with pulsating outer halo.
  pulsingCore,

  /// Sweeping radar / HUD scanner ring.
  radarScanner,
}

/// A sleek, modern, futuristic loading indicator featuring customizable
/// neon glows, orbital particles, and multi-axis rotation effects.
class FuturisticLoadingIndicator extends StatefulWidget {
  /// The radius of the indicator. Defaults to 24.0.
  final double radius;

  /// Optional outer size diameter override. If provided, overrides [radius].
  final double? size;

  /// Primary neon accent color. Defaults to theme primary or cyan accent.
  final Color? color;

  /// Secondary complementary accent color for dual-tone gradient rings.
  final Color? secondaryColor;

  /// Background ring track color. If null, track is subtle or transparent.
  final Color? backgroundColor;

  /// Width of the glowing stroke. Defaults to 3.5.
  final double strokeWidth;

  /// Determinate progress value from 0.0 to 1.0. If null, runs indeterminate animation.
  final double? value;

  /// Animation value color interpolation.
  final Animation<Color?>? valueColor;

  /// Stroke cap styling for arcs. Defaults to [StrokeCap.round].
  final StrokeCap strokeCap;

  /// Visual style preset for the futuristic loader. Defaults to [FuturisticLoadingStyle.dualRings].
  final FuturisticLoadingStyle style;

  /// Glow intensity blur radius. Defaults to 6.0. Set to 0 to disable glow.
  final double glowRadius;

  /// Duration for one complete animation revolution. Defaults to 1500ms.
  final Duration duration;

  const FuturisticLoadingIndicator({
    super.key,
    this.radius = 24.0,
    this.size,
    this.color,
    this.secondaryColor,
    this.backgroundColor,
    this.strokeWidth = 3.5,
    this.value,
    this.valueColor,
    this.strokeCap = StrokeCap.round,
    this.style = FuturisticLoadingStyle.dualRings,
    this.glowRadius = 6.0,
    this.duration = const Duration(milliseconds: 1500),
  });

  /// Factory preset for dual counter-rotating neon cyber rings.
  factory FuturisticLoadingIndicator.dualRings({
    Key? key,
    double radius = 24.0,
    double? size,
    Color? color,
    Color? secondaryColor,
    Color? backgroundColor,
    double strokeWidth = 3.5,
    double glowRadius = 6.0,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return FuturisticLoadingIndicator(
      key: key,
      radius: radius,
      size: size,
      color: color,
      secondaryColor: secondaryColor,
      backgroundColor: backgroundColor,
      strokeWidth: strokeWidth,
      glowRadius: glowRadius,
      style: FuturisticLoadingStyle.dualRings,
      duration: duration,
    );
  }

  /// Factory preset for cyber orbital particles.
  factory FuturisticLoadingIndicator.cyberOrbit({
    Key? key,
    double radius = 24.0,
    double? size,
    Color? color,
    Color? secondaryColor,
    double strokeWidth = 3.0,
    double glowRadius = 7.0,
    Duration duration = const Duration(milliseconds: 1800),
  }) {
    return FuturisticLoadingIndicator(
      key: key,
      radius: radius,
      size: size,
      color: color,
      secondaryColor: secondaryColor,
      strokeWidth: strokeWidth,
      glowRadius: glowRadius,
      style: FuturisticLoadingStyle.cyberOrbit,
      duration: duration,
    );
  }

  /// Factory preset for a pulsing energy core.
  factory FuturisticLoadingIndicator.pulsingCore({
    Key? key,
    double radius = 24.0,
    double? size,
    Color? color,
    Color? secondaryColor,
    double glowRadius = 8.0,
    Duration duration = const Duration(milliseconds: 1200),
  }) {
    return FuturisticLoadingIndicator(
      key: key,
      radius: radius,
      size: size,
      color: color,
      secondaryColor: secondaryColor,
      glowRadius: glowRadius,
      style: FuturisticLoadingStyle.pulsingCore,
      duration: duration,
    );
  }

  /// Factory preset for a sweeping radar HUD scanner.
  factory FuturisticLoadingIndicator.radarScanner({
    Key? key,
    double radius = 24.0,
    double? size,
    Color? color,
    double strokeWidth = 2.5,
    Duration duration = const Duration(milliseconds: 1600),
  }) {
    return FuturisticLoadingIndicator(
      key: key,
      radius: radius,
      size: size,
      color: color,
      strokeWidth: strokeWidth,
      style: FuturisticLoadingStyle.radarScanner,
      duration: duration,
    );
  }

  @override
  State<FuturisticLoadingIndicator> createState() =>
      _FuturisticLoadingIndicatorState();
}

class _FuturisticLoadingIndicatorState extends State<FuturisticLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant FuturisticLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.valueColor?.value ??
        widget.color ??
        theme.colorScheme.primary;
    final secondaryColor = widget.secondaryColor ??
        (widget.color != null
            ? widget.color!.withValues(alpha: 0.7)
            : theme.colorScheme.tertiary);

    final effectiveRadius =
        widget.size != null ? widget.size! / 2 : widget.radius;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.square(effectiveRadius * 2),
          painter: _FuturisticPainter(
            progress: _controller.value,
            value: widget.value,
            color: primaryColor,
            secondaryColor: secondaryColor,
            backgroundColor: widget.backgroundColor,
            strokeWidth: widget.strokeWidth,
            strokeCap: widget.strokeCap,
            style: widget.style,
            glowRadius: widget.glowRadius,
          ),
        );
      },
    );
  }
}

class _FuturisticPainter extends CustomPainter {
  final double progress;
  final double? value;
  final Color color;
  final Color secondaryColor;
  final Color? backgroundColor;
  final double strokeWidth;
  final StrokeCap strokeCap;
  final FuturisticLoadingStyle style;
  final double glowRadius;

  _FuturisticPainter({
    required this.progress,
    this.value,
    required this.color,
    required this.secondaryColor,
    this.backgroundColor,
    required this.strokeWidth,
    required this.strokeCap,
    required this.style,
    required this.glowRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    if (radius <= 0) return;

    // Optional background circle
    if (backgroundColor != null) {
      final bgPaint = Paint()
        ..color = backgroundColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, bgPaint);
    }

    // Determinate Mode
    if (value != null) {
      _paintDeterminate(canvas, center, radius);
      return;
    }

    // Indeterminate Modes by Style
    switch (style) {
      case FuturisticLoadingStyle.dualRings:
        _paintDualRings(canvas, center, radius);
        break;
      case FuturisticLoadingStyle.cyberOrbit:
        _paintCyberOrbit(canvas, center, radius);
        break;
      case FuturisticLoadingStyle.pulsingCore:
        _paintPulsingCore(canvas, center, radius);
        break;
      case FuturisticLoadingStyle.radarScanner:
        _paintRadarScanner(canvas, center, radius);
        break;
    }
  }

  void _paintDeterminate(Canvas canvas, Offset center, double radius) {
    final sweepAngle = 2 * math.pi * value!.clamp(0.0, 1.0);

    if (glowRadius > 0) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.8
        ..strokeCap = strokeCap
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        glowPaint,
      );
    }

    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = strokeCap;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      ringPaint,
    );
  }

  void _paintDualRings(Canvas canvas, Offset center, double radius) {
    // Outer breathing halo
    if (glowRadius > 0) {
      final pulse = 0.25 + 0.25 * math.sin(progress * 2 * math.pi);
      final glowPaint = Paint()
        ..color = color.withValues(alpha: pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 2.0
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);
      canvas.drawCircle(center, radius, glowPaint);
    }

    // Outer primary ring arc (rotates forward)
    final outerRing = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = strokeCap;

    final startAngle1 = progress * 2 * math.pi;
    const sweepAngle1 = math.pi * 1.35;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle1,
      sweepAngle1,
      false,
      outerRing,
    );

    // Inner secondary ring arc (rotates counter-clockwise)
    final innerRadius = radius * 0.68;
    final innerRing = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.75
      ..strokeCap = strokeCap;

    final startAngle2 = -progress * 2 * math.pi;
    const sweepAngle2 = math.pi * 1.1;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle2,
      sweepAngle2,
      false,
      innerRing,
    );
  }

  void _paintCyberOrbit(Canvas canvas, Offset center, double radius) {
    // Base track circle
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, trackPaint);

    // Rotating orbit arc
    final orbitAngle = progress * 2 * math.pi;
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = strokeCap;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      orbitAngle,
      math.pi * 0.75,
      false,
      arcPaint,
    );

    // Satellite particle 1
    final p1Angle = orbitAngle + math.pi * 0.75;
    final p1X = center.dx + radius * math.cos(p1Angle);
    final p1Y = center.dy + radius * math.sin(p1Angle);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(p1X, p1Y), strokeWidth * 0.8, dotPaint);

    if (glowRadius > 0) {
      final dotGlow = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);
      canvas.drawCircle(Offset(p1X, p1Y), strokeWidth * 1.2, dotGlow);
    }

    // Inner counter-satellite particle
    final p2Angle = -orbitAngle * 1.4;
    final innerR = radius * 0.55;
    final p2X = center.dx + innerR * math.cos(p2Angle);
    final p2Y = center.dy + innerR * math.sin(p2Angle);

    final innerDot = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(p2X, p2Y), strokeWidth * 0.65, innerDot);
  }

  void _paintPulsingCore(Canvas canvas, Offset center, double radius) {
    final pulseScale = 0.4 + 0.45 * math.sin(progress * 2 * math.pi).abs();

    // Outer aura
    if (glowRadius > 0) {
      final auraPaint = Paint()
        ..color = color.withValues(alpha: 0.35 * (1.0 - pulseScale * 0.5))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius * 1.5);
      canvas.drawCircle(center, radius * (0.6 + pulseScale * 0.4), auraPaint);
    }

    // Middle halo ring
    final haloPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.6;
    canvas.drawCircle(center, radius * (0.4 + pulseScale * 0.3), haloPaint);

    // Inner bright core
    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.35, corePaint);

    // Center white spark
    final sparkPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.15, sparkPaint);
  }

  void _paintRadarScanner(Canvas canvas, Offset center, double radius) {
    // Outer border ring
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);

    // Sweeping gradient beam
    final startAngle = progress * 2 * math.pi;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final sweepGradient = SweepGradient(
      startAngle: startAngle - math.pi * 0.5,
      endAngle: startAngle,
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.4),
      ],
      stops: const [0.0, 1.0],
    );

    final scanPaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawArc(rect, startAngle - math.pi * 0.5, math.pi * 0.5, true, scanPaint);

    // Scanner lead line
    final lineX = center.dx + radius * math.cos(startAngle);
    final lineY = center.dy + radius * math.sin(startAngle);
    final leadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;
    canvas.drawLine(center, Offset(lineX, lineY), leadPaint);
  }

  @override
  bool shouldRepaint(covariant _FuturisticPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.value != value ||
        oldDelegate.style != style;
  }
}

/// A modern, futuristic linear loading indicator with a pulsing glow effect.
class FuturisticLinearLoadingIndicator extends StatefulWidget {
  /// Determinate progress from 0.0 to 1.0. If null, displays an animated indeterminate laser sweep.
  final double? value;

  /// Primary bar accent color.
  final Color? color;

  /// Background track color.
  final Color? backgroundColor;

  /// Height of the bar. Defaults to 4.0.
  final double minHeight;

  /// Border radius for the bar track. Defaults to pill shape.
  final BorderRadiusGeometry? borderRadius;

  /// Color animation interpolation.
  final Animation<Color?>? valueColor;

  /// Optional gradient for the active progress bar.
  final Gradient? gradient;

  /// Glow blur intensity. Defaults to 4.0.
  final double glowRadius;

  /// Duration of one laser sweep. Defaults to 1800ms.
  final Duration duration;

  const FuturisticLinearLoadingIndicator({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
    this.minHeight = 4.0,
    this.borderRadius,
    this.valueColor,
    this.gradient,
    this.glowRadius = 4.0,
    this.duration = const Duration(milliseconds: 1800),
  });

  @override
  State<FuturisticLinearLoadingIndicator> createState() =>
      _FuturisticLinearLoadingIndicatorState();
}

class _FuturisticLinearLoadingIndicatorState
    extends State<FuturisticLinearLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant FuturisticLinearLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeColor = widget.valueColor?.value ??
        widget.color ??
        theme.colorScheme.primary;
    final bgColor = widget.backgroundColor ?? themeColor.withValues(alpha: 0.15);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.minHeight),
          painter: _GlowingBarPainter(
            progress: _controller.value,
            value: widget.value,
            color: themeColor,
            backgroundColor: bgColor,
            height: widget.minHeight,
            borderRadius: widget.borderRadius,
            gradient: widget.gradient,
            glowRadius: widget.glowRadius,
          ),
        );
      },
    );
  }
}

class _GlowingBarPainter extends CustomPainter {
  final double progress;
  final double? value;
  final Color color;
  final Color backgroundColor;
  final double height;
  final BorderRadiusGeometry? borderRadius;
  final Gradient? gradient;
  final double glowRadius;

  _GlowingBarPainter({
    required this.progress,
    this.value,
    required this.color,
    required this.backgroundColor,
    required this.height,
    this.borderRadius,
    this.gradient,
    required this.glowRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgRadius = borderRadius?.resolve(TextDirection.ltr).topLeft ??
        Radius.circular(height / 2);
    final bgRRect = RRect.fromRectAndRadius(rect, bgRadius);

    // Track
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRRect(bgRRect, bgPaint);

    if (value != null) {
      final filledWidth = size.width * value!.clamp(0.0, 1.0);
      final fillRect = Rect.fromLTWH(0, 0, filledWidth, size.height);
      final fillRRect = RRect.fromRectAndRadius(fillRect, bgRadius);

      final fillPaint = Paint();
      if (gradient != null) {
        fillPaint.shader = gradient!.createShader(fillRect);
      } else {
        fillPaint.color = color;
      }

      if (glowRadius > 0) {
        fillPaint.maskFilter = MaskFilter.blur(BlurStyle.solid, glowRadius);
      }

      canvas.drawRRect(fillRRect, fillPaint);
    } else {
      final startX = size.width * (progress * 2 - 1);
      final barWidth = size.width * 0.45;
      final fillRect = Rect.fromLTWH(startX, 0, barWidth, size.height);

      canvas.save();
      canvas.clipRRect(bgRRect);

      final effGradient = gradient ??
          LinearGradient(
            colors: [
              color.withValues(alpha: 0.0),
              color,
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
          );

      final fillPaint = Paint()
        ..shader = effGradient.createShader(fillRect);

      if (glowRadius > 0) {
        fillPaint.maskFilter = MaskFilter.blur(BlurStyle.solid, glowRadius);
      }

      canvas.drawRect(fillRect, fillPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _GlowingBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.gradient != gradient;
  }
}
