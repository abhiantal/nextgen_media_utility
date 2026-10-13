import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// ENUMS & CONFIGURATIONS
// ============================================================

/// Visual style variants for [MetricBadge].
enum MetricBadgeStyle {
  /// Soft tinted background with solid colored text/icon.
  tinted,

  /// Solid vibrant background with white/contrasting text.
  filled,

  /// Subtle border with transparent background.
  outlined,

  /// Futuristic neon glow shadow around the badge.
  glow,

  /// Semi-transparent glassmorphic frosted appearance.
  glass,

  /// Rich linear gradient fill.
  gradient,
}

/// Size presets for [MetricBadge].
enum MetricBadgeSize {
  small,
  medium,
  large,
}

/// Direction of metric trends.
enum TrendDirection {
  up,
  down,
  neutral,
}

/// Visual style for [MetricCard].
enum MetricCardVariant {
  /// Modern elevated card with subtle border and shadow.
  elevated,

  /// Flat card with subtle background tint.
  flat,

  /// Clean crisp outlined card with zero shadow.
  outlined,

  /// Sleek glassmorphism effect with blur and translucency.
  glass,

  /// Premium linear or mesh gradient card.
  gradient,
}

// ============================================================
// 1. PULSE INDICATOR (LIVE BEACON)
// ============================================================

/// An animated glowing pulse beacon indicator, commonly used to denote
/// "Live", "Online", "Recording", or active system states.
class PulseIndicator extends StatefulWidget {
  /// The diameter of the inner beacon dot. Defaults to 10.
  final double size;

  /// The primary color of the beacon. Defaults to emerald green (0xFF10B981).
  final Color color;

  /// Optional outer ring pulse color. Defaults to [color] with opacity.
  final Color? pulseColor;

  /// Whether the pulse animation is currently active. Defaults to true.
  final bool isPulsing;

  /// Optional text label next to the pulse indicator.
  final String? label;

  /// Style for the [label] text.
  final TextStyle? labelStyle;

  /// Spacing between the dot and the [label]. Defaults to 6.
  final double spacing;

  const PulseIndicator({
    super.key,
    this.size = 10,
    this.color = const Color(0xFF10B981),
    this.pulseColor,
    this.isPulsing = true,
    this.label,
    this.labelStyle,
    this.spacing = 6.0,
  });

  @override
  State<PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<PulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.isPulsing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PulseIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPulsing && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectivePulseColor = widget.pulseColor ?? widget.color;

    final dotWidget = SizedBox(
      width: widget.size * 2.2,
      height: widget.size * 2.2,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                if (widget.isPulsing)
                  Container(
                    width: widget.size + (widget.size * 1.2 * _controller.value),
                    height: widget.size + (widget.size * 1.2 * _controller.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: effectivePulseColor.withValues(
                        alpha: (1.0 - _controller.value) * 0.5,
                      ),
                    ),
                  ),
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    if (widget.label == null) {
      return dotWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        dotWidget,
        SizedBox(width: widget.spacing),
        Text(
          widget.label!,
          style: widget.labelStyle ??
              TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.color,
                letterSpacing: 0.3,
              ),
        ),
      ],
    );
  }
}

// ============================================================
// 2. TREND INDICATOR
// ============================================================

/// A versatile badge displaying metric trends (positive, negative, or neutral),
/// such as delta changes, market shifts, or performance comparisons.
class TrendIndicator extends StatelessWidget {
  /// The formatted delta value string (e.g. "+12.5%", "-3.2%", "0.0%").
  final String value;

  /// Direction of the trend. If null, automatically inferred from `+` or `-` in [value].
  final TrendDirection? direction;

  /// Whether an upward trend is considered favorable (green) vs adverse (red).
  ///
  /// Set to false for metrics where lower is better (e.g. latency, bug count).
  final bool isPositiveGood;

  /// Visual presentation style: tinted, filled, outlined, or glow.
  final MetricBadgeStyle style;

  /// Custom override color for the trend badge.
  final Color? customColor;

  /// Whether to display the directional arrow icon. Defaults to true.
  final bool showIcon;

  /// Size preset for font and padding. Defaults to [MetricBadgeSize.small].
  final MetricBadgeSize size;

  const TrendIndicator({
    super.key,
    required this.value,
    this.direction,
    this.isPositiveGood = true,
    this.style = MetricBadgeStyle.tinted,
    this.customColor,
    this.showIcon = true,
    this.size = MetricBadgeSize.small,
  });

  TrendDirection get _resolvedDirection {
    if (direction != null) return direction!;
    if (value.startsWith('+') || value.toLowerCase().contains('up')) {
      return TrendDirection.up;
    }
    if (value.startsWith('-') || value.toLowerCase().contains('down')) {
      return TrendDirection.down;
    }
    return TrendDirection.neutral;
  }

