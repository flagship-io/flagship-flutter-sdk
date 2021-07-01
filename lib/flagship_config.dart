import 'package:flagship/decision/api_manager.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';

import 'flagship.dart';

// Time out 2 seconds
const TIMEOUT = 2000;

class FlagshipConfig {
  // Mode
  Mode decisionMode = Mode.DECISION_API;
  // Timeout
  int timeout = TIMEOUT;
  // Decision Manager
  DecisionManager decisionManager = ApiManager();
  // LogManager
  late LogManager logManger;

  FlagshipConfig(this.timeout,
      {Level logLevel = Level.ALL, bool isEnableLog = true}) {
    this.logManger = LogManager(level: logLevel, enableLog: isEnableLog);

    Flagship.logger(Level.ALL, "Flagship The timeout is : $timeout ms");
  }

  FlagshipConfig.defaultMode(
      {this.timeout: TIMEOUT, this.decisionMode = Mode.DECISION_API}) {
    this.logManger = LogManager(enableLog: true, level: Level.ALL);
  }
}
