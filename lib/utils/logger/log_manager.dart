import '../logger/flagship_filter.dart';

enum Level {
  NONE,
  /*
         * EXCEPTIONS = 1: Only caught exception will be logged.
         */
  EXCEPTIONS,
  /*
         * ERROR = 2: Only errors and above will be logged.
         */
  ERROR,
  /*
         * WARNING = 3: Only warnings and above will be logged.
         */
  WARNING,
  /*
         * DEBUG = 4: Only debug logs and above will be logged.
         */
  DEBUG,
  /*
         * INFO = 5: Only info logs and above will be logged.
         */
  INFO,
  /*
         * ALL = 6: All logs will be logged.
         */
  ALL
}

class LogManager {
  // Current level
  static Level _level = Level.ALL;

  final FlagshipFilter _filter;

  bool _enableLogs = true;

  // constructor
  LogManager({
    FlagshipFilter? filter,
    Level? level,
  }) : _filter = filter ?? FlagshipFilterDebug() {
    _filter.level = level ?? LogManager._level;
  }

  /// Log info message
  void i(dynamic message) {
    log(Level.INFO, message);
  }

  /// Log a message at level [Level.ALL].
  void a(dynamic message) {
    log(Level.ALL, message);
  }

  /// Log a message at level [Level.debug].
  void d(dynamic message) {
    log(Level.DEBUG, message);
  }

  void e(dynamic message) {
    log(Level.ERROR, message);
  }

  void log(Level pLevel, dynamic message) {
    if (_enableLogs) {
      if (_filter.allowDisplay(pLevel)) {
        print(message);
      }
    }
  }

  void close() {
    _enableLogs = false;
  }
}
