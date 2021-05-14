library flagship;

import 'package:flagship/flagship_config.dart';
import 'package:flagship/visitor.dart';

enum FSStatus {
  Ready,
  Not_Ready,
  Disabled,
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
  static start(String envId, String apiKey) {
    _singleton.apiKey = apiKey;
    _singleton.envId = envId;
    print(
        " ############# Start sdk  $envId  and  $apiKey   ######################");
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

  FlagshipConfig getConfiguration() {
    return _configuration;
  }
}
