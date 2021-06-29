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

  static bool logEnabled = true;

  // Constructor
  LogManager({Level level = Level.ALL, bool enableLog = true}) {
    // Update the logger
    LogManager.logEnabled = enableLog;
    // Update level
    LogManager.level = level;
  }

  void printLog(Level pLevel, dynamic message) {
    if (LogManager.logEnabled) {
      if (_allowDisplay(pLevel)) {
        print(message);
      }
    }
  }

  // Check if we can display the message
  bool _allowDisplay(Level pLevel) {
    return (pLevel.index <= LogManager.level.index);
  }
}
