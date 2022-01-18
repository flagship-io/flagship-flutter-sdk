library flagship;

import 'package:flagship/flagship_config.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/flagship_tools.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flagship/visitor.dart';

import 'flagship_delegate.dart';

enum Status {
  // Flagship SDK has not been started or initialized successfully.
  NOT_INITIALIZED,
  // Flagship SDK is starting.
  //STARTING,
  // Flagship SDK has been started successfully but is still polling campaigns.
  //POLLING,
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
  static FlagshipConfig _configuration = FlagshipConfig.defaultMode();

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

  /// Start Sdk
  ///
  /// envId : environement id (provided by flagship)
  /// apiKey: Api key (provided by flagship)
  static start(String envId, String apiKey, {FlagshipConfig? config}) {
    if (FlagshipTools.chekcXidEnvironment(envId)) {
      _singleton.apiKey = apiKey;
      _singleton.envId = envId;
      _singleton._status = Status.READY;
      if (config != null) {
        Flagship._configuration = config;
      }
      Flagship.logger(Level.INFO, STARTED);
    } else {
      Flagship.logger(Level.ERROR, (INITIALIZATION_PARAM_ERROR));
    }
  }

  /// Start visitor
  ///
  /// visitorId : Id for the visitor
  /// context : Map that represent visitor's attribut  {"isVip":true}
  static Visitor newVisitor(String visitorId, Map<String, Object> context,
      {bool hasConsented = true}) {
    return Visitor(_configuration, visitorId, context,
        hasConsented: hasConsented);
  }

  /// Set the current visitor singleton
  static setCurrentVisitor(Visitor visitor) {
    _singleton.currentVisitor = visitor;
  }

  /// Return the current visitor
  static Visitor? getCurrentVisitor() {
    return _singleton.currentVisitor;
  }

  /// Get the current configuration
  FlagshipConfig? getConfiguration() {
    return Flagship._configuration;
  }

  ///Active or deactivate logger
  ///
  /// isLogEnabled : True to activated logger , otherwise false to deactivate
  static void enableLog(bool isLogEnabled) {
    LogManager.logEnabled = isLogEnabled;
  }

  /// Display message logger
  ///
  /// level : Level of details for logs
  /// message : Message to display
  static void logger(Level level, String message, {bool isJsonString = false}) {
    Flagship._configuration.logManager.printLog(level, message, isJsonString);
  }

  /// Set the level for logger
  ///
  /// newLevel : Level of details for logs
  static void setLoggerLevel(Level newLevel) {
    LogManager.level = newLevel;
  }

  static Status getStatus() {
    return Flagship._singleton._status;
  }

  @override
  void onUpdateState(Status state) {
    _singleton._status = state;
  }
}
