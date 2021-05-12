import 'package:flagship/decision/api_manager.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/utils/constants.dart';

class FlagshipConfig {
  FSMode decisionMode = FSMode.DECISION_API;

  int timeout = 2000; // 2 seconds

  DecisionManager decisionManager = ApiManager();

  FlagshipConfig.defaultMode(
      {this.timeout: 2, this.decisionMode = FSMode.DECISION_API});
}
