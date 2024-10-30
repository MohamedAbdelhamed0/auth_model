import 'package:flutter/foundation.dart';

class Log {
  // ANSI color codes
  static const _reset = '\x1B[0m';
  static const _red = '\x1B[31m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _blue = '\x1B[34m';

  // Log methods with emojis and colors
  static void success(String message) {
    if (kDebugMode) {
      print('$_green✅ $message$_reset');
    }
  }

  static void error(String message) {
    if (kDebugMode) {
      print('$_red❌ $message$_reset');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      print('$_yellow⚠️ $message$_reset');
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      print('$_blueℹ️ $message$_reset');
    }
  }

  static void debug(String message) {
    if (kDebugMode) {
      print('$_blue🐛 $message$_reset');
    }
  }
}
