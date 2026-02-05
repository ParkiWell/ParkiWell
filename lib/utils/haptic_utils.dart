import 'package:flutter/services.dart';

/// Haptic feedback utility for consistent haptic feedback throughout the app
class HapticUtils {
  /// Light impact - for small UI interactions like toggles, switches
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }
  
  /// Medium impact - for button presses, selections
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }
  
  /// Heavy impact - for important actions, confirmations
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }
  
  /// Selection click - for tab changes, item selections
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }
  
  /// Vibrate - for errors, warnings
  static void vibrate() {
    HapticFeedback.vibrate();
  }
  
  /// Success feedback - light double tap feeling
  static void success() {
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.lightImpact();
    });
  }
  
  /// Error feedback - heavy vibration
  static void error() {
    HapticFeedback.heavyImpact();
  }
  
  /// Button tap feedback
  static void buttonTap() {
    HapticFeedback.mediumImpact();
  }
  
  /// Card tap feedback
  static void cardTap() {
    HapticFeedback.lightImpact();
  }
  
  /// Navigation feedback
  static void navigation() {
    HapticFeedback.selectionClick();
  }
}
