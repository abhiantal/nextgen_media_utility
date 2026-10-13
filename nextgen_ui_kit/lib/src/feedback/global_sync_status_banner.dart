import 'dart:async';
import 'package:flutter/material.dart';

/// Represents high-level cloud synchronization and backend server status.
enum ServerSyncState {
  /// Connected and fully synchronized.
  synced,

  /// Actively uploading or downloading data.
  syncing,

  /// Device has no network connection.
  offline,

  /// Server is unreachable, DNS failed, or database service is paused.
  serverPaused,

  /// Authentication token or session has expired.
  authExpired,

  /// Transient state when connectivity is restored before returning to synced.
  restored,
}

/// Placement position for [GlobalSyncStatusBanner].
enum SyncBannerPosition {
  top,
  bottom,
}

/// Comprehensive customization configuration for [GlobalSyncStatusBanner].
class SyncBannerConfig {
  // Offline State
  final String offlineTitle;
  final String offlineSubtitle;
  final String offlineExplanation;

  // Server Paused / Unreachable State
  final String serverPausedTitle;
  final String serverPausedSubtitle;
  final String serverPausedExplanation;
  final String? serverPausedResolutionTip;

  // Auth Expired State
  final String authExpiredTitle;
  final String authExpiredSubtitle;
  final String authExpiredExplanation;

  // Restored State
  final String restoredTitle;
  final String restoredSubtitle;

  // Local Data Guarantee Note
  final String localDataSafetyNote;

  // Colors & Gradients overrides
  final List<Color>? offlineGradient;
  final List<Color>? serverPausedGradient;
  final List<Color>? authExpiredGradient;
  final List<Color>? restoredGradient;

  // Custom Dialog Builder
  final Widget Function(BuildContext context, ServerSyncState state, VoidCallback onRetry)?
      customDialogBuilder;

  const SyncBannerConfig({
    this.offlineTitle = "You're Offline",
    this.offlineSubtitle = 'Changes are safely stored locally on this device.',
    this.offlineExplanation =
        'Your device has no active internet connection. All data created or edited is preserved locally and will sync automatically once reconnected.',
    this.serverPausedTitle = 'Cloud Sync Paused',
    this.serverPausedSubtitle = 'Remote server unreachable. Working in offline mode.',
    this.serverPausedExplanation =
        'The remote server or database is temporarily unreachable. All changes are being recorded locally and will synchronize seamlessly once the server resumes.',
    this.serverPausedResolutionTip =
        '• Check your server dashboard or network status.\n• Edits will automatically sync once the connection is re-established.',
    this.authExpiredTitle = 'Sync Paused (Session Expired)',
    this.authExpiredSubtitle = 'Re-authentication required to complete cloud sync.',
    this.authExpiredExplanation =
        'Your authentication session has expired or requires renewal. Please log in again to continue synchronizing changes.',
    this.restoredTitle = 'Cloud Sync Restored',
    this.restoredSubtitle = 'Connection restored and data is up to date.',
    this.localDataSafetyNote =
        'Your data is completely safe. All changes are stored locally first.',
    this.offlineGradient,
    this.serverPausedGradient,
    this.authExpiredGradient,
    this.restoredGradient,
    this.customDialogBuilder,
  });
}

/// Global controller to broadcast sync state updates across the app.
class SyncStatusController {
  static final ValueNotifier<ServerSyncState> notifier =
      ValueNotifier(ServerSyncState.synced);
  static Future<void> Function()? onRetryCallback;

  static ServerSyncState get current => notifier.value;
  static set current(ServerSyncState state) => notifier.value = state;

  static void update(ServerSyncState state) {
    notifier.value = state;
  }
}

/// A modern, non-intrusive sliding banner informing users when cloud
/// synchronization is paused, offline, or experiencing connection issues.
///
/// Features a built-in grace period and proactive background auto-retry
/// to avoid alarming users during transient socket drops or brief reconnects.
class GlobalSyncStatusBanner extends StatefulWidget {
  /// Custom sync state notifier. If null, defaults to [SyncStatusController.notifier].
  final ValueNotifier<ServerSyncState>? syncStateNotifier;

  /// Custom retry callback. If null, defaults to [SyncStatusController.onRetryCallback].
  final Future<void> Function()? onRetry;

  /// Grace period duration before showing transient errors (default: 12 seconds).
  final Duration graceDuration;

