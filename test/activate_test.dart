import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/model/exposed_flag.dart';
import 'package:flagship/model/flag.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/model/visitor_exposed.dart';
import 'package:flagship/visitor/strategy/default_strategy.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flagship/hits/activate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        Activate(fakeModif, "visitorId", "anonym1", "envId", null, null);
    var fakeJson = activateTest.toJson();
    expect(fakeJson["vaid"], "variationId");
    expect(fakeJson["caid"], "variationGroupId");
    expect(fakeJson["vid"], "visitorId");
    expect(fakeJson["cid"], "envId");
    expect(fakeJson["aid"], "anonym1");
  });

  test("OnExposureCallback", () {
    var expoConfig = ConfigBuilder().withOnVisitorExposed((v, f) {
      expect(f.metadata().campaignId, "campaignId");
      expect(v.id, "expoVisitor");
    }).build();
    Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey", config: expoConfig);
    var expoVisitor =
        Flagship.newVisitor(visitorId: "expoVisitor", hasConsented: true)
            .withContext({"expoKey": "expoVal"}).build();
    // Create a default strategy
    var dfltStrategy = DefaultStrategy(expoVisitor);

    // Create Modification
    var expoModif = Modification(
        "key",
        "campaignId",
        "campaignName",
        "variationGroupId",
        "variationGroupName",
        "variationId",
        "variationName",
        true,
        "AB",
        "slug",
        "value");
    // Trigger the callback
    dfltStrategy.onExposure(expoModif);
  });

  test("OnExposureObject", () {
    var expoConfig = ConfigBuilder().withOnVisitorExposed((v, f) {
      expect(f.metadata().campaignId, "campaignId");
      expect(v.id, "expoVisitorObj");
    }).build();
    Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey", config: expoConfig);
    var expoVisitorObj =
        Flagship.newVisitor(visitorId: "expoVisitorObj", hasConsented: true)
            .withContext({"expoKey": "expoVal"}).build();
    // Create a default strategy
    var dfltStrategy = DefaultStrategy(expoVisitorObj);

    // Create Modification
    var expoModif = Modification(
        "key",
        "campaignId",
        "campaignName",
        "variationGroupId",
        "variationGroupName",
        "variationId",
        "variationName",
        true,
        "AB",
        null,
        "value");
    // Trigger the callback
    dfltStrategy.onExposure(expoModif);

    // Check brut objs
    var vE = VisitorExposed("is", null, {});
    expect(vE.anonymousId, null);
    var eF = ExposedFlag("key", 12, 12, FlagMetadata.withMap({}));
    expect(eF.metadata().campaignId, "");
  });
}
