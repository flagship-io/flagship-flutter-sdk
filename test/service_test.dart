import 'dart:io';
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

  Object data = json.encode({"visitorId": "visitorId", "context": {}});

  MockService fakeService = MockService();
  ApiManager fakeApi = ApiManager(fakeService);
  test('Test API manager with reponse ', () async {
    /// prepare response
    String fakeResponse =
        await readFile('test_resources/decisionApi.json') ?? "";
    when(fakeService.sendHttpRequest(
            RequestType.Post,
            'https://decision.flagship.io/v2/bkk9glocmjcg0vtmdlrr/campaigns/?exposeAllKeys=true',
            fsHeaders,
            data,
            timeoutMs: 2))
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

// Read the mock response
Future<String?> readFile(String path) async {
  final file = new File(testPath(path));
  final jsonString = await file.readAsString();
  return jsonString;
}

/// https://github.com/terryx/flutter-muscle/blob/master/github_provider/test/utils/test_path.dart
String testPath(String relativePath) {
  //Fix vscode test path
  Directory current = Directory.current;
  String path =
      current.path.endsWith('/test') ? current.path : current.path + '/test';

  return path + '/' + relativePath;
}
