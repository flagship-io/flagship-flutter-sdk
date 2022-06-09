import 'package:flagship/decision/api_manager.dart';
import 'package:flagship/decision/bucketing_manager.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:http/http.dart' as http;
import "package:flagship/api/service.dart";

import 'flagship.dart';

// Time out 2 seconds
const TIMEOUT = 2000;

typedef StatusListener = void Function(Status newStatus)?;

class FlagshipConfig {
  // Mode
  Mode decisionMode; // = Mode.DECISION_API;
  // Timeout
  int timeout = TIMEOUT;
  // Decision Manager
  late DecisionManager decisionManager; // = ApiManager(Service(http.Client()));
  // LogManager
  late LogManager logManager;
  // Status listner
  StatusListener statusListener;

  FlagshipConfig(
      {this.timeout = TIMEOUT,
      this.decisionMode = Mode.DECISION_API,
      this.statusListener,
      Level logLevel = Level.ALL,
      bool activeLog = true}) {
    // Set the log Manager
    this.logManager = LogManager(level: logLevel, enabledLog: activeLog);
    // Log the timeout value in ms
    Flagship.logger(Level.ALL, "Flagship The timeout is : $timeout ms");

    decisionManager = (decisionMode == Mode.DECISION_API)
        ? ApiManager(Service(http.Client()))
        : BucketingManager(Service(http.Client()));
  }

  FlagshipConfig.defaultMode({this.timeout: TIMEOUT, this.decisionMode = Mode.DECISION_API}) {
    // Decisoin manager
    decisionManager = (decisionMode == Mode.DECISION_API)
        ? ApiManager(Service(http.Client()))
        : BucketingManager(Service(http.Client()));
    // Log manager
    this.logManager = LogManager(enabledLog: true, level: Level.ALL);
    // Status listner null
    this.statusListener = null;
  }

  FlagshipConfig.withStatusListener(
      {this.timeout = TIMEOUT,
      this.decisionMode = Mode.DECISION_API,
      required this.statusListener,
      Level logLevel = Level.ALL,
      bool activeLog = true}) {
    this.logManager = LogManager(level: logLevel, enabledLog: activeLog);
    Flagship.logger(Level.ALL, "Flagship The timeout is : $timeout ms");

    decisionManager = (decisionMode == Mode.DECISION_API)
        ? ApiManager(Service(http.Client()))
        : BucketingManager(Service(http.Client()));
  }
}
