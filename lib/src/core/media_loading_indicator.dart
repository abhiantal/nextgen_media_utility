// ============================================================
// FILE: lib/src/core/media_loading_indicator.dart
// NextGen Media Utility - Sleek Loading Indicator
// ============================================================

import 'dart:math';
import 'package:flutter/material.dart';

/// A sleek, modern loading indicator with a pulsing, glowing ring effect.
class FuturisticLoadingIndicator extends StatefulWidget {
  final double radius;
  final Color? color;
  final double strokeWidth;
  final double? value;
  final Color? backgroundColor;
  final Animation<Color?>? valueColor;
  final StrokeCap? strokeCap;

  const FuturisticLoadingIndicator({
    super.key,
    this.radius = 20.0,
    this.color,
    this.strokeWidth = 3.0,
    this.value,
    this.backgroundColor,
    this.valueColor,
    this.strokeCap,
  });

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
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor =
        widget.valueColor?.value ??
        widget.color ??
        Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.square(widget.radius * 2),
          painter: _FuturisticLoadingPainter(
            progress: _controller.value,
            color: themeColor,
            strokeWidth: widget.strokeWidth,
            backgroundColor: widget.backgroundColor ?? themeColor.withValues(alpha: 0.15),
            strokeCap: widget.strokeCap ?? StrokeCap.round,
          ),
        );
      },
    );
  }
}

class _FuturisticLoadingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final Color backgroundColor;
  final StrokeCap strokeCap;

  _FuturisticLoadingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.strokeCap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Rotating active arc
    final startAngle = progress * 2 * pi;
    final sweepAngle = pi * 0.75 + sin(progress * pi) * pi * 0.5;

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = strokeCap;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FuturisticLoadingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}

class FuturisticLinearLoadingIndicator extends StatelessWidget {
  final Color? backgroundColor;
  final Color? color;
  final double? value;
  final Animation<Color?>? valueColor;
  final double? minHeight;

  const FuturisticLinearLoadingIndicator({
    super.key,
    this.backgroundColor,
    this.color,
    this.value,
    this.valueColor,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      backgroundColor: backgroundColor,
      value: value,
      minHeight: minHeight,
      valueColor: valueColor ??
          AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

