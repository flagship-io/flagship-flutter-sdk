import 'package:flagship/model/modification.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flagship/hits/activate.dart';

void main() {
  test("Activate with Modification object ", () {
    Modification fakeModif = Modification(
        "key",
        "campaignId",
        "campName",
        "variationGroupId",
        "varGName",
        "variationId",
        "varName",
        true,
        "ab",
        "slug",
        12);

    Activate activateTest =
        Activate(fakeModif, "visitorId", "anonym1", "envId");
    var fakeJson = activateTest.toJson();
    expect(fakeJson["vaid"], "variationId");
    expect(fakeJson["caid"], "variationGroupId");
    expect(fakeJson["vid"], "visitorId");
    expect(fakeJson["cid"], "envId");
    expect(fakeJson["aid"], "anonym1");
  });
}

//  (POST https://decision.flagship.io/v2/activate)

// "{"vaid":"cd7rn3egmgl02tuj7r1g","caid":"cd7rn3egmgl02tuj7r10","vid":"userPoolManager_342","cid":"bkk9glocmjcg0vtmdlng"}"

