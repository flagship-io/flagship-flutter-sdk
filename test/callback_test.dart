import 'package:flagship/decision/api_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/status.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'service_test.mocks.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/flagship_config.dart';
import 'test_tools.dart';

@GenerateMocks([Service])
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  databaseFactory = databaseFactoryFfi;

  Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey");
  MockService fakePanicService = MockService();
  ApiManager fakePanicApi = ApiManager(fakePanicService);

  test('FlagshipConfig ', () async {
    FlagshipConfig conf =
        ConfigBuilder().withTimeout(4000).withLogLevel(Level.ALL).build();

    expect(conf.onSdkStatusChanged, null);
    expect(conf.timeout, 4000);
    expect(conf.decisionMode, Mode.DECISION_API);
  });

  test('Test API with panic mode', () async {
    String fakeResponse =
        await ToolsTest.readFile('test_resources/decisionApiPanic.json') ?? "";
    when(fakePanicService.sendHttpRequest(
            RequestType.Post,
            'https://decision.flagship.io/v2/bkk9glocmjcg0vtmdlrr/campaigns/?exposeAllKeys=true&extras[]=accountSettings',
            any,
            any,
            timeoutMs: TIMEOUT))
        .thenAnswer((_) async {
      return http.Response(fakeResponse, 200);
    });

    FlagshipConfig config = ConfigBuilder().withTimeout(TIMEOUT).build();
    config.onSdkStatusChanged = (newStatus) {
      if (newStatus == FSSdkStatus.SDK_PANIC) {
        // ignore: deprecated_member_use_from_same_package
        expect(Flagship.getCurrentVisitor()?.getModification('key1', 12), 12);
        expect(newStatus, Flagship.getStatus());
      }
    };

    config.decisionManager = fakePanicApi;
    Flagship.sharedInstance().onUpdateState(FSSdkStatus.SDK_NOT_INITIALIZED);
    Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey", config: config);

    var v1 = Flagship.newVisitor(visitorId: "visitorId", hasConsented: true)
        .withContext({}).build();
    Flagship.setCurrentVisitor(v1);

    // ignore: deprecated_member_use_from_same_package
    v1.synchronizeModifications().whenComplete(() {});
  });
}
