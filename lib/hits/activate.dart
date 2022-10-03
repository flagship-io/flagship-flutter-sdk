import 'package:flagship/model/modification.dart';

class Activate {
  // final String campaignId;
  // final String variationId;
  // final String variationGroupId;
  // final bool isReference;
  final Modification modification;
  final String visitorId;
  final String? anonymousId;

  final String envId;

  Activate(this.modification, this.visitorId, this.anonymousId, this.envId);

  Map<String, Object> toJson() {
    Map<String, String> result;

    result = {"vaid": modification.variationId, "caid": modification.variationGroupId, "vid": visitorId, "cid": envId};

    if (this.anonymousId != null) {
      result.addEntries({"aid": anonymousId ?? ""}.entries);
    }
    return result;
  }
}
