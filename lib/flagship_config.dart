import 'package:flagship/decision/api_manager.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:http/http.dart' as http;
import "package:flagship/api/service.dart";

import 'flagship.dart';

// Time out 2 seconds
const TIMEOUT = 2000;

typedef StatusListner = void Function(Status newStatus)?;

class FlagshipConfig {
  // Mode
  Mode decisionMode = Mode.DECISION_API;
  // Timeout
  int timeout = TIMEOUT;
  // Decision Manager
  DecisionManager decisionManager = ApiManager(Service(http.Client()));
  // LogManager
  late LogManager logManager;
  // Status listner
  StatusListner statusListner;

  FlagshipConfig(
      {this.timeout = TIMEOUT,
      this.statusListner,
      Level logLevel = Level.ALL,
      bool activeLog = true}) {
    // Set the log Manager
    this.logManager = LogManager(level: logLevel, enabledLog: activeLog);
    // Log the timeout value in ms
    Flagship.logger(Level.ALL, "Flagship The timeout is : $timeout ms");
  }

  FlagshipConfig.defaultMode(
      {this.timeout: TIMEOUT, this.decisionMode = Mode.DECISION_API}) {
    // Log manager
    this.logManager = LogManager(enabledLog: true, level: Level.ALL);
    // Status listner null
    this.statusListner = null;
  }

  FlagshipConfig.withStatusListner(
      {this.timeout = TIMEOUT,
      required this.statusListner,
      Level logLevel = Level.ALL,
      bool activeLog = true}) {
    this.logManager = LogManager(level: logLevel, enabledLog: activeLog);
    Flagship.logger(Level.ALL, "Flagship The timeout is : $timeout ms");
  }
}
