import 'package:flagship/api/service.dart';
import 'package:flagship/cache/default_cache.dart';
import 'package:flagship/decision/api_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flagship/tracking/tracking_manager.dart';
import 'package:flagship/tracking/tracking_manager_config.dart';
import 'package:flagship/visitor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';
import 'service_test.mocks.dart';
import 'test_tools.dart';

@GenerateMocks([Service])
MockService fakeService = MockService();

MockService fakeTrackingService = MockService();

TrackingManager fakeTrackingMgr = TrackingManager(
    fakeTrackingService, TrackingManagerConfig(), DefaultCacheHitImp());

ApiManager fakeApi = ApiManager(fakeService);

Future<void> main() async {
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
          'https://decision.flagship.io/v2/bkk9glocmjcg0vtmdlrr/campaigns/?exposeAllKeys=true',
          fsHeaders,
          any,
          timeoutMs: TIMEOUT))
      .thenAnswer((_) async {
    return http.Response(fakeResponse, 200);
  });
  test("Test activate ", () async {
    await Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey");
    Visitor vMock = VisitorBuilder("visitorId").build();
    vMock.trackingManager = fakeTrackingMgr;
    vMock.config.decisionManager = fakeApi;

    vMock.fetchFlags().whenComplete(() async {
      var mockFlag = vMock.getFlag("key_A", "defaultValue");

      var mockVal = mockFlag.value(userExposed: false);
      // "key_A":"val_A",
      expect(mockVal, "val_A");
      await mockFlag.userExposed();
      // The activate should failed ==> the activate pool should have one in queue
      expect(fakeTrackingMgr.activatePool.fsQueue.length, 1);

      await mockFlag.userExposed();
      expect(fakeTrackingMgr.activatePool.fsQueue.length, 2);

      // Update response for the activate 200
      // response for activate 400
      when(fakeTrackingService.sendHttpRequest(RequestType.Post,
              'https://decision.flagship.io/v2/activate', any, any,
              timeoutMs: TIMEOUT_REQUEST))
          .thenAnswer((_) async {
        return http.Response("mock", 200);
      });
      await mockFlag.userExposed();
      expect(fakeTrackingMgr.activatePool.fsQueue.length, 0);
    });
  });
}
