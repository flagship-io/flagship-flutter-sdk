import 'package:flagship/api/service.dart';
import 'package:flagship/cache/default_cache.dart';
import 'package:flagship/decision/api_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flagship/hits/screen.dart';
import 'package:flagship/tracking/tracking_manager.dart';
import 'package:flagship/tracking/tracking_manager_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'default_strategy_test.mocks.dart';
import 'test_tools.dart';
import 'package:http/http.dart' as http;

@GenerateMocks([Service])
Future<void> main() async {
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
  MockService fakeTrackingService = MockService();

  TrackingManager fakeTrackingMgr = TrackingManager(
      fakeTrackingService, TrackingManagerConfig(), DefaultCacheHitImp());

  ApiManager fakeApi = ApiManager(fakeService);

  test("workflow whithout strategy / hits", () async {
    // Mock the event route
    when(fakeTrackingService.sendHttpRequest(
            RequestType.Post, 'https://events.flagship.io', any, any,
            timeoutMs: TIMEOUT_REQUEST))
        .thenAnswer((_) async {
      return http.Response("mock", 200);
    });

    // Mock the fetch reponse
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
    // Start Flagship with hidden strategy
    await Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey",
        config: ConfigBuilder()
            .withTrackingConfig(TrackingManagerConfig(
                batchStrategy: BatchCachingStrategy
                    .NO_BATCHING_CONTINUOUS_CACHING_STRATEGY))
            .build());
// create new visitor
    var user = Flagship.newVisitor("userWithHidden").build();
    // Set the mocks
    user.trackingManager = fakeTrackingMgr;
    user.config.decisionManager = fakeApi;

    user.fetchFlags().whenComplete(() async {});
    // Send hit
    await user.sendHit(Screen(location: "locationTest"));
    // Failed the hit
    when(fakeTrackingService.sendHttpRequest(
            RequestType.Post, 'https://events.flagship.io', any, any,
            timeoutMs: TIMEOUT_REQUEST))
        .thenAnswer((_) async {
      return http.Response("mock", 400);
    });
    await user.sendHit(Screen(location: "locationTest"));
    await user.sendHit(Screen(location: "locationTest"));

    when(fakeTrackingService.sendHttpRequest(
            RequestType.Post, 'https://events.flagship.io', any, any,
            timeoutMs: TIMEOUT_REQUEST))
        .thenAnswer((_) async {
      return http.Response("mock", 200);
    });

    Flagship.sharedInstance().close();
  });

  test("workflow whithout strategy / activate", () async {
    // Mock the activate response
    when(fakeTrackingService.sendHttpRequest(RequestType.Post,
            'https://decision.flagship.io/v2/activate', any, any,
            timeoutMs: TIMEOUT_REQUEST))
        .thenAnswer((_) async {
      return http.Response("mock", 200);
    });

    // Mock the fetch response
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

    // Start Flagship with hidden strategy
    await Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey",
        config: ConfigBuilder()
            .withTrackingConfig(TrackingManagerConfig(
                batchStrategy: BatchCachingStrategy
                    .NO_BATCHING_CONTINUOUS_CACHING_STRATEGY))
            .build());
    // create new visitor
    var user = Flagship.newVisitor("userWithHidden").build();
    // Set the mocks
    user.trackingManager = fakeTrackingMgr;
    user.config.decisionManager = fakeApi;
    // Fetch
    user.fetchFlags().whenComplete(() async {
      // Get Flag             "":"val_A",
      var flagTest = user.getFlag("key_A", "dfl");
      // Activate
      // Failed the activate
      when(fakeTrackingService.sendHttpRequest(RequestType.Post,
              'https://decision.flagship.io/v2/activate', any, any,
              timeoutMs: TIMEOUT_REQUEST))
          .thenAnswer((_) async {
        return http.Response("mock", 400);
      });
      flagTest.value();
      // Set the consent to false
      user.setConsent(false);
    });
  });
}
