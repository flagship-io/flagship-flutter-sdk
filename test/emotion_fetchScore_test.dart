import 'package:flagship/api/service.dart';
import 'package:flagship/emotionAi/emotion_tools.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_tools.dart';
import 'tracking_manager_test.mocks.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
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

  String fakeResponseBis =
      await ToolsTest.readFile('test_resources/fetchScoreBis.json') ?? "";
  when(fakeService.sendHttpRequest(
          RequestType.Get,
          'https://uc-info.flagship.io/v1/segments/clients/bkk9glocmjcg0vtmdlvb/visitors/mockScoreUser?partner=eai',
          any,
          any,
          timeoutMs: TIMEOUT))
      .thenAnswer((_) async {
    return http.Response(fakeResponseBis, 200);
  });

  String fakeResponseTer =
      await ToolsTest.readFile('test_resources/fetchScoreBis.json') ?? "";
  when(fakeService.sendHttpRequest(
          RequestType.Get,
          'https://uc-info.flagship.io/v1/segments/clients/bkk9glocmjcg0vtmdlvc/visitors/mockScoreUser?partner=eai',
          any,
          any,
          timeoutMs: TIMEOUT))
      .thenAnswer((_) async {
    return http.Response(fakeResponseTer, 400);
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

  test("Get score Corrupted json", () async {
    await Flagship.start("bkk9glocmjcg0vtmdlvb", "apiKey", config: config);

    // Get score
    ScoreResult result = await EmotionAITools().fetchScore("mockScoreUser");
    expect(result.statusCode, 200);
    expect(result.score, null);
  });

  test("Get score Failed", () async {
    await Flagship.start("bkk9glocmjcg0vtmdlvc", "apiKey", config: config);

    // Get score
    ScoreResult result = await EmotionAITools().fetchScore("mockScoreUser");
    expect(result.statusCode, 400);
    expect(result.score, null);
  });
}
