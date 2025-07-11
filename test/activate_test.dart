import 'package:flagship/api/service.dart';
import 'package:flagship/cache/default_cache.dart';
import 'package:flagship/decision/api_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flagship/model/exposed_flag.dart';
import 'package:flagship/model/flag.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/model/visitor_exposed.dart';
import 'package:flagship/tracking/tracking_manager.dart';
import 'package:flagship/tracking/tracking_manager_config.dart';
import 'package:flagship/tracking/tracking_manager_continuous_strategies.dart';
import 'package:flagship/visitor/strategy/default_strategy.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flagship/hits/activate.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_path_provider_platform.dart';
import 'test_tools.dart';
import 'package:http/http.dart' as http;
import 'service_test.mocks.dart';

@GenerateMocks([Service])
void main() {
  MockService fakeService = MockService();

  MockService fakeTrackingService = MockService();

  TrackingManager fakeTrackingMgr = TrackingManageContinuousStrategy(
      fakeTrackingService, TrackingManagerConfig(), DefaultCacheHitImp());

  ApiManager fakeApi = ApiManager(fakeService);
  PathProviderPlatform.instance = FakePathProviderPlatform();
  ToolsTest.sqfliteTestInit();
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

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
      if (v.id == "expoVisitor") {
        expect(f.metadata().campaignId, "campaignId");
        expect(v.id, "expoVisitor");
        expect(f.alreadyActivatedCampaign, false);
      }
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
      if (v.id == "expoVisitorObj") {
        expect(f.metadata().campaignId, "campaignId");
        expect(v.id, "expoVisitorObj");
      }
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

  test(' Test is Deduplicated', () async {
    /// prepare response
    when(fakeTrackingService.sendHttpRequest(RequestType.Post,
            'https://decision.flagship.io/v2/activate', any, any,
            timeoutMs: TIMEOUT_REQUEST))
        .thenAnswer((_) async {
      return http.Response("mock", 200);
    });

    var testConfig = ConfigBuilder().withOnVisitorExposed((v, f) {
      if (v.id == "testV") {
        expect(f.metadata().campaignId, "campaignId");
        expect(v.id, "expoVisitorObj");
        expect(f.alreadyActivatedCampaign, true);
      }
    }).build();

    Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey", config: testConfig);

    var testV = Flagship.newVisitor(visitorId: "testV", hasConsented: true)
        .withContext({"expoKey": "expoVal"}).build();

    testV.trackingManager = fakeTrackingMgr;
    testV.config.decisionManager = fakeApi;

    // Create a default strategy
    var dfltStrategy = DefaultStrategy(testV);

    Modification itemModif = Modification(
        "key1",
        "campaignId",
        "campName",
        "variationGroupId",
        "vargName",
        "variationId",
        "varName",
        true,
        "ab",
        "slug",
        12);

    dfltStrategy.activateFlag(itemModif, isDuplicated: true);
    var tr = dfltStrategy.visitor.trackingManager
        as TrackingManageContinuousStrategy;
    expect(tr.activatePool.fsQueue.length, 0);
    dfltStrategy.onExposure(itemModif);
  });
}
