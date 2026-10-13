import 'package:flutter/material.dart';

// --- ENUMS (No changes here) ---
enum ProgressOrientation { horizontal, vertical }

enum LabelPosition { top, bottom, left, right, center }

enum ProgressLabelDisplay { none, box, bubble }

// --- WIDGET ---
class CustomProgressIndicator extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final ProgressOrientation orientation;
  final double width; // Base width for vertical, fixed width for horizontal
  final double
  baseHeight; // Base height for horizontal, fixed height for vertical
  final double maxHeightIncrease; // Growth dimension
  final Color backgroundColor;
  final Color progressColor;
  final List<Color>? gradientColors;
  final double borderRadius;
  final LabelPosition nameLabelPosition;

  // Progress Label Properties
  final String? customProgressLabel;
  final ProgressLabelDisplay progressLabelDisplay;
  final Color progressLabelBackgroundColor;
  final TextStyle? progressLabelStyle;
  final EdgeInsetsGeometry progressLabelPadding;
  final double progressLabelSpacing; // Space between bar and label
  final bool animateProgressLabel;
  final Duration progressLabelAnimationDuration;
  final Curve progressLabelAnimationCurve;

  // Name Label Properties
  final String progressBarName;
  final TextStyle? nameLabelStyle;
  final EdgeInsetsGeometry nameLabelPadding;
  final bool animateNameLabel;
  final Duration nameLabelAnimationDuration;
  final Curve nameLabelAnimationCurve;
  final double labelSpacing;

  // General Animation & Styling
  final bool animated;
  final Duration animationDuration;
  final Curve animationCurve;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const CustomProgressIndicator({
    super.key,
    required this.progress,
    this.orientation = ProgressOrientation.horizontal,
    this.width = 250,
    this.baseHeight = 20,
    this.maxHeightIncrease = 15,
    this.backgroundColor = Colors.grey,
    this.progressColor = Colors.blue,
    this.gradientColors,
    this.borderRadius = 10,
    this.nameLabelPosition = LabelPosition.bottom,
    this.customProgressLabel,
    this.progressLabelDisplay = ProgressLabelDisplay.box,
    this.progressLabelBackgroundColor = Colors.blueAccent,
    this.progressLabelStyle,
    this.progressLabelPadding = const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ),
    this.progressLabelSpacing = 6.0,
    this.animateProgressLabel = true,
    this.progressLabelAnimationDuration = const Duration(milliseconds: 500),
    this.progressLabelAnimationCurve = Curves.easeInOut,
    this.progressBarName = '',
    this.nameLabelStyle,
    this.nameLabelPadding = const EdgeInsets.all(6),
    this.animateNameLabel = true,
    this.nameLabelAnimationDuration = const Duration(milliseconds: 800),
    this.nameLabelAnimationCurve = Curves.elasticOut,
    this.labelSpacing = 4,
    this.animated = true,
    this.animationDuration = const Duration(milliseconds: 800),
    this.animationCurve = Curves.easeInOut,
    this.borderColor,
    this.borderWidth = 1,
    this.padding,
    this.margin,
  });

  @override
  State<CustomProgressIndicator> createState() =>
      _CustomProgressIndicatorState();
}

