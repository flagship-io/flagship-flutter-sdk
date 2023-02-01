import 'package:flagship/hits/hit.dart';
import 'package:flagship/model/modification.dart';

class Activate extends BaseHit {
  // final String campaignId;
  // final String variationId;
  // final String variationGroupId;
  // final bool isReference;
  Modification? modification;
  //final String visitorId;
  String? anonymousId;

  late String envId;

  Activate(this.modification, String visitorId, this.anonymousId, this.envId)
      : super() {
    this.visitorId = visitorId;
    type = HitCategory.ACTIVATION;
  }

// This is used to read an activate from the cache
  Activate.fromMap(String oldId, Map body) {
    // Set the type
    this.type = HitCategory.ACTIVATION;
    // Set the visitor
    super.visitorId = body["vid"] ?? "";
    // Set the aid if exist
    if (body["aid"] != null) {
      this.anonymousId = body["aid"];
    }
    // Set the old id
    this.id = oldId;
    // Set the client Id
    this.envId = body["cid"] ?? "";

    // Create the modification object to set the "caid" & "vaid"
    if ((body["caid"] != null) && (body["vaid"] != null)) {
      modification = Modification("", "", body["caid"], body["vaid"], false,
          "campaignType", "slug", null);
    }
  }

  Map<String, Object> toJson() {
    Map<String, String> result;

    result = {
      "vaid": modification?.variationId ?? "",
      "caid": modification?.variationGroupId ?? "",
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
    // Create with basic information
    var customBody = new Map<String, Object>();
    customBody.addEntries(this.toJson().entries);
    // Add qt and type entries
    customBody.addAll({"t": typeOfEvent, "qt": qt.second});
    return customBody;
  }

  @override
  bool isValid() {
    return true;
  }

  @override
  bool isLessThan4H() {
    return (qt.difference(DateTime.now()).inHours <= 4);
    //return true; // see later
  }
}
