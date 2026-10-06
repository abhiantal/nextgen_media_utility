// ============================================================
// FILE: lib/src/core/media_snackbar.dart
// NextGen Media Utility - Premium Top-of-Screen Animated Snackbar
// ============================================================

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'media_logger.dart';

/// ----------------- Snackbar Message Model -----------------
class SnackbarMessage {
  const SnackbarMessage({
    this.title = '',
    this.description,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.timeout = const Duration(milliseconds: 3500),
    this.onTap,
    this.isError = false,
    this.shakeCount = 3,
    this.shakeOffset = 10,
    this.undismissable = false,
    this.isLoading = false,
    this.backgroundColor,
  });

  const SnackbarMessage.success({
    String title = 'Success!',
    String? description,
    Duration timeout = const Duration(milliseconds: 3500),
  }) : this(
         title: title,
         description: description,
         icon: Icons.check_circle_rounded,
         backgroundColor: const Color(0xFF10B981), // Emerald green
         timeout: timeout,
       );

  const SnackbarMessage.info({
    String title = 'Info',
    String? description,
    Duration timeout = const Duration(milliseconds: 3500),
  }) : this(
         title: title,
         description: description,
         icon: Icons.info_outline_rounded,
         backgroundColor: const Color(0xFF2563EB), // Blue
         timeout: timeout,
       );

  const SnackbarMessage.warning({
    String title = 'Warning',
    String? description,
    IconData? icon,
    Duration timeout = const Duration(milliseconds: 3500),
  }) : this(
         title: title,
         description: description,
         icon: icon ?? Icons.warning_amber_rounded,
         backgroundColor: const Color(0xFFF59E0B), // Amber orange
         timeout: timeout,
       );

  const SnackbarMessage.loading({
    String title = 'Loading...',
    Duration timeout = const Duration(hours: 1),
  }) : this(
         title: title,
         isLoading: true,
         icon: null,
         backgroundColor: const Color(0xFF374151), // Dark gray
         timeout: timeout,
         undismissable: true,
       );

  const SnackbarMessage.error({
    String title = 'Error',
    String? description,
    IconData? icon,
    Duration timeout = const Duration(milliseconds: 3500),
  }) : this(
         title: title,
         description: description,
         icon: icon ?? Icons.error_outline_rounded,
         backgroundColor: const Color(0xFFEF4444), // Red
         isError: true,
         timeout: timeout,
       );

  final String title;
  final String? description;
  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;
  final Duration timeout;
  final VoidCallback? onTap;
  final bool isError;
  final int shakeCount;
  final int shakeOffset;
  final bool undismissable;
  final bool isLoading;
  final Color? backgroundColor;
}

/// ----------------- Top-of-Screen Animated Snackbar Widget -----------------
class AppSnackbar extends StatefulWidget {
  const AppSnackbar({super.key});

  static GlobalKey<ScaffoldMessengerState>? messengerKey;

  static void success(String title, {String? description}) {
    snackbarService.showSuccess(title, description: description);
  }

  static void error(String title, {String? description}) {
    snackbarService.showError(title, description: description);
  }

  static void info({required String title, String? message}) {
    snackbarService.showInfo(title, description: message);
  }

  static void warning(String title, {String? description}) {
    snackbarService.showWarning(title, description: description);
  }

  static void loading({required String title}) {
    snackbarService.showLoading(title);
  }

  static void hideLoading() {
    snackbarService.hideLoading();
  }

  static void show(
    String message, {
    String? description,
    bool isError = false,
  }) {
    if (isError) {
      error(message, description: description);
    } else {
      success(message, description: description);
    }
  }

  static void showError(String message, {String? description}) =>
      error(message, description: description);
  static void showInfo(String message, {String? description}) =>
      info(title: message, message: description);
  static void showWarning(String message, {String? description}) =>
      warning(message, description: description);

  @override
  State<AppSnackbar> createState() => AppSnackbarState();
}

