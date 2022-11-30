import 'package:flagship/decision/api_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagshipContext/flagship_context_manager.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'service_test.mocks.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/hits/event.dart';
import 'test_tools.dart';

@GenerateMocks([Service])
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey");
  Map<String, String> fsHeaders = {
    "x-api-key": "apiKey",
    "x-sdk-client": "flutter",
    "x-sdk-version": FlagshipVersion,
    "Content-type": "application/json"
  };

  // Map<String, dynamic> presetContext = FlagshipContextManager.getPresetContextForApp();
  // Map<String, dynamic> jsonData = {"visitorId": "panicUser", "context": presetContext, "trigger_hit": false};
  // Object data = json.encode(jsonData);
  // //Object data = json.encode({"visitorId": "visitorId", "context": {}, "trigger_hit": false});

  MockService fakePanicService = MockService();
  ApiManager fakePanicApi = ApiManager(fakePanicService);
  test('Test API with panic mode', () async {
    String fakeResponse = await ToolsTest.readFile('test_resources/decisionApiPanic.json') ?? "";
    when(fakePanicService.sendHttpRequest(RequestType.Post,
            'https://decision.flagship.io/v2/bkk9glocmjcg0vtmdlrr/campaigns/?exposeAllKeys=true', fsHeaders, any,
            timeoutMs: TIMEOUT))
        .thenAnswer((_) async {
      return http.Response(fakeResponse, 200);
    });

    FlagshipConfig config = ConfigBuilder().withTimeout(TIMEOUT).build();
    config.statusListener = (newState) {
      if (newState == Status.PANIC_ON) {
        // ignore: deprecated_member_use_from_same_package
        expect(Flagship.getCurrentVisitor()?.getModification('key1', 12), 2);
      }
    };

    config.decisionManager = fakePanicApi;
    Flagship.sharedInstance().onUpdateState(Status.NOT_INITIALIZED);
    Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey", config: config);

    var v1 = Flagship.newVisitor("panicUser").build();
    Flagship.setCurrentVisitor(v1);

    // ignore: deprecated_member_use_from_same_package
    v1.synchronizeModifications().then((value) {
      expect(Flagship.getStatus(), Status.PANIC_ON);

      /// Activate
      // ignore: deprecated_member_use_from_same_package
      v1.activateModification("key");

      // ignore: deprecated_member_use_from_same_package
      expect(v1.getModification('key1', 12), 12);

      // ignore: deprecated_member_use_from_same_package
      expect(v1.getModificationInfo('key1'), null);

      v1.setConsent(false);
      expect(v1.getConsent(), false);

      v1.updateContext("newKey", 2);
      expect(v1.getContext().keys.contains('newKey'), false);

      /// Send hit
      v1.sendHit(Event(action: "action", category: EventCategory.Action_Tracking));
    });
  });
}
