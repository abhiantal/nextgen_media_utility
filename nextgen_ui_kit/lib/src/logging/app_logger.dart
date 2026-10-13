import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Highly customizable developer logger providing color-coded terminal outputs,
/// stack traces, emoji indicators, and structured tagging.
class AppLogger {
  static Logger? _instance;
  static Level _defaultLevel = kDebugMode ? Level.debug : Level.error;

  /// Customizes the global logger configuration.
  static void init({
    Level? level,
    LogPrinter? printer,
    LogOutput? output,
    LogFilter? filter,
  }) {
    if (level != null) _defaultLevel = level;
    _instance = Logger(
      level: _defaultLevel,
      printer: printer ??
          PrettyPrinter(
            methodCount: 2,
            errorMethodCount: 8,
            lineLength: 100,
            colors: true,
            printEmojis: true,
            dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
          ),
      output: output,
      filter: filter,
    );
  }

  /// The active [Logger] instance.
  static Logger get instance {
    if (_instance == null) {
      init();
    }
    return _instance!;
  }

  static String _formatMessage(dynamic message, String? tag) {
    if (tag != null && tag.isNotEmpty) {
      return '[$tag] $message';
    }
    return '$message';
  }

  /// Log debug messages for development diagnosis.
  static void d(
    dynamic message, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    instance.d(
      _formatMessage(message, tag),
      time: time ?? DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log informational application messages.
  static void i(
    dynamic message, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    instance.i(
      _formatMessage(message, tag),
      time: time ?? DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log warning messages to flag unexpected runtime events.
  static void w(
    dynamic message, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    instance.w(
      _formatMessage(message, tag),
      time: time ?? DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log errors with optional error object and stack trace.
  static void e(
    dynamic message, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    instance.e(
      _formatMessage(message, tag),
      time: time ?? DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log verbose trace messages for fine-grained debugging.
  static void t(
    dynamic message, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    instance.t(
      _formatMessage(message, tag),
      time: time ?? DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log fatal crashes or unrecoverable critical failures.
  static void f(
    dynamic message, {
    String? tag,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    instance.f(
      _formatMessage(message, tag),
      time: time ?? DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Global convenience function to log debug messages.
void logD(
  dynamic message, {
  String? tag,
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
}) {
  AppLogger.d(message, tag: tag, time: time, error: error, stackTrace: stackTrace);
}

/// Global convenience function to log info messages.
void logI(
  dynamic message, {
  String? tag,
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
}) {
  AppLogger.i(message, tag: tag, time: time, error: error, stackTrace: stackTrace);
}

/// Global convenience function to log warning messages.
void logW(
  dynamic message, {
  String? tag,
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
}) {
  AppLogger.w(message, tag: tag, time: time, error: error, stackTrace: stackTrace);
}

/// Global convenience function to log error messages.
void logE(
  dynamic message, {
  String? tag,
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
}) {
  AppLogger.e(message, tag: tag, time: time, error: error, stackTrace: stackTrace);
}

/// Global convenience function to log trace messages.
void logT(
  dynamic message, {
  String? tag,
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
}) {
  AppLogger.t(message, tag: tag, time: time, error: error, stackTrace: stackTrace);
}

/// Global convenience function to log fatal messages.
void logF(
  dynamic message, {
  String? tag,
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
}) {
  AppLogger.f(message, tag: tag, time: time, error: error, stackTrace: stackTrace);
}

/// Extension methods for quick logging from any Dart Object.
extension LoggerExtension on Object {
  void logError([Object? error, StackTrace? stackTrace, String? tag]) {
    AppLogger.e(toString(), error: error, stackTrace: stackTrace, tag: tag);
  }

  void logWarning([Object? error, StackTrace? stackTrace, String? tag]) {
    AppLogger.w(toString(), error: error, stackTrace: stackTrace, tag: tag);
  }

  void logInfo([Object? error, StackTrace? stackTrace, String? tag]) {
    AppLogger.i(toString(), error: error, stackTrace: stackTrace, tag: tag);
  }

  void logDebug([Object? error, StackTrace? stackTrace, String? tag]) {
    AppLogger.d(toString(), error: error, stackTrace: stackTrace, tag: tag);
  }
}
