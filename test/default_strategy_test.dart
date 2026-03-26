import 'package:flagship/decision/api_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flagship/status.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fake_path_provider_platform.dart';
import 'service_test.mocks.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/hits/event.dart';
import 'test_tools.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

@GenerateMocks([Service])
void main() {
  ToolsTest.sqfliteTestInit();
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  Map<String, String> fsHeaders = {
    "x-api-key": "apiKey",
    "x-sdk-client": "flutter",
    "x-sdk-version": FlagshipVersion,
    "Content-type": "application/json"
  };

  MockService fakeService = MockService();
  ApiManager fakeApi = ApiManager(fakeService);
  test('Test API with default startegy', () async {
    String fakeResponse =
        await ToolsTest.readFile('test_resources/decisionApi.json') ?? "";
    when(fakeService.sendHttpRequest(
            RequestType.Post,
            'https://decision.flagship.io/v2/bkk9glocmjcg0vtmdlng/campaigns/?exposeAllKeys=true&extras[]=accountSettings',
            fsHeaders,
            any,
            timeoutMs: TIMEOUT))
        .thenAnswer((_) async {
      return http.Response(fakeResponse, 200);
    });

    FlagshipConfig config = ConfigBuilder().withTimeout(TIMEOUT).build();
    // config.decisionManager = fakeApi;
    await Flagship.start("bkk9glocmjcg0vtmdlng", "apiKey", config: config);
    Flagship.enableLog(true);
    Flagship.setLoggerLevel(Level.WARNING);
    PathProviderPlatform.instance = FakePathProviderPlatform();

    var v1 = Flagship.newVisitor(visitorId: "visitorId", hasConsented: true)
        .withContext({}).build();

    v1.config.decisionManager = fakeApi;

    v1.setConsent(true);
    expect(v1.getConsent(), true);
    // ignore: deprecated_member_use_from_same_package

    await v1.fetchFlags().whenComplete(() {
      expect(Flagship.getStatus(), FSSdkStatus.SDK_INITIALIZED);
      expect(v1.flagStatus, FlagStatus.FETCHED);
      expect(v1.fetchReasons, FetchFlagsRequiredStatusReason.NONE);

      /// Send hit
      v1.sendHit(
          Event(action: "action", category: EventCategory.Action_Tracking));

      /// Send consent hit
      v1.sendHit(Consent(hasConsented: false));
    });
  });

  test('Test API with default startegy and callback', () async {
    // MockService fakeService = MockService();
    // ApiManager fakeApi = ApiManager(fakeService);

    String fakeResponse =
        await ToolsTest.readFile('test_resources/decisionApi.json') ?? "";
    when(fakeService.sendHttpRequest(
            RequestType.Post,
            'https://decision.flagship.io/v2/bkk9glocmjcg0vtmdlrr/campaigns/?exposeAllKeys=true',
            fsHeaders,
            any,
            timeoutMs: TIMEOUT))
        .thenAnswer((_) async {
      return http.Response(fakeResponse, 200);
    });

    /// count the callback trigger

    FlagshipConfig config =
        ConfigBuilder().withTimeout(TIMEOUT).onSdkStatusChanged((newStatus) {
      print(" ---- statusListner is trigger ---- ");
      expect(Flagship.getStatus() == newStatus, true);
      expect(newStatus, Flagship.getStatus());
    }).build();

    config.decisionManager = fakeApi;

    await Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey", config: config);
    PathProviderPlatform.instance = FakePathProviderPlatform();
    var v1 =
        Flagship.newVisitor(visitorId: "visitorId", hasConsented: true).build();
    Flagship.setCurrentVisitor(v1);
    expect(v1.getConsent(), true);

    // ignore: deprecated_member_use_from_same_package
    await v1.fetchFlags().then((value) {
      expect(Flagship.getStatus(), FSSdkStatus.SDK_INITIALIZED);

      v1.modifications.clear();
    });
  });

  test('Test API with timeout', () async {
    String fakeResponse =
        await ToolsTest.readFile('test_resources/decisionApi.json') ?? "";
    when(fakeService.sendHttpRequest(
            RequestType.Post,
            'https://decision.flagship.io/v2/bkk9glocmjcg0vtmdlrr/campaigns/?exposeAllKeys=true',
            any,
            any,
            timeoutMs: TIMEOUT))
        .thenAnswer((_) async {
      return http.Response(fakeResponse, 408);
    });

    String fakeRessoource =
        await ToolsTest.readFile('test_resources/accountSettings.json') ?? "";
    when(fakeService.sendHttpRequest(
            RequestType.Get,
            'https://cdn.flagship.io/bkk9glocmjcg0vtmdlrr/accountSettings.json',
            any,
            any,
            timeoutMs: TIMEOUT))
        .thenAnswer((_) async {
      return http.Response(fakeRessoource, 200);
    });

    FlagshipConfig config =
        ConfigBuilder().withTimeout(TIMEOUT).onSdkStatusChanged((newStatus) {
      print(" ---- statusListner is trigger ---- ");
      expect(Flagship.getStatus() == newStatus, true);
      expect(newStatus, Flagship.getStatus());
    }).build();

    config.decisionManager = fakeApi;

    await Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey", config: config);
    PathProviderPlatform.instance = FakePathProviderPlatform();
    var v1 =
        Flagship.newVisitor(visitorId: "visitorId", hasConsented: true).build();
    Flagship.setCurrentVisitor(v1);
    expect(v1.getConsent(), true);

    v1.fetchFlags().whenComplete(() {
      expect(v1.flagStatus, FlagStatus.FETCH_REQUIRED);
      expect(
          v1.fetchReasons, FetchFlagsRequiredStatusReason.FLAGS_FETCHING_ERROR);
    });
  });
}