  /// Delay before triggering silent proactive background retry. Defaults to 4 seconds.
  final Duration autoRetryDelay;

  /// Detailed copy and color configuration.
  final SyncBannerConfig config;

  /// Screen position for the banner (top or bottom). Defaults to [SyncBannerPosition.top].
  final SyncBannerPosition position;

  /// Whether the user can tap the banner to open an informative explanation dialog.
  final bool showDetailsDialog;

  /// Whether to show a dismiss (X) button on the banner. Defaults to true.
  final bool dismissible;

  /// Callback when user dismisses the banner.
  final VoidCallback? onDismissed;

  const GlobalSyncStatusBanner({
    super.key,
    this.syncStateNotifier,
    this.onRetry,
    this.graceDuration = const Duration(seconds: 12),
    this.autoRetryDelay = const Duration(seconds: 4),
    this.config = const SyncBannerConfig(),
    this.position = SyncBannerPosition.top,
    this.showDetailsDialog = true,
    this.dismissible = true,
    this.onDismissed,
  });

  @override
  State<GlobalSyncStatusBanner> createState() => _GlobalSyncStatusBannerState();
}

class _GlobalSyncStatusBannerState extends State<GlobalSyncStatusBanner> {
  ServerSyncState? _visibleState;
  ServerSyncState _renderedState = ServerSyncState.offline;
  ServerSyncState? _pendingErrorState;
  Timer? _graceTimer;
  Timer? _autoRetryTimer;
  bool _isDismissedForCurrentState = false;
  bool _isRetrying = false;

  ValueNotifier<ServerSyncState> get _effectiveNotifier =>
      widget.syncStateNotifier ?? SyncStatusController.notifier;

  @override
  void initState() {
    super.initState();
    _effectiveNotifier.addListener(_onSyncStateChanged);
    _onSyncStateChanged();
  }

