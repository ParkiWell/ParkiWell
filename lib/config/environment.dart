// Environment configuration for the app.
//
// Build with different environments using:
// - Development: flutter run
// - Staging: flutter run --dart-define=ENVIRONMENT=staging
// - Production: flutter run --dart-define=ENVIRONMENT=production

enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static Environment get current {
    switch (_environment) {
      case 'production':
        return Environment.production;
      case 'staging':
        return Environment.staging;
      default:
        return Environment.development;
    }
  }

  static bool get isDevelopment => current == Environment.development;
  static bool get isStaging => current == Environment.staging;
  static bool get isProduction => current == Environment.production;

  static String get name {
    switch (current) {
      case Environment.production:
        return 'Production';
      case Environment.staging:
        return 'Staging';
      case Environment.development:
        return 'Development';
    }
  }

  /// Enable debug features only in non-production environments
  static bool get enableDebugFeatures => !isProduction;

  /// Enable analytics only in production
  static bool get enableAnalytics => isProduction;

  /// Enable crash reporting in staging and production
  static bool get enableCrashReporting => isStaging || isProduction;

  /// Show environment banner in non-production builds
  static bool get showEnvironmentBanner => const bool.fromEnvironment(
        'SHOW_ENV_BANNER',
        defaultValue: false,
      );

  /// Log level based on environment
  static LogLevel get logLevel {
    switch (current) {
      case Environment.production:
        return LogLevel.error;
      case Environment.staging:
        return LogLevel.warning;
      case Environment.development:
        return LogLevel.debug;
    }
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
}
