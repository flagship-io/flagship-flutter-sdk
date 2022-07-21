import 'dart:convert';

import 'package:flagship/api/service.dart';
import 'package:flagship/decision/api_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flagship/model/flag.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'service_test.mocks.dart';
import 'test_tools.dart';
import 'package:http/http.dart' as http;

@GenerateMocks([Service])
void main() async {
  Map<String, String> fsHeaders = {
    "x-api-key": "apiKey",
    "x-sdk-client": "flutter",
    "x-sdk-version": FlagshipVersion,
    "Content-type": "application/json"
  };
  Object data = json.encode({"visitorId": "flagVisitor", "context": {}, "trigger_hit": false});
  MockService fakeService = MockService();
  ApiManager fakeApi = ApiManager(fakeService);

  String fakeResponse = await ToolsTest.readFile('test_resources/decisionApi.json') ?? "";
  when(fakeService.sendHttpRequest(RequestType.Post,
          'https://decision.flagship.io/v2/bkk9glocmjcg0vtmdlrr/campaigns/?exposeAllKeys=true', fsHeaders, data,
          timeoutMs: TIMEOUT))
      .thenAnswer((_) async {
    return http.Response(fakeResponse, 200);
  });

  FlagshipConfig config = ConfigBuilder().withTimeout(TIMEOUT).build();
  config.decisionManager = fakeApi;
  Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey", config: config);
  var v1 = Flagship.newVisitor("flagVisitor").build();

  test("Test Flag class", (() async {
    v1.fetchFlags().whenComplete(() {
      // List of flags
      List<Map<String, dynamic>> listEntry = [
        // Correct Flag
        {
          "key": "key_A",
          "dfltValue": "defaultValue",
          "expectedValue": "val_A",
          "existingFlag": true,
          "shouldHaveMetadata": true
        },
        {"key": "key_B", "dfltValue": 2.14, "expectedValue": 3.14, "existingFlag": true, "shouldHaveMetadata": true},
        {"key": "key_C", "dfltValue": 4, "expectedValue": 2, "existingFlag": true, "shouldHaveMetadata": true},
        {"key": "key_D", "dfltValue": false, "expectedValue": true, "existingFlag": true, "shouldHaveMetadata": true},
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
        Flag myFlag = v1.getFlag(item['key'], item['dfltValue']);

        expect(myFlag.value(), item['expectedValue']);
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
          expect(metadata.slug, "");
          expect(metadata.campaignType, "");
        }
        // Check lentgh for metedata json
        expect(myFlag.metadata().toJson().keys.length, 6);
        // Expose
        myFlag.userExposed();
      }
    });
  }));

  test("Flag with bad type", () {
    v1.fetchFlags().whenComplete(() {
      Flag myFlag = v1.getFlag("key_A", 3.14);
      expect(myFlag.value(), 3.14);
      expect(myFlag.exists(), true);
      FlagMetadata metadata = myFlag.metadata();
      expect(metadata.campaignId, "");
      expect(metadata.variationGroupId, "");
      expect(metadata.variationId, "");
      expect(metadata.isReference, false);
      expect(metadata.slug, "");
      expect(metadata.campaignType, "");
    });
  });

  test("Flag with null as value", () {
    v1.fetchFlags().whenComplete(() {
      Flag myFlag = v1.getFlag("keyNull", "nullValue");
      expect(myFlag.value(), "nullValue");
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

  test("Flag value & default value = null", () {
    v1.fetchFlags().whenComplete(() {
      Flag myFlag = v1.getFlag("keyNull", null);
      expect(myFlag.value(), null);
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
}
