import 'dart:math';
import 'package:flagship/api/service.dart';
import 'package:flagship/emotionAi/emotion_event.dart';
import 'package:flagship/emotionAi/emotion_tools.dart';
import 'package:flagship/emotionAi/polling_score.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/tracking/tracking_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fake_path_provider_platform.dart';
import 'test_tools.dart';
import 'tracking_manager_test.mocks.dart';
import 'package:http/http.dart' as http;

@GenerateMocks([EmotionAiDelegate])
Future<void> main() async {
  PathProviderPlatform.instance = FakePathProviderPlatform();
  ToolsTest.sqfliteTestInit();
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  MockService fakeService = MockService();

  String fakeResponse =
      await ToolsTest.readFile('test_resources/fetchScore.json') ?? "";
  when(fakeService.sendHttpRequest(
          RequestType.Get,
          'https://uc-info.flagship.io/v1/segments/clients/bkk9glocmjcg0vtmdlva/visitors/mockScoreUser?partner=eai',
          any,
          any,
          timeoutMs: TIMEOUT))
      .thenAnswer((_) async {
    return http.Response(fakeResponse, 200);
  });

  String fakeRessoource =
      await ToolsTest.readFile('test_resources/accountSettings.json') ?? "";
  when(fakeService.sendHttpRequest(
          RequestType.Get,
          'https://cdn.flagship.io/bkk9glocmjcg0vtmdlva/accountSettings.json',
          any,
          any,
          timeoutMs: TIMEOUT))
      .thenAnswer((_) async {
    return http.Response(fakeRessoource, 200);
  });

  String fakeResponseBis =
      await ToolsTest.readFile('test_resources/fetchScore.json') ?? "";
  when(fakeService.sendHttpRequest(
          RequestType.Get,
          'https://uc-info.flagship.io/v1/segments/clients/bkk9glocmjcg0vtmdlvc/visitors/mockScoreUser?partner=eai',
          any,
          any,
          timeoutMs: TIMEOUT))
      .thenAnswer((_) async {
    return http.Response(fakeResponseBis, 204);
  });

  when(fakeService.sendHttpRequest(
          RequestType.Post, 'https://ariane.abtasty.com/emotionsai', any, any,
          timeoutMs: TIMEOUT_REQUEST))
      .thenAnswer((_) async {
    return http.Response('fakeResponseEvent', 200);
  });

  FlagshipConfig config = ConfigBuilder().withTimeout(TIMEOUT).build();
  config.decisionManager.service = fakeService;

  test("Get score", () async {
    await Flagship.start("bkk9glocmjcg0vtmdlva", "apiKey", config: config);
    // Get score
    ScoreResult result = await EmotionAITools().fetchScore("mockScoreUser");
    expect(result.statusCode, 200);
    expect(result.score, "Immediacy");
  });

  test("Polling score with 204", () async {
    await Flagship.start("bkk9glocmjcg0vtmdlvc", "apiKey", config: config);

    var vistorTest =
        Flagship.newVisitor(visitorId: "mockScoreUser", hasConsented: true)
            .build();

    vistorTest.collectEmotionsAIEvents("screenName");

    await Future.delayed(const Duration(milliseconds: 2000));

    expect(vistorTest.emotionScoreAI, null);
  });

  test("Polling score with 200", () async {
    String _visitorId = "flutterTestUser" + Random().nextInt(100000).toString();
    MockService fakeService200 = MockService();

    String fakeResponse200 =
        await ToolsTest.readFile('test_resources/fetchScore.json') ?? "";
    when(fakeService200.sendHttpRequest(
            RequestType.Get,
            'https://uc-info.flagship.io/v1/segments/clients/bkk9glocmjcg0vtmdlvc/visitors/${_visitorId}?partner=eai',
            any,
            any,
            timeoutMs: TIMEOUT))
        .thenAnswer((_) async {
      return http.Response(fakeResponse200, 204);
    });

    when(fakeService200.sendHttpRequest(
            RequestType.Post, 'https://ariane.abtasty.com/emotionsai', any, any,
            timeoutMs: TIMEOUT_REQUEST))
        .thenAnswer((_) async {
      return http.Response('fakeResponseEvent', 200);
    });

    String fakeRessoource =
        await ToolsTest.readFile('test_resources/accountSettings.json') ?? "";
    when(fakeService200.sendHttpRequest(
            RequestType.Get,
            'https://cdn.flagship.io/bkk9glocmjcg0vtmdlvc/accountSettings.json',
            any,
            any,
            timeoutMs: TIMEOUT))
        .thenAnswer((_) async {
      return http.Response(fakeRessoource, 200);
    });

    when(fakeService200.sendHttpRequest(
            RequestType.Get,
            'https://uc-info.flagship.io/v1/segments/clients/bkk9glocmjcg0vtmdlvd/visitors/${_visitorId}?partner=eai',
            any,
            any,
            timeoutMs: TIMEOUT))
        .thenAnswer((_) async {
      return http.Response(fakeResponse200, 200);
    });

    FlagshipConfig config200 = ConfigBuilder().withTimeout(TIMEOUT).build();
    config200.decisionManager.service = fakeService200;

    // Start
    await Flagship.start("bkk9glocmjcg0vtmdlvc", "apiKey", config: config200);

    // Create visitor
    var vistorTest =
        await Flagship.newVisitor(visitorId: _visitorId, hasConsented: true)
            .build();

    // Start collect
    vistorTest.collectEmotionsAIEvents("screenName");
    // Delayed time to wait reponse of sending view
    await Future.delayed(const Duration(milliseconds: 3000));
    expect(vistorTest.emotion_ai?.isCollecting, true,
        reason: "The collect should be collecting ......");

    String cpStirng = "cpString";
    String cpoString = "cpoString";
    String spoString = "spoString";
    String currentScreen = "currenTtScreent";

    FSEmotionEvent eventTest =
        FSEmotionEvent(cpStirng, cpoString, spoString, currentScreen);

    // Send events
    vistorTest.emotion_ai?.sendEvent(eventTest, 10);
    vistorTest.emotion_ai?.sendEvent(eventTest, 20);
    vistorTest.emotion_ai
        ?.sendEvent(eventTest, 35); // To stop and polling score

    // Change the id for envId in order to have the mock url
    Flagship.sharedInstance().envId = "bkk9glocmjcg0vtmdlvd";
    // The collect should be stop
    expect(vistorTest.emotion_ai?.isCollecting, false,
        reason: "The collect should not collecting ......");

    // Await few time for polling score
    await Future.delayed(const Duration(milliseconds: 10000));

    expect(vistorTest.emotionScoreAI, "Immediacy");
    expect(vistorTest.eaiVisitorScored, true);
  });
}
