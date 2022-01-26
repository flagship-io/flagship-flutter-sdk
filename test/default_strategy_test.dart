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
import 'package:flagship/hits/event.dart';
import 'test_tools.dart';

@GenerateMocks([Service])
void main() {
  Map<String, String> fsHeaders = {
    "x-api-key": "apiKey",
    "x-sdk-client": "flutter",
    "x-sdk-version": FlagshipVersion,
    "Content-type": "application/json"
  };

  Object data = json
      .encode({"visitorId": "visitorId", "context": {}, "trigger_hit": false});

  MockService fakeService = MockService();
  ApiManager fakeApi = ApiManager(fakeService);
  test('Test API with default startegy', () async {
    String fakeResponse =
        await ToolsTest.readFile('test_resources/decisionApi.json') ?? "";
    when(fakeService.sendHttpRequest(
            RequestType.Post,
            'https://decision.flagship.io/v2/bkk9glocmjcg0vtmdlrr/campaigns/?exposeAllKeys=true',
            fsHeaders,
            data,
            timeoutMs: TIMEOUT))
        .thenAnswer((_) async {
      return http.Response(fakeResponse, 200);
    });

    FlagshipConfig config = FlagshipConfig(TIMEOUT);
    config.decisionManager = fakeApi;
    Flagship.start("bkk9glocmjcg0vtmdlrr", "apiKey", config: config);

    var v1 = Flagship.newVisitor("visitorId", {});
    expect(v1.getConsent(), true);
    v1.synchronizeModifications().then((value) {
      expect(Flagship.getStatus(), Status.READY);

      /// Activate
      v1.activateModification("aliasTer");

      /// Get Modification
      expect(v1.getModification('aliasTer', 'default'), "testValue");

      expect(v1.getModification('aliasDouble', 100.0), 12.0);

      //

      /// Get infos
      var infos = v1.getModificationInfo('alias');
      expect(infos?.length, 4);
      expect(infos!['campaignId'], "bsffhle242b2l3igq4dg");
      expect(infos['variationGroupId'], "bsffhle242b2l3igq4egaa");
      expect(infos['variationId'], "bsffhle242b2l3igq4f0");
      expect(infos['isReference'], true);

      /// Get info for none exting key
      var infosBis = v1.getModificationInfo('noKey');
      expect(infosBis, null);

      /// Wrong type
      expect(v1.getModification('aliasTer', 12), 12);
      expect(v1.getModification('aliasDouble', "default"), "default");

      /// Send hit
      v1.sendHit(
          Event(action: "action", category: EventCategory.Action_Tracking));

      /// Send consent hit
      v1.sendHit(Consent(hasConsented: false));
    });
  });
}

// // Read the mock response
// Future<String?> readFile(String path) async {
//   final file = new File(testPath(path));
//   final jsonString = await file.readAsString();
//   return jsonString;
// }

// /// https://github.com/terryx/flutter-muscle/blob/master/github_provider/test/utils/test_path.dart
// String testPath(String relativePath) {
//   //Fix vscode test path
//   Directory current = Directory.current;
//   String path =
//       current.path.endsWith('/test') ? current.path : current.path + '/test';

//   return path + '/' + relativePath;
// }
