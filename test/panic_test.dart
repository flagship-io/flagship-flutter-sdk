import 'package:flagship/decision/api_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flagship/status.dart';
import 'package:flagship/tracking/tracking_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fake_path_provider_platform.dart';
import 'service_test.mocks.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/hits/event.dart';
import 'test_tools.dart';

@GenerateMocks([Service])
void main() {
  PathProviderPlatform.instance = FakePathProviderPlatform();
  ToolsTest.sqfliteTestInit();
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey");

  MockService fakePanicService = MockService();
  ApiManager fakePanicApi = ApiManager(fakePanicService);
  test('Test API with panic mode', () async {
    String fakeResponse =
        await ToolsTest.readFile('test_resources/decisionApiPanic.json') ?? "";
    when(fakePanicService.sendHttpRequest(
      RequestType.Post,
      'https://decision.flagship.io/v2/bkk9glocmjcg0vtmdlrr/campaigns/?exposeAllKeys=true&extras[]=accountSettings',
      any,
      any,
      timeoutMs: TIMEOUT,
    )).thenAnswer((_) async {
      return http.Response(fakeResponse, 200);
    });

    FlagshipConfig config = ConfigBuilder().withTimeout(TIMEOUT).build();

    Flagship.sharedInstance().onUpdateState(FSSdkStatus.SDK_NOT_INITIALIZED);
    await Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey", config: config);

    var v1 =
        Flagship.newVisitor(visitorId: "panicUser", hasConsented: true).build();
    v1.config.decisionManager = fakePanicApi;

    Flagship.setCurrentVisitor(v1);

    // ignore: deprecated_member_use_from_same_package
    await v1.fetchFlags().then((value) {
      expect(Flagship.getStatus(), FSSdkStatus.SDK_PANIC);

      /// Activate
      // ignore: deprecated_member_use_from_same_package
      // v1.activateModification("key");

      // ignore: deprecated_member_use_from_same_package
      // expect(v1.getModification('key1', 12), 12);

      // ignore: deprecated_member_use_from_same_package
      // expect(v1.getModificationInfo('key1'), null);

      v1.setConsent(false);
      expect(v1.getConsent(), false);

      v1.updateContext("newKey", 2);
      expect(v1.getContext().keys.contains('newKey'), false);

      /// Send hit
      v1.sendHit(
          Event(action: "action", category: EventCategory.Action_Tracking));
    });
  });
}
