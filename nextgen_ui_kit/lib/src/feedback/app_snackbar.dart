import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pausable_timer/pausable_timer.dart';


/// ----------------- Snackbar Message -----------------
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
    this.dismissWhen,
    this.isLoading = false,
    this.backgroundColor,
  });

  const SnackbarMessage.success({
    String title = 'Successfully!',
    String? description,
    Duration timeout = const Duration(milliseconds: 3500),
  }) : this(
         title: title,
         description: description,
         icon: Icons.done,
         backgroundColor: const Color.fromARGB(255, 41, 166, 64),
         timeout: timeout,
       );

  const SnackbarMessage.info({
    String title = 'Info',
    String? description,
    Duration timeout = const Duration(milliseconds: 3500),
  }) : this(
         title: title,
         description: description,
         icon: Icons.help_outline_rounded,
         backgroundColor: const Color.fromARGB(255, 33, 150, 243),
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
         backgroundColor: const Color.fromARGB(255, 255, 152, 0), // Orange
         timeout: timeout,
       );

  const SnackbarMessage.loading({
    String title = 'Loading...',
    Duration timeout = const Duration(hours: 1),
  }) : this(
         title: title,
         isLoading: true,
         icon: null,
         backgroundColor: const Color.fromARGB(255, 66, 66, 66),
         timeout: timeout,
         undismissable: true,
       );

  const SnackbarMessage.error({
    String title = '',
    String? description,
    IconData? icon,
    Duration timeout = const Duration(milliseconds: 3500),
  }) : this(
         title: title,
         description: description,
         icon: icon ?? Icons.cancel_rounded,
         backgroundColor: const Color.fromARGB(255, 228, 71, 71),
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
  final FutureOr<bool>? dismissWhen;
  final bool isLoading;
  final Color? backgroundColor;
}

/// ----------------- App Snackbar Widget -----------------
class AppSnackbar extends StatefulWidget {
  const AppSnackbar({super.key});

  static void success(String title, {String? description}) {
    SnackbarService().showSuccess(title, description: description);
  }

  static void error(String title, {String? description}) {
    SnackbarService().showError(
      title,
      description: description != null
          ? title
          : null,
    );
  }

  static void info({required String title, String? message}) {
    SnackbarService().showInfo(title, description: message);
  }

  static void warning(String title, {String? description}) {
    SnackbarService().showWarning(title, description: description);
  }

  static void loading({required String title}) {
    SnackbarService().showLoading(title);
  }

  static void hideLoading() {
    SnackbarService().hideLoading();
  }

  @override
  State<AppSnackbar> createState() => AppSnackbarState();
}

