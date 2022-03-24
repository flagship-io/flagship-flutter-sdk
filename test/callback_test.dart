import 'package:flagship/decision/api_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'service_test.mocks.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/flagship_config.dart';
import 'test_tools.dart';

@GenerateMocks([Service])
void main() {
  Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey");
  Map<String, String> fsHeaders = {
    "x-api-key": "apiKey",
    "x-sdk-client": "flutter",
    "x-sdk-version": FlagshipVersion,
    "Content-type": "application/json"
  };

  Object data = json
      .encode({"visitorId": "visitorId", "context": {}, "trigger_hit": false});

  MockService fakePanicService = MockService();
  ApiManager fakePanicApi = ApiManager(fakePanicService);

  test('FlagshipConfig ', () async {
    FlagshipConfig conf = FlagshipConfig(
        statusListener: null,
        timeout: 4000,
        activeLog: false,
        logLevel: Level.ALL);

    expect(conf.statusListener, null);
    expect(conf.timeout, 4000);
    expect(conf.decisionMode, Mode.DECISION_API);

    FlagshipConfig confBis = FlagshipConfig.defaultMode();
    expect(confBis.statusListener, null);

    FlagshipConfig confTer =
        FlagshipConfig.withStatusListener(statusListener: (newStatus) {});
    expect((confTer.statusListener != null), true);
    confTer.statusListener = null;
    expect(confTer.statusListener, null);
  });

  test('Test API with panic mode', () async {
    String fakeResponse =
        await ToolsTest.readFile('test_resources/decisionApiPanic.json') ?? "";
    when(fakePanicService.sendHttpRequest(
            RequestType.Post,
            'https://decision.flagship.io/v2/bkk9glocmjcg0vtmdlrr/campaigns/?exposeAllKeys=true',
            fsHeaders,
            data,
            timeoutMs: TIMEOUT))
        .thenAnswer((_) async {
      return http.Response(fakeResponse, 200);
    });

    FlagshipConfig config = FlagshipConfig(timeout: TIMEOUT);
    config.statusListener = (newStatus) {
      if (newStatus == Status.PANIC_ON) {
        expect(Flagship.getCurrentVisitor()?.getModification('key1', 12), 12);
        expect(newStatus, Flagship.getStatus());
      }
    };

    config.decisionManager = fakePanicApi;
    Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey", config: config);

    var v1 = Flagship.newVisitor("visitorId", {});
    Flagship.setCurrentVisitor(v1);

    v1.synchronizeModifications().whenComplete(() {});
  });
}
