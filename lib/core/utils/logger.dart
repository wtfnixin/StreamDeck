import 'dart:developer' as developer;

class AppLogger {
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    print('[DevDeck.Debug] $message${error != null ? ' | Error: $error' : ''}');
    developer.log(
      message,
      name: 'DevDeck.Debug',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void info(String message) {
    print('[DevDeck.Info] $message');
    developer.log(
      message,
      name: 'DevDeck.Info',
    );
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    print('[DevDeck.Warning] $message${error != null ? ' | Error: $error' : ''}');
    developer.log(
      message,
      name: 'DevDeck.Warning',
      error: error,
      stackTrace: stackTrace,
      level: 900,
    );
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    print('[DevDeck.Error] $message${error != null ? ' | Error: $error' : ''}');
    developer.log(
      message,
      name: 'DevDeck.Error',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
