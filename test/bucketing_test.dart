import 'dart:convert';
import 'package:flagship/decision/bucketing_manager.dart';
import 'package:flagship/decision/bucketing_process.dart';
import 'package:flagship/model/bucketing.dart';
import 'package:flagship/model/campaigns.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fake_path_provider_platform.dart';
import 'service_test.mocks.dart';
import 'test_tools.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = FakePathProviderPlatform();
  ToolsTest.sqfliteTestInit();
  SharedPreferences.setMockInitialValues({});

  test("Bucketing test with context", () async {
    MockService fakeService = MockService();
    String fakeResponse =
        await ToolsTest.readFile('test_resources/bucketMock.json') ?? "";
    BucketingManager bkManager = BucketingManager(fakeService, 60);
    Bucketing bucketingObject = Bucketing.fromJson(json.decode(fakeResponse));
    Campaigns result = bkManager.bucketVariations('alias', bucketingObject,
        {"basketNumber": 100, "condition4": "value4"}, {});
    expect(result.campaigns.length, 1);
    expect(result.campaigns.first.idCampaign, "br8dca47pe0g1648p34g");
    expect(
        result.campaigns.first.variation?.idVariation, "br8dihk7pe0g16ag5img");
    expect(result.campaigns.first.variation?.modifications?.vals.length, 7);
    expect(
        result.campaigns.first.variation?.modifications?.vals["key5"], "value");
    expect(result.campaigns.first.variation?.modifications?.vals["key6"], 12);
    expect(result.campaigns.first.variation?.modifications?.vals["key7"], true);

    expect(result.accountSettings?.enabled1V1T, false);
    expect(result.accountSettings?.enabledXPC, false);
    expect(result.accountSettings?.troubleshooting, null);

    Campaigns resultBis = bkManager.bucketVariations(
        'alias', bucketingObject, {"condition4": "value5"}, {});
    expect(resultBis.campaigns.length, 0);

    Campaigns resultTer = bkManager.bucketVariations('alias', bucketingObject, {
      "basketNumber": 100,
      "Boolean_Key": true,
      "ctxKeyNumber": 223,
      "testKey": "",
      "testKey1": "abc",
      "testKey2": "acd",
      "testKey3": "abcd",
      "testKey4": 5,
      "testKey5": 6,
      "testKey6": 8,
      "testKey7": 11,
      "testKey8": "1",
      "testKey9": "9",
      "testKey10": "100"
    }, {});
    expect(resultTer.campaigns.length, 1);
  });

  test("Bucketing test with context", () async {
    MockService fakeService = MockService();
    BucketingManager bkManager = BucketingManager(fakeService, 60);

    String fakeResponse =
        await ToolsTest.readFile('test_resources/bucketMockBis.json') ?? "";
    Bucketing bucketingObject = Bucketing.fromJson(json.decode(fakeResponse));
    Campaigns result = bkManager.bucketVariations('alias', bucketingObject,
        {"basketNumber": 100, "condition4": "value4"}, {});

    expect(result.accountSettings?.troubleshooting?.traffic, 50);
    expect(result.accountSettings?.troubleshooting?.startDate,
        "2023-11-08T22:39:17.765Z");
  });
}
