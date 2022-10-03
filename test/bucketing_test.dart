import 'dart:convert';
import 'package:flagship/decision/bucketing_manager.dart';
import 'package:flagship/decision/bucketing_process.dart';
import 'package:flagship/model/bucketing.dart';
import 'package:flagship/model/campaigns.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'service_test.mocks.dart';
import 'test_tools.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  test("Bucketing test with context", () async {
    MockService fakeService = MockService();
    String fakeResponse = await ToolsTest.readFile('test_resources/bucketMock.json') ?? "";
    BucketingManager bkManager = BucketingManager(fakeService, 60);
    Bucketing bucketingObject = Bucketing.fromJson(json.decode(fakeResponse));
    Campaigns result =
        bkManager.bucketVariations('alias', bucketingObject, {"basketNumber": 100, "condition4": "value4"});
    expect(result.campaigns.length, 1);
    expect(result.campaigns.first.idCampaign, "br8dca47pe0g1648p34g");
    expect(result.campaigns.first.variation?.idVariation, "br8dihk7pe0g16ag5img");
    expect(result.campaigns.first.variation?.modifications.vals.length, 7);
    expect(result.campaigns.first.variation?.modifications.vals["key5"], "value");
    expect(result.campaigns.first.variation?.modifications.vals["key6"], 12);
    expect(result.campaigns.first.variation?.modifications.vals["key7"], true);

    Campaigns resultBis = bkManager.bucketVariations('alias', bucketingObject, {"condition4": "value5"});
    expect(resultBis.campaigns.length, 0);

    Campaigns resultTer = bkManager.bucketVariations('alias', bucketingObject, {
      "basketNumber": 100,
      "Boolean_Key": true,
      "ctxKeyNumber": 223,
      "testKey": "",
      "testKey1": "abc",
      "testKey2": "acd",
      "testKey3": "abcd"
    });
    expect(resultTer.campaigns.length, 1);

    Campaigns result4 = bkManager.bucketVariations('user5', bucketingObject, {
      "basketNumber": 100,
      "Boolean_Key": true,
      "ctxKeyNumber": 223,
      "testKey": "",
      "testKey1": "abc",
      "testKey2": "acd",
      "testKey3": "abcd"
    });
    expect(result4.campaigns.length, 0);
  });
}
