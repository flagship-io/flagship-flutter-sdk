import 'package:flagship/api/service.dart';
import 'package:flagship/cache/default_cache.dart';
import 'package:flagship/decision/api_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flagship/model/flag.dart';
import 'package:flagship/tracking/tracking_manager.dart';
import 'package:flagship/tracking/tracking_manager_config.dart';
import 'package:flagship/tracking/tracking_manager_continuous_strategies.dart';
import 'package:flagship/visitor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';
import 'fake_path_provider_platform.dart';
import 'service_test.mocks.dart';
import 'test_tools.dart';

@GenerateMocks([Service])
MockService fakeService = MockService();

MockService fakeTrackingService = MockService();

TrackingManager fakeTrackingMgr = TrackingManageContinuousStrategy(
    fakeTrackingService, TrackingManagerConfig(), DefaultCacheHitImp());

ApiManager fakeApi = ApiManager(fakeService);

Future<void> main() async {
  PathProviderPlatform.instance = FakePathProviderPlatform();
  ToolsTest.sqfliteTestInit();
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  Map<String, String> fsHeaders = {
    "x-api-key": "apiKey",
    "x-sdk-client": "flutter",
    "x-sdk-version": FlagshipVersion,
    "Content-type": "application/json"
  };

  // response for activate 400
  when(fakeTrackingService.sendHttpRequest(RequestType.Post,
          'https://decision.flagship.io/v2/activate', any, any,
          timeoutMs: TIMEOUT_REQUEST))
      .thenAnswer((_) async {
    return http.Response("mock", 400);
  });

  /// prepare response
  String fakeResponse =
      await ToolsTest.readFile('test_resources/decisionApi.json') ?? "";
  when(fakeService.sendHttpRequest(
          RequestType.Post,
          'https://decision.flagship.io/v2/bkk9glocmjcg0vtmdlrr/campaigns/?exposeAllKeys=true&extras[]=accountSettings',
          fsHeaders,
          any,
          timeoutMs: TIMEOUT))
      .thenAnswer((_) async {
    return http.Response(fakeResponse, 200);
  });
  test("Test activate ", () async {
    var conf =
        ConfigBuilder().withOnVisitorExposed((visitorExposed, flagExposed) {
      expect(visitorExposed.id, "visitorId");
      expect(flagExposed.key, "key_A");
    }).build();

    await Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey", config: conf);
    Visitor vMock = VisitorBuilder("visitorId", true).build();
    vMock.trackingManager = fakeTrackingMgr;
    vMock.config.decisionManager = fakeApi;

    (vMock.trackingManager as TrackingManageContinuousStrategy)
        .activatePool
        .fsQueue
        .clear();
    await vMock.fetchFlags();

    for (int i = 0; i < 300; i++) {
      Flag mockFlag;
      mockFlag = vMock.getFlag("key_A");
      var mockVal = mockFlag.value("defaultValue", visitorExposed: false);
      expect(mockVal, "val_A");
      await mockFlag.visitorExposed();
    }

    expect(
        (vMock.trackingManager as TrackingManageContinuousStrategy)
            .activatePool
            .fsQueue
            .length,
        300);

    when(fakeTrackingService.sendHttpRequest(RequestType.Post,
            'https://decision.flagship.io/v2/activate', any, any,
            timeoutMs: TIMEOUT_REQUEST))
        .thenAnswer((_) async {
      return http.Response("mock", 200);
    });
    Flag mockFlagBis;
    mockFlagBis = vMock.getFlag("key_A");
    var mockValBis = mockFlagBis.value("defaultValue", visitorExposed: false);
    expect(mockValBis, "val_A");
    await mockFlagBis.visitorExposed();
    // After sucess the pool should be empty
    expect(
        (vMock.trackingManager as TrackingManageContinuousStrategy)
            .activatePool
            .fsQueue
            .length,
        0);
  });
}