  Color _resolveColor() {
    if (customColor != null) return customColor!;
    final dir = _resolvedDirection;
    if (dir == TrendDirection.neutral) {
      return const Color(0xFF94A3B8); // Slate 400
    }
    final isUp = dir == TrendDirection.up;
    final isFavorable = isPositiveGood ? isUp : !isUp;
    return isFavorable
        ? const Color(0xFF10B981) // Emerald Green
        : const Color(0xFFEF4444); // Crimson Red
  }

  IconData _resolveIcon() {
    switch (_resolvedDirection) {
      case TrendDirection.up:
        return Icons.trending_up_rounded;
      case TrendDirection.down:
        return Icons.trending_down_rounded;
      case TrendDirection.neutral:
        return Icons.trending_flat_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor();
    final icon = _resolveIcon();

    return MetricBadge(
      label: value,
      icon: showIcon ? icon : null,
      color: color,
      style: style,
      size: size,
    );
  }
}

// ============================================================
// 3. METRIC BADGE (HIGH-IMPACT STATUS & TAG PILL)
// ============================================================

/// Highly customizable modern metric badge and status pill widget.
class MetricBadge extends StatelessWidget {
  /// The primary label text.
  final String label;

  /// Optional secondary or numerical value displayed after [label].
  final String? value;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional custom leading widget (takes precedence over [icon]).
  final Widget? leading;

  /// Optional trailing widget.
  final Widget? trailing;

  /// Base accent color for the badge. Defaults to system primary.
  final Color? color;

  /// Custom text color override.
  final Color? textColor;

  /// Custom icon color override.
  final Color? iconColor;

  /// Custom border color override.
  final Color? borderColor;

  /// Custom gradient (used with [MetricBadgeStyle.gradient]).
  final Gradient? gradient;

  /// Visual presentation style variant. Defaults to [MetricBadgeStyle.tinted].
  final MetricBadgeStyle style;

  /// Size preset. Defaults to [MetricBadgeSize.medium].
  final MetricBadgeSize size;

  /// Corner radius. If null, a fully rounded pill border is applied.
  final BorderRadius? borderRadius;

  /// Optional interactive tap handler with haptic feedback.
  final VoidCallback? onTap;

  /// Explicit custom padding override.
  final EdgeInsetsGeometry? padding;

  const MetricBadge({
    super.key,
    required this.label,
    this.value,
    this.icon,
    this.leading,
    this.trailing,
    this.color,
    this.textColor,
    this.iconColor,
    this.borderColor,
    this.gradient,
    this.style = MetricBadgeStyle.tinted,
    this.size = MetricBadgeSize.medium,
    this.borderRadius,
    this.onTap,
    this.padding,
  });

  // --- FACTORY PRESETS ---

  /// Quick success badge preset (Emerald).
  factory MetricBadge.success({
    Key? key,
    required String label,
    String? value,
    IconData icon = Icons.check_circle_rounded,
    MetricBadgeStyle style = MetricBadgeStyle.tinted,
    MetricBadgeSize size = MetricBadgeSize.medium,
    VoidCallback? onTap,
  }) {
    return MetricBadge(
      key: key,
      label: label,
      value: value,
      icon: icon,
      color: const Color(0xFF10B981),
      style: style,
      size: size,
      onTap: onTap,
    );
  }

  /// Quick error/critical badge preset (Crimson).
  factory MetricBadge.error({
    Key? key,
    required String label,
    String? value,
    IconData icon = Icons.error_rounded,
    MetricBadgeStyle style = MetricBadgeStyle.tinted,
    MetricBadgeSize size = MetricBadgeSize.medium,
    VoidCallback? onTap,
  }) {
    return MetricBadge(
      key: key,
      label: label,
      value: value,
      icon: icon,
      color: const Color(0xFFEF4444),
      style: style,
      size: size,
      onTap: onTap,
    );
  }

  /// Quick warning/caution badge preset (Amber).
  factory MetricBadge.warning({
    Key? key,
    required String label,
    String? value,
    IconData icon = Icons.warning_amber_rounded,
    MetricBadgeStyle style = MetricBadgeStyle.tinted,
    MetricBadgeSize size = MetricBadgeSize.medium,
    VoidCallback? onTap,
  }) {
    return MetricBadge(
      key: key,
      label: label,
      value: value,
      icon: icon,
      color: const Color(0xFFF59E0B),
      style: style,
      size: size,
      onTap: onTap,
    );
  }

  /// Quick info badge preset (Sky Blue).
  factory MetricBadge.info({
    Key? key,
    required String label,
    String? value,
    IconData icon = Icons.info_outline_rounded,
    MetricBadgeStyle style = MetricBadgeStyle.tinted,
    MetricBadgeSize size = MetricBadgeSize.medium,
    VoidCallback? onTap,
  }) {
    return MetricBadge(
      key: key,
      label: label,
      value: value,
      icon: icon,
      color: const Color(0xFF0284C7),
      style: style,
      size: size,
      onTap: onTap,
    );
  }