class AppSnackbarState extends State<AppSnackbar>
    with TickerProviderStateMixin {
  PausableTimer? currentTimeout;
  late AnimationController _animationControllerY;
  late AnimationController _animationControllerX;
  late AnimationController _animationControllerErrorShake;
  late AnimationController _loadingAnimationController;
  double totalMovedNegative = 0;
  List<SnackbarMessage> currentQueue = [];
  SnackbarMessage? currentMessage;

  void post(
    SnackbarMessage message, {
    required bool clearIfQueue,
    required bool undismissable,
  }) {
    if (clearIfQueue && currentQueue.isNotEmpty) {
      currentQueue.clear();
      currentQueue.add(message);
      animateOut();
      return;
    }
    currentQueue.add(message);
    if (currentQueue.length <= 1) {
      animateIn(message, undismissable: undismissable);
    }
  }

  void clearLoading() {
    if (currentMessage?.isLoading == true) {
      animateOut();
    }
  }

  void animateIn(SnackbarMessage message, {bool undismissable = false}) {
    setState(() {
      currentMessage = currentQueue.isNotEmpty ? currentQueue[0] : null;
    });
    _animationControllerX.animateTo(0.5, duration: Duration.zero);
    _animationControllerY.animateTo(
      0.5,
      curve: const ElasticOutCurve(0.8),
      duration: Duration(
        milliseconds: ((_animationControllerY.value - 0.5).abs() * 800 + 900)
            .toInt(),
      ),
    );
    if (message.isError) shake();
    if (message.isLoading) {
      _loadingAnimationController.repeat();
    } else {
      _loadingAnimationController.stop();
    }

    if (!message.undismissable) {
      currentTimeout = PausableTimer(message.timeout, animateOut);
      currentTimeout!.start();
    }
  }

  void animateOut() {
    currentTimeout?.cancel();
    _loadingAnimationController.stop();

    // Animate out
    _animationControllerY
        .animateTo(
          0,
          curve: Curves.easeInBack,
          duration: const Duration(milliseconds: 400),
        )
        .then((_) {
          // CRITICAL FIX: Clear current message after animation completes
          if (mounted) {
            setState(() {
              currentMessage = null;
            });
          }
        });

    // Remove from queue
    if (currentQueue.isNotEmpty) currentQueue.removeAt(0);

    // Show next message if exists
    if (currentQueue.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          animateIn(currentQueue[0]);
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
      duration: const Duration(milliseconds: 1000),
    );
    _animationControllerX = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationControllerErrorShake =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1000),
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
    currentTimeout?.cancel();
    _animationControllerY.dispose();
    _animationControllerX.dispose();
    _animationControllerErrorShake.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  void _onPointerMove(PointerMoveEvent ptr) {
    if (currentMessage?.undismissable == true) return;

    if (ptr.delta.dy <= 0) totalMovedNegative += ptr.delta.dy;
    if (_animationControllerY.value <= 0.5) {
      _animationControllerY.value += ptr.delta.dy / 400;
    } else {
      _animationControllerY.value +=
          ptr.delta.dy / (2000 * _animationControllerY.value * 8);
    }
    _animationControllerX.value +=
        ptr.delta.dx / (1000 + (_animationControllerX.value - 0.5).abs() * 100);

    currentTimeout?.pause();
  }

  void _onPointerUp(PointerUpEvent event) {
    if (currentMessage?.undismissable == true) {
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

    if (totalMovedNegative <= -200 || _animationControllerY.value <= 0.4) {
      animateOut();
    } else {
      _animationControllerY.animateTo(
        0.5,
        curve: Curves.elasticOut,
        duration: Duration(
          milliseconds: ((_animationControllerY.value - 0.5).abs() * 800 + 700)
              .toInt(),
        ),
      );
      currentTimeout?.start();
    }
    _animationControllerX.animateTo(
      0.5,
      curve: Curves.elasticOut,
      duration: Duration(
        milliseconds: ((_animationControllerX.value - 0.5).abs() * 800 + 700)
            .toInt(),
      ),
    );
    totalMovedNegative = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (currentMessage == null) return const SizedBox.shrink();

    return AnimatedBuilder(
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
                (_animationControllerY.value - 0.5) * 400 +
                    MediaQuery.of(context).viewPadding.top +
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
        child: Center(
          child: Align(
            alignment: Alignment.topCenter,
            child: AnimatedBuilder(
              animation: _animationControllerErrorShake,
              builder: (context, child) {
                final sineValue = sin(
                  (currentMessage?.shakeCount ?? 3) *
                      2 *
                      pi *
                      _animationControllerErrorShake.value,
                );
                final shakeOffset = currentMessage?.shakeOffset ?? 10;
                return Transform.translate(
                  offset: Offset(sineValue * shakeOffset, 0),
                  child: child,
                );
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 350),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: currentMessage?.backgroundColor ?? Colors.blue,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .1),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (currentMessage?.isLoading == true)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: AnimatedBuilder(
                            animation: _loadingAnimationController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle:
                                    _loadingAnimationController.value * 2 * pi,
                                child: child,
                              );
                            },
                            child: const Icon(
                              Icons.sync,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else if (currentMessage?.icon != null)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: InkWell(
                            onTap: currentMessage?.undismissable == true
                                ? null
                                : animateOut,
                            child: Icon(
                              currentMessage?.icon,
                              size: currentMessage?.iconSize ?? 24,
                              color: currentMessage?.iconColor ?? Colors.white,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentMessage?.title ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (currentMessage?.description != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    currentMessage!.description!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
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

/// ----------------- Snackbar Service -----------------
class SnackbarService {
  static final SnackbarService _instance = SnackbarService._internal();
  factory SnackbarService() => _instance;
  SnackbarService._internal();

  final GlobalKey<AppSnackbarState> snackbarKey = GlobalKey<AppSnackbarState>();

  void showSuccess(String title, {String? description}) {
    snackbarKey.currentState?.post(
      SnackbarMessage.success(title: title, description: description),
      clearIfQueue: true,
      undismissable: false,
    );
  }

  void showInfo(String title, {String? description}) {
    snackbarKey.currentState?.post(
      SnackbarMessage.info(title: title, description: description),
      clearIfQueue: true,
      undismissable: false,
    );
  }

  void showWarning(String title, {String? description}) {
    snackbarKey.currentState?.post(
      SnackbarMessage.warning(title: title, description: description),
      clearIfQueue: true,
      undismissable: false,
    );
  }

  void showError(String title, {String? description}) {
    snackbarKey.currentState?.post(
      SnackbarMessage.error(
        title: title,
        description: description != null
            ? title
            : null,
      ),
      clearIfQueue: true,
      undismissable: false,
    );
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
}

final snackbarService = SnackbarService();

/// A convenient wrapper widget that injects [AppSnackbar] over the entire application.
/// Simply wrap your MaterialApp's `builder` with [SnackbarHost]:
/// ```dart
/// MaterialApp(
///   builder: (context, child) => SnackbarHost(child: child!),
/// )
/// ```
class SnackbarHost extends StatelessWidget {
  /// The root child widget (typically the Navigator/Scaffold).
  final Widget child;

  /// Optional alignment for the snackbar overlay (top or bottom). Defaults to Alignment.topCenter.
  final AlignmentGeometry alignment;

  const SnackbarHost({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Align(
          alignment: alignment,
          child: AppSnackbar(key: SnackbarService().snackbarKey),
        ),
      ],
    );
  }
}
