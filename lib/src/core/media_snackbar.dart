// ============================================================
// FILE: lib/src/core/media_snackbar.dart
// NextGen Media Utility - Modular Snackbar Helper
// ============================================================

import 'package:flutter/material.dart';
import 'media_logger.dart';

class AppSnackbar {
  static GlobalKey<ScaffoldMessengerState>? messengerKey;

  static void show(
    String message, {
    String? description,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final text = description != null && description.isNotEmpty
        ? '$message: $description'
        : message;

    final messenger = messengerKey?.currentState;
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: duration,
        ),
      );
    } else {
      if (isError) {
        MediaLogger.error(text);
      } else {
        MediaLogger.info(text);
      }
    }
  }

  static void success(
    String message, {
    String? description,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(message, description: description, isError: false, duration: duration);
  }

  static void error(
    String message, {
    String? description,
    dynamic error,
    dynamic stackTrace,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(message, description: description, isError: true, duration: duration);
    if (error != null) {
      MediaLogger.error('$message: $error', error, stackTrace is StackTrace ? stackTrace : null);
    }
  }

  static void warning(
    String message, {
    String? description,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(message, description: description, isError: true, duration: duration);
  }

  static void showError(String message, {String? description}) =>
      error(message, description: description);
  static void showInfo(String message, {String? description}) =>
      show(message, description: description);
  static void showWarning(String message, {String? description}) =>
      warning(message, description: description);
}

typedef AppSnackBar = AppSnackbar;

class SnackbarService {
  void show(String message, {String? description, bool isError = false}) {
    AppSnackbar.show(message, description: description, isError: isError);
  }

  void showError(String message, {String? description}) =>
      AppSnackbar.error(message, description: description);
  void showInfo(String message, {String? description}) =>
      AppSnackbar.show(message, description: description);
  void showSuccess(String message, {String? description}) =>
      AppSnackbar.success(message, description: description);
  void showWarning(String message, {String? description}) =>
      AppSnackbar.warning(message, description: description);

  void success(String message, {String? description}) =>
      showSuccess(message, description: description);
  void error(String message, {String? description}) =>
      showError(message, description: description);
  void warning(String message, {String? description}) =>
      showWarning(message, description: description);
}

final snackbarService = SnackbarService();