class _CustomProgressIndicatorState extends State<CustomProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _progressAnimationController;
  late AnimationController _progressLabelAnimationController;
  late AnimationController _nameLabelAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _progressLabelAnimation;
  late Animation<double> _nameLabelAnimation;

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: widget.progress)
        .animate(
          CurvedAnimation(
            parent: _progressAnimationController,
            curve: widget.animationCurve,
          ),
        );
    _progressLabelAnimationController = AnimationController(
      duration: widget.progressLabelAnimationDuration,
      vsync: this,
    );
    _progressLabelAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressLabelAnimationController,
        curve: widget.progressLabelAnimationCurve,
      ),
    );
    _nameLabelAnimationController = AnimationController(
      duration: widget.nameLabelAnimationDuration,
      vsync: this,
    );
    _nameLabelAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _nameLabelAnimationController,
        curve: widget.nameLabelAnimationCurve,
      ),
    );
    if (widget.animated) _progressAnimationController.forward();
    if (widget.animateProgressLabel) {
      _progressLabelAnimationController.forward();
    }
    if (widget.animateNameLabel) _nameLabelAnimationController.forward();
  }

  @override
  void didUpdateWidget(CustomProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: widget.progress,
          ).animate(
            CurvedAnimation(
              parent: _progressAnimationController,
              curve: widget.animationCurve,
            ),
          );
      if (widget.animated) {
        _progressAnimationController
          ..reset()
          ..forward();
      }
      if (widget.animateProgressLabel) {
        _progressLabelAnimationController
          ..reset()
          ..forward();
      }
    }
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _progressLabelAnimationController.dispose();
    _nameLabelAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          margin: widget.margin,
          padding: widget.padding,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _progressAnimation,
              _progressLabelAnimation,
              _nameLabelAnimation,
            ]),
            builder: (context, _) {
              final currentProgress = _progressAnimation.value.clamp(0.0, 1.0);
              return _buildProgressLayout(
                currentProgress,
                context,
                constraints,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProgressLayout(
    double progress,
    BuildContext context,
    BoxConstraints constraints,
  ) {
    double barHeight, barWidth;

    final isHorizontal = widget.orientation == ProgressOrientation.horizontal;
    final double parentWidth = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : 250.0;

    if (isHorizontal) {
      barHeight = widget.baseHeight + widget.maxHeightIncrease * progress;
      barWidth = parentWidth;
    } else {
      barHeight = widget.baseHeight;
      barWidth = widget.width + widget.maxHeightIncrease * progress;
    }

    final progressBar = Container(
      width: barWidth,
      height: barHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.borderColor != null
            ? Border.all(color: widget.borderColor!, width: widget.borderWidth)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: CustomPaint(
          painter: ProgressPainter(
            progress: progress,
            orientation: widget.orientation,
            backgroundColor: widget.backgroundColor,
            progressColor: widget.progressColor,
            gradientColors: widget.gradientColors,
          ),
        ),
      ),
    );

    Widget? progressLabel = _buildProgressLabelBoxOrBubble(progress);
    Widget nameLabel = _buildNameLabel(context) ?? const SizedBox.shrink();

    final double maxLeftOffset = barWidth > 40.0 ? barWidth - 20.0 : 20.0;
    final double progressLabelLeft =
        (barWidth * progress).clamp(20.0, maxLeftOffset) - 20.0;

    final progressAndLabelStack = Stack(
      clipBehavior: Clip.none, // Allow label to draw outside
      alignment: Alignment.center,
      children: [
        progressBar,
        if (progressLabel != null)
          if (isHorizontal) // Horizontal Orientation
            Positioned(
              bottom: barHeight + widget.progressLabelSpacing,
              left: progressLabelLeft.isFinite ? progressLabelLeft : 0,
              child: progressLabel,
            )
          else // Vertical Orientation
            Positioned(
              left: 0,
              right: 0,
              bottom: (barHeight * progress) + widget.progressLabelSpacing,
              child: Align(alignment: Alignment.center, child: progressLabel),
            ),
      ],
    );

    if (widget.progressBarName.isEmpty) {
      return progressAndLabelStack;
    }

    switch (widget.nameLabelPosition) {
      case LabelPosition.top:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: widget.nameLabelPadding, child: nameLabel),
            SizedBox(height: widget.labelSpacing),
            progressAndLabelStack,
          ],
        );
      case LabelPosition.bottom:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            progressAndLabelStack,
            SizedBox(height: widget.labelSpacing),
            Padding(padding: widget.nameLabelPadding, child: nameLabel),
          ],
        );
      case LabelPosition.left:
        return Row(
          mainAxisSize: isHorizontal ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Padding(padding: widget.nameLabelPadding, child: nameLabel),
            ),
            SizedBox(width: widget.labelSpacing),
            if (isHorizontal)
              Expanded(child: progressAndLabelStack)
            else
              progressAndLabelStack,
          ],
        );
      case LabelPosition.right:
        return Row(
          mainAxisSize: isHorizontal ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isHorizontal)
              Expanded(child: progressAndLabelStack)
            else
              progressAndLabelStack,
            SizedBox(width: widget.labelSpacing),
            Flexible(
              child: Padding(padding: widget.nameLabelPadding, child: nameLabel),
            ),
          ],
        );
      case LabelPosition.center:
        return Stack(
          alignment: Alignment.center,
          children: [progressAndLabelStack, nameLabel],
        );
    }
  }

  Widget? _buildProgressLabelBoxOrBubble(double progress) {
    if (widget.progressLabelDisplay == ProgressLabelDisplay.none) return null;
    final labelText =
        widget.customProgressLabel ?? '${(progress * 100).toInt()}%';
    final textWidget = Text(
      labelText,
      style:
          widget.progressLabelStyle ??
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
    );
    Widget labelContent;
    if (widget.progressLabelDisplay == ProgressLabelDisplay.box) {
      labelContent = Container(
        padding: widget.progressLabelPadding,
        decoration: BoxDecoration(
          color: widget.progressLabelBackgroundColor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: textWidget,
      );
    } else {
      labelContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: widget.progressLabelPadding,
            decoration: BoxDecoration(
              color: widget.progressLabelBackgroundColor,
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: textWidget,
          ),
          CustomPaint(
            size: const Size(15, 8),
            painter: _TrianglePainter(
              color: widget.progressLabelBackgroundColor,
            ),
          ),
        ],
      );
    }
    if (widget.animateProgressLabel) {
      return AnimatedBuilder(
        animation: _progressLabelAnimation,
        builder: (context, child) => Transform.scale(
          scale: _progressLabelAnimation.value,
          child: Opacity(opacity: _progressLabelAnimation.value, child: child),
        ),
        child: labelContent,
      );
    }
    return labelContent;
  }

  Widget? _buildNameLabel(BuildContext context) {
    if (widget.progressBarName.isEmpty) return null;
    final theme = Theme.of(context);
    final textStyle = widget.nameLabelStyle ?? theme.textTheme.bodyMedium;
    Widget text = Text(
      widget.progressBarName,
      style: textStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (widget.animateNameLabel) {
      return AnimatedBuilder(
        animation: _nameLabelAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - _nameLabelAnimation.value)),
            child: Transform.scale(
              scale: 0.8 + (0.2 * _nameLabelAnimation.value),
              child: Opacity(
                opacity: _nameLabelAnimation.value.clamp(0.0, 1.0),
                child: child,
              ),
            ),
          );
        },
        child: text,
      );
    }
    return text;
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    // Ensure size is valid
    if (size.width <= 0 || size.height <= 0) return;

    var paint = Paint()..color = color;
    var path = Path();

    // Ensure coordinates are valid
    final x1 = size.width * 0.1;
    final x2 = size.width / 2;
    final x3 = size.width * 0.9;

    if (x1.isFinite && x2.isFinite && x3.isFinite) {
      path.moveTo(x1, 0);
      path.lineTo(x2, size.height);
      path.lineTo(x3, 0);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProgressPainter extends CustomPainter {
  final double progress;
  final ProgressOrientation orientation;
  final Color backgroundColor;
  final Color progressColor;
  final List<Color>? gradientColors;
  ProgressPainter({
    required this.progress,
    required this.orientation,
    required this.backgroundColor,
    required this.progressColor,
    this.gradientColors,
  });
  @override
  void paint(Canvas canvas, Size size) {
    // Ensure size is valid
    if (size.width <= 0 || size.height <= 0) return;

    final backgroundPaint = Paint()
      ..color = backgroundColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final progressPaint = Paint()..style = PaintingStyle.fill;

    // Ensure progress is valid
    final clampedProgress = progress.clamp(0.0, 1.0);

    if (gradientColors != null && gradientColors!.length > 1) {
      final Alignment begin = orientation == ProgressOrientation.horizontal
          ? Alignment.centerLeft
          : Alignment.bottomCenter;
      final Alignment end = orientation == ProgressOrientation.horizontal
          ? Alignment.centerRight
          : Alignment.topCenter;
      progressPaint.shader = LinearGradient(
        begin: begin,
        end: end,
        colors: gradientColors!,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      progressPaint.color = progressColor;
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    if (orientation == ProgressOrientation.horizontal) {
      final progressWidth = size.width * clampedProgress;
      // Ensure progressWidth is valid
      if (progressWidth.isFinite && progressWidth > 0) {
        canvas.drawRect(
          Rect.fromLTWH(0, 0, progressWidth, size.height),
          progressPaint,
        );
      }
    } else {
      final progressHeight = size.height * clampedProgress;
      // Ensure progressHeight is valid
      if (progressHeight.isFinite && progressHeight > 0) {
        canvas.drawRect(
          Rect.fromLTWH(
            0,
            size.height - progressHeight,
            size.width,
            progressHeight,
          ),
          progressPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ProgressPainter oldDelegate) => true;
}
