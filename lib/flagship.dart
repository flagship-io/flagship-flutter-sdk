library flagship;

import 'package:flagship/flagship_config.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/device_tools.dart';
import 'package:flagship/utils/flagship_tools.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flagship/visitor.dart';
import 'flagship_delegate.dart';

enum Status {
  // Flagship SDK has not been started or initialized successfully.
  NOT_INITIALIZED,
  // Flagship SDK is ready but is running in Panic mode: All features are disabled except the one which refresh this status.
  PANIC_ON,
  // Flagship SDK is ready to use.
  READY
}

class Flagship with FlagshipDelegate {
  // environement id (provided by flagship)
  String? envId;

  // Api key (provided by flagship)
  String? apiKey;

  // Default configuration DECISION_API
  static FlagshipConfig _configuration = ConfigBuilder().build();

  // Local visitor , see the startClient function
  Visitor? currentVisitor;

  Status _status = Status.NOT_INITIALIZED;

  // internal Singelton
  static final Flagship _singleton = Flagship._internal();

  factory Flagship.sharedInstance() {
    return _singleton;
  }

  Flagship._internal() {
    /// implement later
  }

  // Start Sdk
  //
  // envId : environement id (provided by flagship)
  // apiKey: Api key (provided by flagship)
  static start(String envId, String apiKey, {FlagshipConfig? config}) async {
    _singleton._status = Status.NOT_INITIALIZED;
    await FSDevice.loadDeviceInfo();
    if (FlagshipTools.chekcXidEnvironment(envId)) {
      _singleton.apiKey = apiKey;
      _singleton.envId = envId;
      if (config != null) {
        Flagship._configuration = config;
      }
      if (_configuration.decisionMode == Mode.BUCKETING) {
        Flagship._configuration.decisionManager.startPolling();
      }
      _singleton.onUpdateState(Status.READY);
      Flagship.logger(Level.INFO, STARTED);
    } else {
      _singleton.onUpdateState(Status.NOT_INITIALIZED);
      Flagship.logger(Level.ERROR, (INITIALIZATION_PARAM_ERROR));
    }
  }

  /// Create new visitor
  static VisitorBuilder newVisitor(String visitorId) {
    return VisitorBuilder(visitorId);
  }

  // Set the current visitor singleton
  static setCurrentVisitor(Visitor visitor) {
    _singleton.currentVisitor = visitor;
  }

  // Return the current visitor
  static Visitor? getCurrentVisitor() {
    return _singleton.currentVisitor;
  }

  // Get the current configuration
  FlagshipConfig? getConfiguration() {
    return Flagship._configuration;
  }

  // Active or deactivate logger
  //
  // isLogEnabled : True to activated logger , otherwise false to deactivate
  static void enableLog(bool isLogEnabled) {
    LogManager.logEnabled = isLogEnabled;
  }

  // Display message logger
  //
  // level : Level of details for logs
  // message : Message to display
  static void logger(Level level, String message, {bool isJsonString = false}) {
    Flagship._configuration.logManager.printLog(level, message, isJsonString);
  }

  // Set the level for logger
  // newLevel : Level of details for logs
  static void setLoggerLevel(Level newLevel) {
    LogManager.level = newLevel;
  }

  // Get Status
  static Status getStatus() {
    return Flagship._singleton._status;
  }

  @override
  void onUpdateState(Status newStatus) {
    // If the status hasn't changed, no need to update and trigger the callback
    if (newStatus == _singleton._status) {
      return;
    }
    _singleton._status = newStatus;

    // Trigger the callback
    // Check if the callback if not null before trigger it
    if (Flagship._configuration.statusListener != null) {
      Flagship._configuration.statusListener!(newStatus);
    }
  }
}
