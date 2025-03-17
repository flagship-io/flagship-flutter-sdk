import 'dart:math';

import 'package:flagship/api/service.dart';
import 'package:flagship/emotionAi/emotion_tools.dart';
import 'package:flagship/emotionAi/fs_emotion.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/tracking/tracking_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'fake_path_provider_platform.dart';
import 'test_tools.dart';
import 'tracking_manager_test.mocks.dart';
import 'package:http/http.dart' as http;

@GenerateMocks([EmotionAITools])
void main() async {
  PathProviderPlatform.instance = FakePathProviderPlatform();
  ToolsTest.sqfliteTestInit();
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  databaseFactory = databaseFactoryFfi;

  MockService fakeService = MockService();

  when(fakeService.sendHttpRequest(
          RequestType.Post, 'https://ariane.abtasty.com/emotionsai', any, any,
          timeoutMs: TIMEOUT_REQUEST))
      .thenAnswer((_) async {
    return http.Response('fakeResponseEvent', 200);
  });

  String fakeResponse =
      await ToolsTest.readFile('test_resources/accountSettings.json') ?? "";
  when(fakeService.sendHttpRequest(
          RequestType.Get,
          'https://cdn.flagship.io/bkk9glocmjcg0vtmdlrr/accountSettings.json',
          any,
          any,
          timeoutMs: TIMEOUT))
      .thenAnswer((_) async {
    return http.Response(fakeResponse, 200);
  });

  String fakeResponseBis =
      await ToolsTest.readFile('test_resources/accountSettingsBis.json') ?? "";
  when(fakeService.sendHttpRequest(
          RequestType.Get,
          'https://cdn.flagship.io/bkk9glocmjcg0vtmdlrb/accountSettings.json',
          any,
          any,
          timeoutMs: TIMEOUT))
      .thenAnswer((_) async {
    return http.Response(fakeResponseBis, 200);
  });

  String fakeResponseTer =
      await ToolsTest.readFile('test_resources/accountSettingsBis.json') ?? "";
  when(fakeService.sendHttpRequest(
          RequestType.Get,
          'https://cdn.flagship.io/bkk9glocmjcg0vtmdlrc/accountSettings.json',
          any,
          any,
          timeoutMs: TIMEOUT))
      .thenAnswer((_) async {
    return http.Response(fakeResponseTer, 200);
  });

  await ToolsTest.readFile('test_resources/accountSettingsBis.json') ?? "";
  when(fakeService.sendHttpRequest(
          RequestType.Get,
          'https://cdn.flagship.io/bkk9glocmjcg0vtmdlrd/accountSettings.json',
          any,
          any,
          timeoutMs: TIMEOUT))
      .thenAnswer((_) async {
    return http.Response(fakeResponseTer, 400);
  });

  FlagshipConfig config = ConfigBuilder().withTimeout(TIMEOUT).build();
  config.decisionManager.service = fakeService;

  test("Test Account Ressource", () async {
    await Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey", config: config);
    expect(Flagship.sharedInstance().eaiActivationEnabled, true);
    expect(Flagship.sharedInstance().eaiCollectEnabled, true);
  });

  test("Test Account Ressource with False", () async {
    await Flagship.start("bkk9glocmjcg0vtmdlrb", "apiKey", config: config);
    expect(Flagship.sharedInstance().eaiActivationEnabled, false);
    expect(Flagship.sharedInstance().eaiCollectEnabled, false);
  });

  test("Test Account Ressource with missing fields", () async {
    await Flagship.start("bkk9glocmjcg0vtmdlrc", "apiKey", config: config);
    expect(Flagship.sharedInstance().eaiActivationEnabled, false);
    expect(Flagship.sharedInstance().eaiCollectEnabled, false);
  });

  test("Test Account Ressource with failed request", () async {
    await Flagship.start("bkk9glocmjcg0vtmdlrd", "apiKey", config: config);
    expect(Flagship.sharedInstance().eaiActivationEnabled, false);
    expect(Flagship.sharedInstance().eaiCollectEnabled, false);
  });

  test('test emotionAI object', () {
    EmotionAI emotion_ai = EmotionAI("userId", "anonymousId");
    expect(emotion_ai.anonymousId, "anonymousId");
    expect(emotion_ai.visitorId, "userId");
    expect(emotion_ai.isCollecting, false);
    // Start collect
    emotion_ai.startEAICollectForView("nameScreenTest");
    expect(emotion_ai.currentScreenName, "nameScreenTest");
  });

  test("with no consent ", () async {
    await Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey", config: config);
    String _visitorId = "flutterTest" + Random().nextInt(100000).toString();
    var nonCosentUser =
        Flagship.newVisitor(visitorId: _visitorId, hasConsented: false).build();
    nonCosentUser.collectEmotionsAIEvents("screenName");
    await Future.delayed(const Duration(milliseconds: 2000));
    expect(nonCosentUser.emotion_ai, null);
    expect(nonCosentUser.eaiVisitorScored, false);
    expect(nonCosentUser.emotionScoreAI, null);
  });
}
