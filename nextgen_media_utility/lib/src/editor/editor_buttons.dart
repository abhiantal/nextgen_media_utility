// ============================================================
// FILE: lib/media_utility/editor_buttons.dart
// Enhanced Editor Buttons with Animations & Haptics
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// TOP BAR BUTTON - ANIMATED & INTERACTIVE
// ============================================================

class TopBarButton extends StatefulWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;
  final bool isDark;
  final String? tooltip;

  const TopBarButton({
    super.key,
    required this.icon,
    required this.isActive,
    required this.onPressed,
    required this.isDark,
    this.tooltip,
  });

  @override
  State<TopBarButton> createState() => _TopBarButtonState();
}

class _TopBarButtonState extends State<TopBarButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isActive
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: widget.isActive
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.isActive
                      ? Colors.white
                      : (widget.isDark ? Colors.white70 : Colors.black54),
                  size: 22,
                ),
              ),
            ),
          );
        },
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        preferBelow: true,
        verticalOffset: 20,
        child: button,
      );
    }

    return button;
  }
}

// ============================================================
// BOTTOM BAR BUTTON - MODERN & ANIMATED
// ============================================================

class BottomBarButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;
  final Color? color;

  const BottomBarButton({
    super.key,
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onPressed,
    this.color,
  });

  @override
  State<BottomBarButton> createState() => _BottomBarButtonState();
}

class _BottomBarButtonState extends State<BottomBarButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _activeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _activeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _activeController, curve: Curves.elasticOut),
    );

    if (widget.isActive) {
      _activeController.forward();
    }
  }

  @override
  void didUpdateWidget(BottomBarButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _activeController.forward();
      } else {
        _activeController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _activeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTapDown: (_) {
        _pressController.forward();
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        _pressController.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pressController, _activeController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background circle
                        if (widget.isActive)
                          Transform.scale(
                            scale: _bounceAnimation.value,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        // Icon
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          child: Icon(
                            widget.icon,
                            color: widget.isActive ? color : Colors.grey,
                            size: widget.isActive ? 26 : 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: widget.isActive ? color : Colors.grey,
                        fontSize: widget.isActive ? 13 : 12,
                        fontWeight: widget.isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// ADJUSTMENT SLIDER - MODERN & INTERACTIVE
// ============================================================

class AdjustmentSlider extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final IconData? icon;
  final Color? activeColor;
  final double min;
  final double max;

  const AdjustmentSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon,
    this.activeColor,
    this.min = -1.0,
    this.max = 1.0,
  });

  @override
  State<AdjustmentSlider> createState() => _AdjustmentSliderState();
}

class _AdjustmentSliderState extends State<AdjustmentSlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _indicatorAnimation;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _indicatorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart() {
    setState(() => _isDragging = true);
    _controller.forward();
    HapticFeedback.selectionClick();
  }

  void _handleDragEnd() {
    setState(() => _isDragging = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = widget.activeColor ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _indicatorAnimation,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.1 + (0.1 * _indicatorAnimation.value),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${(widget.value * 100).toInt()}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: activeColor,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
              thumbColor: Colors.white,
              overlayColor: activeColor.withValues(alpha: 0.2),
              trackHeight: _isDragging ? 6 : 4,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: _isDragging ? 8 : 6,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: widget.value,
              min: widget.min,
              max: widget.max,
              onChangeStart: (_) => _handleDragStart(),
              onChangeEnd: (_) => _handleDragEnd(),
              onChanged: (value) {
                widget.onChanged(value);
                if (value.abs() < 0.05) {
                  // Snap to zero
                  HapticFeedback.lightImpact();
                  widget.onChanged(0);
                }
              },
            ),
          ),
          // Reset button
          if (widget.value != 0)
            Center(
              child: TextButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onChanged(0);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: const Text('Reset', style: TextStyle(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// FLOATING ACTION BUTTON - ANIMATED
// ============================================================

class AnimatedFloatingButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isExtended;
  final String? label;

  const AnimatedFloatingButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.isExtended = false,
    this.label,
  });

  @override
  State<AnimatedFloatingButton> createState() => _AnimatedFloatingButtonState();
}

class _AnimatedFloatingButtonState extends State<AnimatedFloatingButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _handlePress() {
    HapticFeedback.mediumImpact();
    _rotationController.forward().then((_) {
      _rotationController.reverse();
    });
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final foregroundColor = widget.foregroundColor ?? Colors.white;

    final button = AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _rotationController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: Material(
              color: backgroundColor,
              elevation: 6,
              shadowColor: backgroundColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: _handlePress,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isExtended ? 20 : 16,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, color: foregroundColor),
                      if (widget.isExtended && widget.label != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          widget.label!,
                          style: TextStyle(
                            color: foregroundColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}

// ============================================================
// COLOR PICKER BUTTON - ANIMATED
// ============================================================

class ColorPickerButton extends StatefulWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final double size;

  const ColorPickerButton({
    super.key,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.size = 40,
  });

  @override
  State<ColorPickerButton> createState() => _ColorPickerButtonState();
}

class _ColorPickerButtonState extends State<ColorPickerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ColorPickerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isSelected ? _scaleAnimation.value : 1.0,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isSelected ? Colors.white : Colors.white54,
                  width: widget.isSelected ? 3 : 2,
                ),
                boxShadow: [
                  if (widget.isSelected)
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: widget.isSelected
                  ? const Center(
                      child: Icon(Icons.check, color: Colors.white, size: 16),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// ICON TOGGLE BUTTON - ANIMATED
// ============================================================

class IconToggleButton extends StatefulWidget {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final bool isActive;
  final VoidCallback onToggle;
  final Color? activeColor;
  final Color? inactiveColor;
  final double size;

  const IconToggleButton({
    super.key,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.isActive,
    required this.onToggle,
    this.activeColor,
    this.inactiveColor,
    this.size = 24,
  });

  @override
  State<IconToggleButton> createState() => _IconToggleButtonState();
}

class _IconToggleButtonState extends State<IconToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor =
        widget.activeColor ?? Theme.of(context).colorScheme.primary;
    final inactiveColor = widget.inactiveColor ?? Colors.grey;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _controller.forward(from: 0);
        widget.onToggle();
      },
      child: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                widget.isActive ? widget.activeIcon : widget.inactiveIcon,
                key: ValueKey(widget.isActive),
                color: widget.isActive ? activeColor : inactiveColor,
                size: widget.size,
              ),
            ),
          );
        },
      ),
    );
  }
}