  /// Quick live/pulsing badge preset.
  factory MetricBadge.live({
    Key? key,
    String label = 'LIVE',
    Color color = const Color(0xFFEF4444),
    MetricBadgeStyle style = MetricBadgeStyle.tinted,
    MetricBadgeSize size = MetricBadgeSize.small,
  }) {
    return MetricBadge(
      key: key,
      label: label,
      leading: PulseIndicator(
        size: 8,
        color: color,
        isPulsing: true,
      ),
      color: color,
      style: style,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = color ?? theme.colorScheme.primary;

    // Sizing specs
    final double fontSize;
    final double iconSize;
    final EdgeInsetsGeometry resolvedPadding;

    switch (size) {
      case MetricBadgeSize.small:
        fontSize = 11;
        iconSize = 13;
        resolvedPadding = padding ??
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3);
        break;
      case MetricBadgeSize.medium:
        fontSize = 13;
        iconSize = 15;
        resolvedPadding = padding ??
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
        break;
      case MetricBadgeSize.large:
        fontSize = 15;
        iconSize = 18;
        resolvedPadding = padding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 9);
        break;
    }

    // Styling specs
    Color bg;
    Color fg;
    Color borderC = borderColor ?? Colors.transparent;
    List<BoxShadow>? shadows;
    Gradient? effGradient;

    switch (style) {
      case MetricBadgeStyle.tinted:
        bg = baseColor.withValues(alpha: 0.12);
        fg = textColor ?? baseColor;
        borderC = borderColor ?? baseColor.withValues(alpha: 0.2);
        break;

      case MetricBadgeStyle.filled:
        bg = baseColor;
        fg = textColor ?? Colors.white;
        break;

      case MetricBadgeStyle.outlined:
        bg = Colors.transparent;
        fg = textColor ?? baseColor;
        borderC = borderColor ?? baseColor.withValues(alpha: 0.6);
        break;

      case MetricBadgeStyle.glow:
        bg = baseColor.withValues(alpha: 0.18);
        fg = textColor ?? baseColor;
        borderC = borderColor ?? baseColor.withValues(alpha: 0.4);
        shadows = [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ];
        break;

      case MetricBadgeStyle.glass:
        bg = baseColor.withValues(alpha: 0.15);
        fg = textColor ?? (theme.brightness == Brightness.dark ? Colors.white : Colors.black87);
        borderC = borderColor ?? Colors.white.withValues(alpha: 0.25);
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
        break;

      case MetricBadgeStyle.gradient:
        bg = Colors.transparent;
        fg = textColor ?? Colors.white;
        effGradient = gradient ??
            LinearGradient(
              colors: [
                baseColor,
                baseColor.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );
        break;
    }

    final effBorderRadius = borderRadius ?? BorderRadius.circular(100);

    Widget badgeContent = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 5),
        ] else if (icon != null) ...[
          Icon(
            icon,
            size: iconSize,
            color: iconColor ?? fg,
          ),
          const SizedBox(width: 5),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: fg,
            letterSpacing: 0.2,
          ),
        ),
        if (value != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: style == MetricBadgeStyle.filled
                  ? Colors.white.withValues(alpha: 0.25)
                  : baseColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value!,
              style: TextStyle(
                fontSize: fontSize * 0.9,
                fontWeight: FontWeight.bold,
                color: style == MetricBadgeStyle.filled ? Colors.white : baseColor,
              ),
            ),
          ),
        ],
        if (trailing != null) ...[
          const SizedBox(width: 5),
          trailing!,
        ],
      ],
    );

    Widget container = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: resolvedPadding,
      decoration: BoxDecoration(
        color: effGradient == null ? bg : null,
        gradient: effGradient,
        borderRadius: effBorderRadius,
        border: borderC != Colors.transparent ? Border.all(color: borderC, width: 1.2) : null,
        boxShadow: shadows,
      ),
      child: badgeContent,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap!();
          },
          borderRadius: effBorderRadius,
          child: container,
        ),
      );
    }

    return container;
  }
}

// ============================================================
// 4. METRIC CARD (STAT & KPI DASHBOARD CARD)
// ============================================================

/// Ultra-modern KPI and dashboard metric card displaying title, value, icon,
/// trend indication, and optional actions.
class MetricCard extends StatelessWidget {
  /// Category, metric, or KPI title (e.g. "Total Revenue", "Active Users").
  final String title;

  /// Primary metric value string (e.g. "$48,250", "98.4%", "1,240").
  final String value;

