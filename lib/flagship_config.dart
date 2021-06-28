import 'package:flagship/decision/api_manager.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/flagship_filter.dart';
import 'package:flagship/utils/logger/log_manager.dart';

class FlagshipConfig {
  // Mode
  Mode decisionMode = Mode.DECISION_API;
  // Timeout
  int timeout = 2000; // 2 seconds
  // Decision Manager
  DecisionManager decisionManager = ApiManager();
  // LogManager
  LogManager logManger =
      LogManager(filter: FlagshipFilterDebug(), level: Level.ALL);

  FlagshipConfig(this.timeout,
      {Level logLevel = Level.ALL, bool isEnableLog = true}) {
    this.logManger = LogManager(level: logLevel, enableLog: isEnableLog);
  }

  FlagshipConfig.defaultMode(
      {this.timeout: 2000, this.decisionMode = Mode.DECISION_API});
}
