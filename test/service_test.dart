import 'package:flagship/decision/api_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'service_test.mocks.dart';
import 'package:flagship/api/service.dart';
import 'test_tools.dart';

// Generate a MockClient using the Mockito package.
// Create new instances of this class in each test.
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

  MockService fakeService = MockService();
  ApiManager fakeApi = ApiManager(fakeService);
  test('Test API manager with reponse ', () async {
    /// prepare response
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
    fakeApi.getCampaigns("bkk9glocmjcg0vtmdlrr", "visitorId", {}).then((value) {
      fakeApi.getModifications(value.campaigns);
      expect(fakeApi.isConsent(), true);
      fakeApi.updateConsent(false);
      expect(fakeApi.isConsent(), false);
      expect(fakeApi.isPanic(), false);
    });
  });
}