  @override
  void didUpdateWidget(covariant GlobalSyncStatusBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.syncStateNotifier != widget.syncStateNotifier) {
      (oldWidget.syncStateNotifier ?? SyncStatusController.notifier)
          .removeListener(_onSyncStateChanged);
      _effectiveNotifier.addListener(_onSyncStateChanged);
      _onSyncStateChanged();
    }
  }

  @override
  void dispose() {
    _effectiveNotifier.removeListener(_onSyncStateChanged);
    _cancelGraceTimers();
    super.dispose();
  }

  bool _isErrorState(ServerSyncState state) {
    return state == ServerSyncState.serverPaused ||
        state == ServerSyncState.offline ||
        state == ServerSyncState.authExpired;
  }

  void _onSyncStateChanged() {
    final state = _effectiveNotifier.value;

    if (_isErrorState(state)) {
      if (_visibleState != null && _isErrorState(_visibleState!)) {
        if (_visibleState != state) {
          setState(() {
            _visibleState = state;
            _renderedState = state;
            _isDismissedForCurrentState = false;
          });
        }
        return;
      }
      _scheduleGracePeriod(state);
    } else if (state == ServerSyncState.restored) {
      _cancelGraceTimers();
      if (_visibleState != null && _isErrorState(_visibleState!)) {
        setState(() {
          _visibleState = ServerSyncState.restored;
          _renderedState = ServerSyncState.restored;
          _isDismissedForCurrentState = false;
        });
      } else {
        if (_visibleState != null) {
          setState(() => _visibleState = null);
        }
      }
    } else {
      _cancelGraceTimers();
      if (_visibleState != null) {
        setState(() {
          _visibleState = null;
          _isDismissedForCurrentState = false;
        });
      }
    }
  }

  void _scheduleGracePeriod(ServerSyncState errorState) {
    _pendingErrorState = errorState;

    if (_graceTimer?.isActive ?? false) return;

    _autoRetryTimer?.cancel();
    _autoRetryTimer = Timer(widget.autoRetryDelay, () async {
      if (!mounted) return;
      if (_pendingErrorState != null) {
        try {
          if (widget.onRetry != null) {
            await widget.onRetry!();
          } else if (SyncStatusController.onRetryCallback != null) {
            await SyncStatusController.onRetryCallback!();
          }
        } catch (_) {}
      }
    });

    _graceTimer?.cancel();
    _graceTimer = Timer(widget.graceDuration, () {
      if (!mounted) return;
      if (_pendingErrorState != null) {
        setState(() {
          _visibleState = _pendingErrorState;
          _renderedState = _pendingErrorState!;
          _pendingErrorState = null;
          _isDismissedForCurrentState = false;
        });
      }
    });
  }

  void _cancelGraceTimers() {
    _graceTimer?.cancel();
    _graceTimer = null;
    _autoRetryTimer?.cancel();
    _autoRetryTimer = null;
    _pendingErrorState = null;
  }

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      if (widget.onRetry != null) {
        await widget.onRetry!();
      } else if (SyncStatusController.onRetryCallback != null) {
        await SyncStatusController.onRetryCallback!();
      }
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  void _showDetailsDialog(BuildContext context, ServerSyncState state) {
    if (widget.config.customDialogBuilder != null) {
      showDialog(
        context: context,
        builder: (ctx) => widget.config.customDialogBuilder!(
          ctx,
          state,
          _handleRetry,
        ),
      );
      return;
    }

    final theme = Theme.of(context);
    final isServerPaused = state == ServerSyncState.serverPaused;
    final isAuthExpired = state == ServerSyncState.authExpired;

    final String title;
    final String explanation;
    final String? tip;
    final IconData icon;
    final Color iconColor;

    if (isServerPaused) {
      title = widget.config.serverPausedTitle;
      explanation = widget.config.serverPausedExplanation;
      tip = widget.config.serverPausedResolutionTip;
      icon = Icons.cloud_off_rounded;
      iconColor = const Color(0xFFD97706);
    } else if (isAuthExpired) {
      title = widget.config.authExpiredTitle;
      explanation = widget.config.authExpiredExplanation;
      tip = null;
      icon = Icons.lock_clock_rounded;
      iconColor = const Color(0xFFDC2626);
    } else {
      title = widget.config.offlineTitle;
      explanation = widget.config.offlineExplanation;
      tip = null;
      icon = Icons.wifi_off_rounded;
      iconColor = const Color(0xFF64748B);
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.config.localDataSafetyNote,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  explanation,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                if (tip != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Resolution:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleRetry();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry Connection'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final shouldShow = _visibleState != null && !_isDismissedForCurrentState;
    final isTop = widget.position == SyncBannerPosition.top;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      offset: shouldShow
          ? Offset.zero
          : (isTop ? const Offset(0, -1.2) : const Offset(0, 1.2)),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: shouldShow ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: !shouldShow,
          child: SafeArea(
            top: isTop,
            bottom: !isTop,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: _buildBannerCard(context, _renderedState),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCard(BuildContext context, ServerSyncState state) {
    List<Color> gradientColors;
    IconData icon;
    String title;
    String subtitle;
    bool showRetry = true;

    switch (state) {
      case ServerSyncState.serverPaused:
        gradientColors = widget.config.serverPausedGradient ??
            const [Color(0xFFB45309), Color(0xFFD97706)];
        icon = Icons.cloud_off_rounded;
        title = widget.config.serverPausedTitle;
        subtitle = widget.config.serverPausedSubtitle;
        break;

      case ServerSyncState.authExpired:
        gradientColors = widget.config.authExpiredGradient ??
            const [Color(0xFF991B1B), Color(0xFFDC2626)];
        icon = Icons.lock_clock_rounded;
        title = widget.config.authExpiredTitle;
        subtitle = widget.config.authExpiredSubtitle;
        break;

      case ServerSyncState.offline:
        gradientColors = widget.config.offlineGradient ??
            const [Color(0xFF334155), Color(0xFF475569)];
        icon = Icons.wifi_off_rounded;
        title = widget.config.offlineTitle;
        subtitle = widget.config.offlineSubtitle;
        break;

      case ServerSyncState.restored:
        gradientColors = widget.config.restoredGradient ??
            const [Color(0xFF047857), Color(0xFF10B981)];
        icon = Icons.cloud_done_rounded;
        title = widget.config.restoredTitle;
        subtitle = widget.config.restoredSubtitle;
        showRetry = false;
        break;

      case ServerSyncState.synced:
      case ServerSyncState.syncing:
        return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: InkWell(
                onTap: widget.showDetailsDialog
                    ? () => _showDetailsDialog(context, state)
                    : null,
                borderRadius: BorderRadius.circular(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.showDetailsDialog) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.help_outline_rounded,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 13,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            if (showRetry) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: _isRetrying ? null : _handleRetry,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isRetrying
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Retry',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],

            if (widget.dismissible) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  setState(() => _isDismissedForCurrentState = true);
                  widget.onDismissed?.call();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
