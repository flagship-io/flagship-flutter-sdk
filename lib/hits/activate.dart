import 'package:flagship/hits/hit.dart';
import 'package:flagship/model/modification.dart';

class Activate extends Hit {
  // final String campaignId;
  // final String variationId;
  // final String variationGroupId;
  // final bool isReference;
  final Modification modification;
  //final String visitorId;
  final String? anonymousId;

  final String envId;

  Activate(this.modification, String visitorId, this.anonymousId, this.envId)
      : super() {
    this.visitorId = visitorId;
  }

  Map<String, Object> toJson() {
    Map<String, String> result;

    result = {
      "vaid": modification.variationId,
      "caid": modification.variationGroupId,
      "vid": visitorId,
      "cid": envId
    };

    if (this.anonymousId != null) {
      result.addEntries({"aid": anonymousId ?? ""}.entries);
    }
    return result;
  }

  @override
  Map<String, Object> get bodyTrack {
    return toJson();
  }

  @override
  bool isValid() {
    return true;
  }

  @override
  bool isLessThan4H() {
    // return (qt.difference(DateTime.now()).inHours <= 4);
    return true; // see later
  }
}
