import 'package:flagship/decision/api_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_version.dart';
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
    FlagshipConfig conf = FlagshipConfig(statusListner: null);
    expect(conf.statusListner, null);

    FlagshipConfig confBis = FlagshipConfig.defaultMode();
    expect(confBis.statusListner, null);

    FlagshipConfig confTer =
        FlagshipConfig.withStatusListner(statusListner: (newState) {});
    expect((confTer.statusListner != null), true);
    confTer.statusListner = null;
    expect(confTer.statusListner, null);
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
    config.statusListner = (newState) {
      if (newState == Status.PANIC_ON) {
        expect(Flagship.getCurrentVisitor()?.getModification('key1', 12), 12);

        expect(newState, Flagship.getStatus());
      }
    };

    config.decisionManager = fakePanicApi;
    Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey", config: config);

    var v1 = Flagship.newVisitor("visitorId", {});
    Flagship.setCurrentVisitor(v1);

    v1.synchronizeModifications().whenComplete(() {});
  });
}
