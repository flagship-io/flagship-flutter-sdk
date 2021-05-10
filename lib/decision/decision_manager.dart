import 'package:flagship/decision/interface_decision_manager.dart';
import 'package:flagship/model/campaign.dart';
import 'package:flagship/model/modification.dart';

abstract class DecisionManager extends IDecisionManager {
  //panic mode
  bool _panic = false;

  DecisionManager();

  Map<String, Modification> getModifications(List<Campaign> campaigns) {
    print(
        "#################### Get getModificationsBis #########################");

    Map<String, Modification> result = new Map<String, Modification>();

    for (var itemCampaign in campaigns) {
      result.addAll(itemCampaign.getAllModificationBis());
    }
    return result;
  }

  bool isPanic() {
    return _panic;
  }
}
