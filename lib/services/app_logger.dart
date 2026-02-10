import 'package:logger/logger.dart';

/// Production-grade logging service
///
/// Provides structured logging with different levels for debugging,
/// monitoring, and error tracking in production environments.
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;

  late final Logger _logger;
  bool _isProduction = false;

  AppLogger._internal() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      filter: _ProductionFilter(),
    );
  }

  /// Initialize logger with production mode setting
  void init({bool isProduction = false}) {
    _isProduction = isProduction;
  }

  /// Log debug information (not shown in production)
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isProduction) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log general information
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warnings
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log errors
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal errors
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log database operations
  void database(String operation, {String? table, String? details}) {
    debug('DB [$operation] ${table ?? ''}: ${details ?? ''}');
  }

  /// Log security events
  void security(String event, {Map<String, dynamic>? metadata}) {
    info('SECURITY [$event] ${metadata?.toString() ?? ''}');
  }

  /// Log content moderation events
  void moderation(String action, {String? reason, String? contentPreview}) {
    info('MODERATION [$action] Reason: ${reason ?? 'N/A'}');
  }
}

/// Custom filter for production environments
class _ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // In production, only log warnings and above
    // In debug, log everything
    return true; // Filter based on level in individual methods
  }
}
