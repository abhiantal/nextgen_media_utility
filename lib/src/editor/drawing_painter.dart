// ============================================================
// FILE: lib/media_utility/drawing_painter.dart
// Enhanced Drawing Painter with Smooth Curves - UPDATED
// ============================================================

import 'package:flutter/material.dart';
import '../core/media_asset_model.dart';

class MediaDrawingPainter extends CustomPainter {
  final List<DrawStroke> strokes;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double strokeWidth;
  final bool enableSmoothing;
  final double smoothingFactor;

  MediaDrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.strokeWidth,
    this.enableSmoothing = true,
    this.smoothingFactor = 0.3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, stroke.color, stroke.strokeWidth);
    }
    if (currentStroke.isNotEmpty) {
      _drawStroke(canvas, currentStroke, currentColor, strokeWidth);
    }
  }

  void _drawStroke(
    Canvas canvas,
    List<Offset> points,
    Color color,
    double width,
  ) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    if (_isLightColor(color)) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = width + 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..isAntiAlias = true;
      _drawPath(canvas, points, glowPaint);
    }

    _drawPath(canvas, points, paint);
  }

  void _drawPath(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) {
      if (points.isNotEmpty) {
        canvas.drawCircle(points[0], paint.strokeWidth / 2, paint);
      }
      return;
    }

    if (enableSmoothing && points.length > 2) {
      _drawSmoothPath(canvas, points, paint);
    } else {
      _drawSimplePath(canvas, points, paint);
    }
  }

  void _drawSimplePath(Canvas canvas, List<Offset> points, Paint paint) {
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawSmoothPath(Canvas canvas, List<Offset> points, Paint paint) {
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[0];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : p2;

      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) * smoothingFactor,
        p1.dy + (p2.dy - p0.dy) * smoothingFactor,
      );

      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) * smoothingFactor,
        p2.dy - (p3.dy - p1.dy) * smoothingFactor,
      );

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    canvas.drawPath(path, paint);
  }

  bool _isLightColor(Color color) {
    return color.computeLuminance() > 0.5;
  }

  @override
  bool shouldRepaint(covariant MediaDrawingPainter oldDelegate) => true;
}

enum DrawingMode { pen, highlighter, eraser, shape }

class DrawingOverlayController extends ChangeNotifier {
  final List<DrawStroke> _strokes = [];
  final List<Offset> _currentStroke = [];

  Color _currentColor = Colors.red;
  double _currentStrokeWidth = 3.0;
  DrawingMode _mode = DrawingMode.pen;

  List<DrawStroke> get strokes => List.unmodifiable(_strokes);
  List<Offset> get currentStroke => List.unmodifiable(_currentStroke);
  Color get currentColor => _currentColor;
  double get currentStrokeWidth => _currentStrokeWidth;
  DrawingMode get mode => _mode;

  bool get canUndo => _strokes.isNotEmpty;
  bool get isEmpty => _strokes.isEmpty && _currentStroke.isEmpty;

  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _currentStrokeWidth = width;
    notifyListeners();
  }

  void setMode(DrawingMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void startStroke(Offset point) {
    _currentStroke.add(point);
    notifyListeners();
  }

  void addPoint(Offset point) {
    _currentStroke.add(point);
    notifyListeners();
  }

  void endStroke() {
    if (_currentStroke.isNotEmpty) {
      _strokes.add(
        DrawStroke(
          points: List.from(_currentStroke),
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
        ),
      );
      _currentStroke.clear();
      notifyListeners();
    }
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      _strokes.removeLast();
      notifyListeners();
    }
  }

  void clear() {
    _strokes.clear();
    _currentStroke.clear();
    notifyListeners();
  }

  void loadStrokes(List<DrawStroke> strokes) {
    _strokes.clear();
    _strokes.addAll(strokes);
    notifyListeners();
  }
}
