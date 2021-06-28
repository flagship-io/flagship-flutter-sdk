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
  // Default level
  static Level level = Level.ALL;

  FlagshipFilter _filter;

  static bool logEnabled = true;

  // Constructor
  LogManager({FlagshipFilter? filter, Level? level, bool enableLog = true})
      : _filter = filter ?? FlagshipFilterDebug() {
    LogManager.logEnabled = enableLog;
  }

  void printLog(Level pLevel, dynamic message) {
    if (LogManager.logEnabled) {
      if (_filter.allowDisplay(pLevel)) {
        print(message);
      }
    }
  }

  // void enableLog(bool enbale) {
  //   this.logEnabled = enbale;
  // }
}