class AppSnackbarState extends State<AppSnackbar>
    with TickerProviderStateMixin {
  Timer? _dismissTimer;
  late AnimationController _animationControllerY;
  late AnimationController _animationControllerX;
  late AnimationController _animationControllerErrorShake;
  late AnimationController _loadingAnimationController;
  double _totalMovedNegative = 0;
  final List<SnackbarMessage> _currentQueue = [];
  SnackbarMessage? _currentMessage;

  void post(
    SnackbarMessage message, {
    required bool clearIfQueue,
    required bool undismissable,
  }) {
    if (clearIfQueue && _currentQueue.isNotEmpty) {
      _currentQueue.clear();
      _currentQueue.add(message);
      animateOut();
      return;
    }
    _currentQueue.add(message);
    if (_currentQueue.length <= 1) {
      animateIn(message, undismissable: undismissable);
    }
  }

  void clearLoading() {
    if (_currentMessage?.isLoading == true) {
      animateOut();
    }
  }

  void animateIn(SnackbarMessage message, {bool undismissable = false}) {
    setState(() {
      _currentMessage = _currentQueue.isNotEmpty ? _currentQueue[0] : null;
    });

    _animationControllerX.animateTo(0.5, duration: Duration.zero);
    _animationControllerY.animateTo(
      0.5,
      curve: const ElasticOutCurve(0.8),
      duration: Duration(
        milliseconds: ((_animationControllerY.value - 0.5).abs() * 800 + 800).toInt(),
      ),
    );

    if (message.isError) shake();

    if (message.isLoading) {
      _loadingAnimationController.repeat();
    } else {
      _loadingAnimationController.stop();
    }

    if (!message.undismissable) {
      _dismissTimer?.cancel();
      _dismissTimer = Timer(message.timeout, animateOut);
    }
  }

  void animateOut() {
    _dismissTimer?.cancel();
    _loadingAnimationController.stop();

    _animationControllerY
        .animateTo(
          0,
          curve: Curves.easeInBack,
          duration: const Duration(milliseconds: 350),
        )
        .then((_) {
          if (mounted) {
            setState(() {
              _currentMessage = null;
            });
          }
        });

    if (_currentQueue.isNotEmpty) {
      _currentQueue.removeAt(0);
    }

    if (_currentQueue.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          animateIn(_currentQueue[0]);
        }
      });
    }
  }

  void shake() => _animationControllerErrorShake.forward();

  @override
  void initState() {
    super.initState();
    _animationControllerY = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animationControllerX = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animationControllerErrorShake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationControllerErrorShake.reset();
      }
    });
    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animationControllerY.dispose();
    _animationControllerX.dispose();
    _animationControllerErrorShake.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  void _onPointerMove(PointerMoveEvent ptr) {
    if (_currentMessage?.undismissable == true) return;

    if (ptr.delta.dy <= 0) _totalMovedNegative += ptr.delta.dy;
    if (_animationControllerY.value <= 0.5) {
      _animationControllerY.value += ptr.delta.dy / 400;
    } else {
      _animationControllerY.value +=
          ptr.delta.dy / (2000 * _animationControllerY.value * 8);
    }
    _animationControllerX.value +=
        ptr.delta.dx / (1000 + (_animationControllerX.value - 0.5).abs() * 100);

    _dismissTimer?.cancel();
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_currentMessage?.undismissable == true) {
      _animationControllerY.animateTo(
        0.5,
        curve: Curves.elasticOut,
        duration: const Duration(milliseconds: 500),
      );
      _animationControllerX.animateTo(
        0.5,
        curve: Curves.elasticOut,
        duration: const Duration(milliseconds: 500),
      );
      return;
    }

    if (_totalMovedNegative <= -120 || _animationControllerY.value <= 0.4) {
      animateOut();
    } else {
      _animationControllerY.animateTo(
        0.5,
        curve: Curves.elasticOut,
        duration: Duration(
          milliseconds: ((_animationControllerY.value - 0.5).abs() * 800 + 600).toInt(),
        ),
      );
      _dismissTimer?.cancel();
      _dismissTimer = Timer(const Duration(milliseconds: 2500), animateOut);
    }

    _animationControllerX.animateTo(
      0.5,
      curve: Curves.elasticOut,
      duration: const Duration(milliseconds: 500),
    );
    _totalMovedNegative = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentMessage == null) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _animationControllerY,
        builder: (context, child) {
          if (_animationControllerY.value <= 0.01) {
            return const SizedBox.shrink();
          }

          return AnimatedBuilder(
            animation: _animationControllerX,
            builder: (context, innerChild) {
              return Transform.translate(
                offset: Offset(
                  (_animationControllerX.value - 0.5) * 100,
                  (_animationControllerY.value - 0.5) * 350 +
                      MediaQuery.paddingOf(context).top +
                      10,
                ),
                child: innerChild,
              );
            },
            child: child,
          );
        },
        child: Listener(
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          child: Align(
            alignment: Alignment.topCenter,
            child: AnimatedBuilder(
              animation: _animationControllerErrorShake,
              builder: (context, child) {
                final sineValue = sin(
                  (_currentMessage?.shakeCount ?? 3) *
                      2 *
                      pi *
                      _animationControllerErrorShake.value,
                );
                final shakeOffset = _currentMessage?.shakeOffset ?? 10;
                return Transform.translate(
                  offset: Offset(sineValue * shakeOffset, 0),
                  child: child,
                );
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 380),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _currentMessage?.backgroundColor ?? const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_currentMessage?.isLoading == true)
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: AnimatedBuilder(
                            animation: _loadingAnimationController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _loadingAnimationController.value * 2 * pi,
                                child: child,
                              );
                            },
                            child: const Icon(
                              Icons.sync_rounded,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else if (_currentMessage?.icon != null)
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: InkWell(
                            onTap: _currentMessage?.undismissable == true
                                ? null
                                : animateOut,
                            child: Icon(
                              _currentMessage?.icon,
                              size: _currentMessage?.iconSize ?? 24,
                              color: _currentMessage?.iconColor ?? Colors.white,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 6,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentMessage?.title ?? '',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (_currentMessage?.description != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    _currentMessage!.description!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                        onPressed: animateOut,
                        tooltip: 'Dismiss',
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ----------------- Singleton Snackbar Service -----------------
class SnackbarService {
  static final SnackbarService _instance = SnackbarService._internal();
  factory SnackbarService() => _instance;
  SnackbarService._internal();

  final GlobalKey<AppSnackbarState> snackbarKey = GlobalKey<AppSnackbarState>();

  void showSuccess(String title, {String? description}) {
    if (snackbarKey.currentState != null) {
      snackbarKey.currentState?.post(
        SnackbarMessage.success(title: title, description: description),
        clearIfQueue: true,
        undismissable: false,
      );
    } else {
      MediaLogger.info('$title ${description ?? ""}');
    }
  }

  void showInfo(String title, {String? description}) {
    if (snackbarKey.currentState != null) {
      snackbarKey.currentState?.post(
        SnackbarMessage.info(title: title, description: description),
        clearIfQueue: true,
        undismissable: false,
      );
    } else {
      MediaLogger.info('$title ${description ?? ""}');
    }
  }

  void showWarning(String title, {String? description}) {
    if (snackbarKey.currentState != null) {
      snackbarKey.currentState?.post(
        SnackbarMessage.warning(title: title, description: description),
        clearIfQueue: true,
        undismissable: false,
      );
    } else {
      MediaLogger.warning('$title ${description ?? ""}');
    }
  }

  void showError(String title, {String? description}) {
    if (snackbarKey.currentState != null) {
      snackbarKey.currentState?.post(
        SnackbarMessage.error(title: title, description: description),
        clearIfQueue: true,
        undismissable: false,
      );
    } else {
      MediaLogger.error('$title ${description ?? ""}');
    }
  }

  void showLoading(String title) {
    snackbarKey.currentState?.post(
      SnackbarMessage.loading(title: title),
      clearIfQueue: true,
      undismissable: true,
    );
  }

  void hideLoading() {
    snackbarKey.currentState?.clearLoading();
  }

  void hideAll() {
    snackbarKey.currentState?.animateOut();
  }

  void show(String message, {String? description, bool isError = false}) {
    if (isError) {
      showError(message, description: description);
    } else {
      showSuccess(message, description: description);
    }
  }

  void success(String message, {String? description}) =>
      showSuccess(message, description: description);
  void error(String message, {String? description}) =>
      showError(message, description: description);
  void warning(String message, {String? description}) =>
      showWarning(message, description: description);
  void info(String message, {String? description}) =>
      showInfo(message, description: description);
}

final snackbarService = SnackbarService();
typedef AppSnackBar = AppSnackbar;
