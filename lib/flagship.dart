library flagship;

import 'package:flagship/flagship_config.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flagship/visitor.dart';

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

class Flagship {
  // environement id (provided by flagship)
  String? envId;

  // Api key (provided by flagship)
  String? apiKey;

  // Default configuration DECISION_API
  static FlagshipConfig _configuration = FlagshipConfig.defaultMode();

  // Local visitor , see the startClient function
  Visitor? currentVisitor;

  // internal Singelton
  static final Flagship _singleton = Flagship._internal();

  factory Flagship.sharedInstance() {
    return _singleton;
  }

  Flagship._internal() {
    /// implement later
    print("internal init");
  }

  /// Start Sdk
  ///
  /// envId : environement id (provided by flagship)
  /// apiKey: Api key (provided by flagship)
  static start(String envId, String apiKey, {FlagshipConfig? config}) {
    _singleton.apiKey = apiKey;
    _singleton.envId = envId;

    if (config != null) {
      Flagship._configuration = config;
    }

    Flagship.logger(Level.INFO, "Start sdk  $envId  and  $apiKey");
  }

  /// Start visitor
  ///
  /// visitorId : Id for the visitor
  /// context : Map that represent visitor's attribut  {"isVip":true}
  static Visitor newVisitor(String visitorId, Map<String, Object> context) {
    return Visitor(_configuration, visitorId, context);
  }

  /// Set the current visitor singleton
  static setCurrentVisitor(Visitor visitor) {
    _singleton.currentVisitor = visitor;
  }

  /// Return the current visitor
  static Visitor? getCurrentVisitor() {
    return _singleton.currentVisitor;
  }

  FlagshipConfig? getConfiguration() {
    return _singleton.currentVisitor?.config;
  }

  static void enableLog(bool isLogEnabled) {
    LogManager.logEnabled = isLogEnabled;
  }

  // Display logs in debug console
  static void logger(Level level, String message) {
    Flagship._configuration.logManger.printLog(level, message);
  }

  static void setLoggerLevel(Level newLevel) {
    LogManager.level = newLevel;
  }
}