  /// Optional subtitle or contextual secondary note (e.g. "vs previous period").
  final String? subtitle;

  /// Leading or top-right indicator icon.
  final IconData? icon;

  /// Leading icon accent color. Defaults to theme primary.
  final Color? iconColor;

  /// Custom container background color for the icon.
  final Color? iconBackgroundColor;

  /// Optional trend value string or widget (e.g. "+14.2%").
  final String? trend;

  /// Explicit trend direction.
  final TrendDirection? trendDirection;

  /// Visual presentation style variant for the card.
  final MetricCardVariant variant;

  /// Custom background color override.
  final Color? backgroundColor;

  /// Custom gradient fill.
  final Gradient? gradient;

  /// Corner radius for the card. Defaults to 18.
  final BorderRadius? borderRadius;

  /// Padding inside the card. Defaults to EdgeInsets.all(18).
  final EdgeInsetsGeometry? padding;

  /// Optional badge widget displayed beside the title.
  final Widget? badge;

  /// Optional bottom footer widget (e.g. progress bar, sparkline, or action link).
  final Widget? footer;

  /// Interactive tap callback.
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.trend,
    this.trendDirection,
    this.variant = MetricCardVariant.elevated,
    this.backgroundColor,
    this.gradient,
    this.borderRadius,
    this.padding,
    this.badge,
    this.footer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = iconColor ?? theme.colorScheme.primary;

    Color bg;
    Border? border;
    List<BoxShadow>? shadows;
    Gradient? effGradient;

    final effRadius = borderRadius ?? BorderRadius.circular(18);

    switch (variant) {
      case MetricCardVariant.elevated:
        bg = backgroundColor ?? (isDark ? const Color(0xFF1E293B) : Colors.white);
        border = Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        );
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];
        break;

      case MetricCardVariant.flat:
        bg = backgroundColor ??
            (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC));
        break;

      case MetricCardVariant.outlined:
        bg = backgroundColor ?? Colors.transparent;
        border = Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1.4,
        );
        break;

      case MetricCardVariant.glass:
        bg = backgroundColor ??
            (isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.65));
        border = Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.4),
          width: 1.2,
        );
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ];
        break;

      case MetricCardVariant.gradient:
        bg = Colors.transparent;
        effGradient = gradient ??
            LinearGradient(
              colors: [
                primary.withValues(alpha: 0.85),
                primary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );
        shadows = [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ];
        break;
    }

    final isWhiteText = variant == MetricCardVariant.gradient;

    Widget cardBody = Padding(
      padding: padding ?? const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Title + Icon + Optional Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isWhiteText
                              ? Colors.white.withValues(alpha: 0.9)
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      badge!,
                    ],
                  ],
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 12),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor ??
                        (isWhiteText
                            ? Colors.white.withValues(alpha: 0.2)
                            : primary.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isWhiteText ? Colors.white : primary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Primary Value
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isWhiteText
                  ? Colors.white
                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),

          // Subtitle and / or Trend
          if (trend != null || subtitle != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (trend != null) ...[
                  TrendIndicator(
                    value: trend!,
                    direction: trendDirection,
                    style: isWhiteText ? MetricBadgeStyle.filled : MetricBadgeStyle.tinted,
                    customColor: isWhiteText ? Colors.white.withValues(alpha: 0.25) : null,
                  ),
                  const SizedBox(width: 8),
                ],
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isWhiteText
                            ? Colors.white.withValues(alpha: 0.8)
                            : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],

          // Footer
          if (footer != null) ...[
            const SizedBox(height: 14),
            footer!,
          ],
        ],
      ),
    );

    Widget container = Container(
      decoration: BoxDecoration(
        color: effGradient == null ? bg : null,
        gradient: effGradient,
        borderRadius: effRadius,
        border: border,
        boxShadow: shadows,
      ),
      child: cardBody,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effRadius,
          child: container,
        ),
      );
    }

    return container;
  }
}

// ============================================================
// 5. METRIC GROUP ROW
// ============================================================

/// Clean layout wrapper to arrange multiple metric indicators or badges
/// horizontally with responsive wrapping or scrolling.
class MetricIndicatorGroup extends StatelessWidget {
  /// The collection of badges or indicators.
  final List<Widget> children;

  /// Horizontal spacing between items. Defaults to 8.
  final double spacing;

  /// Vertical spacing between wrapped rows. Defaults to 8.
  final double runSpacing;

  /// Alignment of items along the main axis.
  final WrapAlignment alignment;

  /// When true, renders a horizontal scroll view instead of a wrapping container.
  final bool scrollable;

  const MetricIndicatorGroup({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.alignment = WrapAlignment.start,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) SizedBox(width: spacing),
            ],
          ],
        ),
      );
    }

    return Wrap(
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: spacing,
      runSpacing: runSpacing,
      children: children,
    );
  }
}
