import 'dart:convert';

import 'package:flagship/api/service.dart';
import 'package:flagship/decision/api_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagshipContext/flagship_context.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flagship/model/flag.dart';
import 'package:flagship/model/visitor_flag.dart';
import 'package:flagship/tracking/tracking_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fake_path_provider_platform.dart';
import 'service_test.mocks.dart';
import 'test_tools.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

@GenerateMocks([Service])
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ToolsTest.sqfliteTestInit();
  SharedPreferences.setMockInitialValues({});

  Map<String, String> fsHeaders = {
    "x-api-key": "apiKey",
    "x-sdk-client": "flutter",
    "x-sdk-version": FlagshipVersion,
    "Content-type": "application/json"
  };

  MockService fakeService = MockService();
  ApiManager fakeApi = ApiManager(fakeService);

  String fakeResponse =
      await ToolsTest.readFile('test_resources/decisionApi.json') ?? "";
  when(fakeService.sendHttpRequest(
          RequestType.Post,
          'https://decision.flagship.io/v2/bkk9glocmjcg0vtmdlrr/campaigns/?exposeAllKeys=true&extras[]=accountSettings',
          fsHeaders,
          any,
          timeoutMs: TIMEOUT))
      .thenAnswer((_) async {
    return http.Response(fakeResponse, 200);
  });

  when(fakeService.sendHttpRequest(RequestType.Post,
          'https://decision.flagship.io/v2/activate', any, any,
          timeoutMs: 60000))
      .thenAnswer((_) async {
    return http.Response("fakeResponse", 200);
  });

  FlagshipConfig config = ConfigBuilder()
      .withTimeout(TIMEOUT)
      .withOnVisitorExposed((exposedUser, exposedFlag) {
    expect(exposedFlag.metadata().campaignId, "bsffhle242b2l3igq4dg");
    expect(exposedFlag.metadata().variationGroupId, "bsffhle242b2l3igq4egaa");
    expect(exposedFlag.metadata().variationId, "bsffhle242b2l3igq4f0");
  }).build();
  config.decisionManager = fakeApi;
  TrackingManager fakeTracking =
      TrackingManager(fakeService, config.trackingManagerConfig, null);

  await Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey", config: config);
  PathProviderPlatform.instance = FakePathProviderPlatform();
  var v1 =
      Flagship.newVisitor(visitorId: "flagVisitor", hasConsented: true).build();
  v1.config.decisionManager = fakeApi;

  test("Test Flag class", (() async {
    // PathProviderPlatform.instance = FakePathProviderPlatform();
    var v1 = Flagship.newVisitor(visitorId: "flagVisitor", hasConsented: true)
        .build();

    v1.trackingManager = fakeTracking;
    v1.fetchFlags().whenComplete(() async {
      expect(v1.getFlagSyncStatus(), FlagSyncStatus.FLAGS_FETCHED);
      // List of flags
      List<Map<String, dynamic>> listEntry = [
        // Correct Flag
        {
          "key": "specialChar",
          "dfltValue": "defaultValue",
          "expectedValue":
              "Ceci est un exemple avec des caractères spéciaux : é, à, ü, œ, ñ, ç…",
          "existingFlag": true,
          "shouldHaveMetadata": true
        },
        {
          "key": "key_A",
          "dfltValue": "defaultValue",
          "expectedValue": "val_A",
          "existingFlag": true,
          "shouldHaveMetadata": true
        },
        {
          "key": "key_B",
          "dfltValue": 2.14,
          "expectedValue": 3.14,
          "existingFlag": true,
          "shouldHaveMetadata": true
        },
        {
          "key": "key_C",
          "dfltValue": 4,
          "expectedValue": 2,
          "existingFlag": true,
          "shouldHaveMetadata": true
        },
        {
          "key": "key_D",
          "dfltValue": false,
          "expectedValue": true,
          "existingFlag": true,
          "shouldHaveMetadata": true
        },
        // array
        {
          "key": "array",
          "dfltValue": [],
          "expectedValue": [1, 2, 3],
          "existingFlag": true,
          "shouldHaveMetadata": true
        },
        // json
        {
          "key": "object",
          "dfltValue": {"value": 1111},
          "expectedValue": {"value": 123456},
          "existingFlag": true,
          "shouldHaveMetadata": true
        },
        //None existing key
        {
          "key": "badKey",
          "dfltValue": "dflt",
          "expectedValue": "dflt",
          "existingFlag": false,
          "shouldHaveMetadata": false
        }
      ];

      for (var item in listEntry) {
        print(item['key']);
        Flag myFlag = v1.getFlag(item['key']);

        expect(myFlag.value(item['dfltValue']), item['expectedValue']);
        expect(myFlag.exists(), item['existingFlag']);

        FlagMetadata metadata = myFlag.metadata();

        if (item['shouldHaveMetadata']) {
          expect(metadata.campaignId, "bsffhle242b2l3igq4dg");
          expect(metadata.variationGroupId, "bsffhle242b2l3igq4egaa");
          expect(metadata.variationId, "bsffhle242b2l3igq4f0");
          expect(metadata.isReference, true);
          expect(metadata.slug, "flutter");
          expect(metadata.campaignType, "ab");
        } else {
          expect(metadata.campaignId, "");
          expect(metadata.variationGroupId, "");
          expect(metadata.variationId, "");
          expect(metadata.isReference, false);
          expect(metadata.slug, null);
          expect(metadata.campaignType, "");
        }
        // Check lentgh for metedata json
        expect(myFlag.metadata().toJson().keys.length, 9);

        // Expose
        await myFlag.visitorExposed();
      }
    });
  }));

  test('Test Flag warning message', () {
    // Update Context
    Flagship.getCurrentVisitor()?.updateContext("keyFalg", "valueFlag");
    expect(Flagship.getCurrentVisitor()?.getFlagSyncStatus(),
        FlagSyncStatus.CONTEXT_UPDATED);

    // Authetictae
    Flagship.getCurrentVisitor()?.authenticate("xpcUser");
    expect(Flagship.getCurrentVisitor()?.getFlagSyncStatus(),
        FlagSyncStatus.AUTHENTICATED);
    // Update Flagship Context
    Flagship.getCurrentVisitor()
        ?.updateFlagshipContext(FlagshipContext.CARRIER_NAME, "SFR");
    expect(Flagship.getCurrentVisitor()?.getFlagSyncStatus(),
        FlagSyncStatus.CONTEXT_UPDATED);
    // unAuthetictae
    Flagship.getCurrentVisitor()?.unauthenticate();
    expect(Flagship.getCurrentVisitor()?.getFlagSyncStatus(),
        FlagSyncStatus.UNAUTHENTICATED);

    // Update context with the same keys
    Flagship.getCurrentVisitor()?.updateContext("keyFalg", "valueFlag");
    expect(Flagship.getCurrentVisitor()?.getFlagSyncStatus(),
        FlagSyncStatus.UNAUTHENTICATED);

    // Update context with the same keys
    Flagship.getCurrentVisitor()?.updateContextWithMap(
        Flagship.getCurrentVisitor()?.getContext() ?? {});
    expect(Flagship.getCurrentVisitor()?.getFlagSyncStatus(),
        FlagSyncStatus.UNAUTHENTICATED);

    Flagship.getCurrentVisitor()
        ?.updateFlagshipContext(FlagshipContext.CARRIER_NAME, "SFR");
    expect(Flagship.getCurrentVisitor()?.getFlagSyncStatus(),
        FlagSyncStatus.UNAUTHENTICATED);

    Flagship.getCurrentVisitor()
        ?.updateFlagshipContext(FlagshipContext.CARRIER_NAME, "ORANGE");
    expect(Flagship.getCurrentVisitor()?.getFlagSyncStatus(),
        FlagSyncStatus.CONTEXT_UPDATED);
  });

  test("Flag with bad type", () {
    //  PathProviderPlatform.instance = FakePathProviderPlatform();
    var v2 = Flagship.newVisitor(visitorId: "flagVisitor", hasConsented: true)
        .build();
    v2.fetchFlags().whenComplete(() {
      Flag myFlag = v2.getFlag(
        "key_A",
      );
      expect(myFlag.value(3.14), 3.14);

      Flag myFlagBis = v2.getFlag("key_A");
      expect(myFlagBis.value(false), false);

      expect(myFlag.exists(), true);
      FlagMetadata metadata = myFlag.metadata();
      expect(metadata.campaignId, "bsffhle242b2l3igq4dg");
      expect(metadata.variationGroupId, "bsffhle242b2l3igq4egaa");
      expect(metadata.variationId, "bsffhle242b2l3igq4f0");
      expect(metadata.isReference, true);
      expect(metadata.slug, "flutter");
      expect(metadata.campaignType, "ab");
    });
  });

  test("Flag with null as value", () {
    var v3 = Flagship.newVisitor(visitorId: "flagVisitor", hasConsented: true)
        .build();
    v3.fetchFlags().whenComplete(() {
      // String as default value
      Flag myFlag = v3.getFlag("keyNull");
      expect(myFlag.value("nullValue"), "nullValue");
      // bool as default value
      Flag myFlagBool = v3.getFlag("keyNull");
      expect(myFlagBool.value(false), false);
      // Double as default value
      Flag myFlagDouble = v3.getFlag("keyNull");
      expect(myFlagDouble.value(12.0), 12.0);
      // Int as default value
      Flag myFlagInt = v3.getFlag("keyNull");
      expect(myFlagInt.value(2), 2);
      // is existing
      expect(myFlag.exists(), true);
      // Get metadata
      FlagMetadata metadata = myFlag.metadata();
      expect(metadata.campaignId, "bsffhle242b2l3igq4dg");
      expect(metadata.variationGroupId, "bsffhle242b2l3igq4egaa");
      expect(metadata.variationId, "bsffhle242b2l3igq4f0");
      expect(metadata.isReference, true);
      expect(metadata.slug, "flutter");
      expect(metadata.campaignType, "ab");
    });
  });

  test("Flag value & default value = null", () {
    //PathProviderPlatform.instance = FakePathProviderPlatform();
    var v4 = Flagship.newVisitor(visitorId: "flagVisitor", hasConsented: true)
        .build();
    v4.fetchFlags().whenComplete(() {
      Flag myFlag = v4.getFlag("keyNull");
      expect(myFlag.value(null), null);
      expect(myFlag.exists(), true);
      FlagMetadata metadata = myFlag.metadata();
      expect(metadata.campaignId, "bsffhle242b2l3igq4dg");
      expect(metadata.variationGroupId, "bsffhle242b2l3igq4egaa");
      expect(metadata.variationId, "bsffhle242b2l3igq4f0");
      expect(metadata.isReference, true);
      expect(metadata.slug, "flutter");
      expect(metadata.campaignType, "ab");
    });
  });

  test("Flag with default value = null", () {
    //PathProviderPlatform.instance = FakePathProviderPlatform();
    var v4 = Flagship.newVisitor(visitorId: "flagVisitor", hasConsented: true)
        .build();
    v4.fetchFlags().whenComplete(() {
      Flag myFlag = v4.getFlag("key_A");
      expect(myFlag.value(null), "val_A");
      expect(myFlag.exists(), true);
      FlagMetadata metadata = myFlag.metadata();
      expect(metadata.campaignId, "bsffhle242b2l3igq4dg");
      expect(metadata.variationGroupId, "bsffhle242b2l3igq4egaa");
      expect(metadata.variationId, "bsffhle242b2l3igq4f0");
      expect(metadata.isReference, true);
      expect(metadata.slug, "flutter");
      expect(metadata.campaignType, "ab");
    });
  });

  test("Failed Activate Flag", () {
    when(fakeService.sendHttpRequest(RequestType.Post,
            'https://decision.flagship.io/v2/activate', any, any,
            timeoutMs: 60000))
        .thenAnswer((_) async {
      return http.Response("fakeResponse", 400);
    });
    var v5 = Flagship.newVisitor(visitorId: "flagVisitor", hasConsented: true)
        .build();
    v5.fetchFlags().whenComplete(() async {
      Flag myFlag = v5.getFlag("key_A");
      myFlag.visitorExposed();
    });
  });

  test("FlagCollections", () {
    var vCollect =
        Flagship.newVisitor(visitorId: "flagVisitor", hasConsented: true)
            .build();

    vCollect.trackingManager = fakeTracking;

    vCollect.fetchFlags().whenComplete(() {
      FlagCollection fCollect = vCollect.getFlags();
      // is not empty
      expect(fCollect.isEmpty, false);
      // Count == 11
      expect(fCollect.count, 12);

      var collectResult = fCollect.filter((key, flag) {
        return (key == "key_B");
      });
      // check if the count is equal to 1
      expect(collectResult.count, 1);
      // decode the json clollect
      var mapResult = jsonDecode(collectResult.toJson());
      // check the hex value
      expect(mapResult[0]["hex"], "7b2276223a332e31347d");
      // Expose all
      fCollect.exposeAll();
      // Check json with quick access
      var collectResultbis = fCollect.filter((key, flag) {
        return (key == "object");
      });
      var quickAccessFlag = collectResultbis["object"];
      // Get Value
      var val = quickAccessFlag.value({"value": 1111});
      // Check the value as expected
      expect(val["value"], 123456);
    });
  });
}
