// ============================================================
// FILE: lib/src/core/media_logger.dart
// NextGen Media Utility - Modular Diagnostic Logger
// ============================================================

import 'dart:developer' as developer;

class MediaLogger {
  static bool enableLogs = true;

  static void info(String message, [dynamic error]) {
    if (enableLogs) {
      developer.log('ℹ️ [NextGenMedia] $message', error: error);
    }
  }

  static void warning(String message, [dynamic error]) {
    if (enableLogs) {
      developer.log('⚠️ [NextGenMedia] $message', error: error);
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (enableLogs) {
      developer.log('❌ [NextGenMedia] $message', error: error, stackTrace: stackTrace);
    }
  }
}

// Convenience global shortcuts compatible with existing code
void logD(String message) => MediaLogger.info(message);
void logI(String message) => MediaLogger.info(message);
void logW(String message) => MediaLogger.warning(message);
void logE(
  String message, [
  dynamic error,
  StackTrace? stackTrace,
]) =>
    MediaLogger.error(message, error, stackTrace);
