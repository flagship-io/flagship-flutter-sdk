import 'dart:convert';
import 'dart:io';
import 'package:flagship/api/endpoints.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/decision/bucketing_process.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/decision/polling/polling.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flagship/model/bucketing.dart';
import 'package:flagship/model/campaigns.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BucketingManager extends DecisionManager {
  final int intervalPolling;
  Polling? polling;
  bool fileExists = true;

  late Future<SharedPreferences> _prefs;
  late Campaigns campaigns;

  String lastModfiedKey = "FSLastModifiedScript";
  String bucketingFolder = "/flagship/Bucketing/";
  String fileName = "bucketing.json";

  BucketingManager(Service service, this.intervalPolling) : super(service) {
    _prefs = SharedPreferences.getInstance();
  }

  @override
  Future<Campaigns> getCampaigns(String envId, String visitorId, Map<String, Object> context) async {
    /// Read File before
    String jsonString = await _readFile().catchError((error) {
      Flagship.logger(Level.ALL, "Error on reading the saved bucketing file");
    });

    Bucketing bucketingObject = Bucketing.fromJson(json.decode(jsonString));

    // Send Keys context when the consent is true && the panic mode is not activated
    if (isConsent() && bucketingObject.panic == false) {
      // Send the context
      _sendKeyContext(envId, visitorId, context);
    }
    return bucketVariations(visitorId, bucketingObject, context);
  }

  _downloadScript() async {
    SharedPreferences prefs = await _prefs;
    // Create url
    String urlString = Endpoints.BucketingScript.replaceFirst("%s", Flagship.sharedInstance().envId ?? "");

    var response = await this.service.sendHttpRequest(
        // {"if-modified-since": prefs.getString(lastModfiedKey) ?? ""}
        RequestType.Get,
        urlString,
        {},
        null,
        timeoutMs: Flagship.sharedInstance().getConfiguration()?.timeout ?? TIMEOUT);
    switch (response.statusCode) {
      case 200:
        Flagship.logger(Level.ALL, response.body, isJsonString: true);
        String? lastModified = response.headers["last-modified"];
        if (lastModified != null) {
          prefs.setString(lastModfiedKey, lastModified);
        }
        // Save response body
        _saveFile(response.body);
        break;
      case 304:
        Flagship.logger(Level.ALL, "The bucketing script is not modified since last download");
        break;
      default:
        Flagship.logger(Level.ALL, "Failed to download script for bucketing");
        throw Exception('Flagship, Failed on getting bucketing script');
    }
  }

  @override
  void startPolling() {
    // Create and launch the polling process here...
    this.polling = Polling(intervalPolling, () async {
      await _downloadScript();
    });
    this.polling?.start();
  }

  _sendKeyContext(String envId, String visitorId, Map<String, dynamic> currentContext) async {
    String urlString = Endpoints.DECISION_API + envId + Endpoints.EVENTS;

    Flagship.logger(Level.INFO, 'Send Context :' + urlString);

    // Create headers
    Map<String, String> headers = {
      "x-api-key": Flagship.sharedInstance().apiKey ?? "",
      "x-sdk-client": "flutter",
      "x-sdk-version": FlagshipVersion,
      "Content-type": "application/json"
    };
    // Create data to post
    Object dataToPost = json.encode({"visitor_id": visitorId, "data": currentContext, "type": "CONTEXT"});

    // send context
    this.service.sendHttpRequest(RequestType.Post, urlString, headers, dataToPost);
  }

  // Save the response into the file
  _saveFile(String body) async {
    final directory = await getApplicationDocumentsDirectory();
    Directory bucketingDirectory =
        await Directory.fromUri(Uri.file(directory.path + bucketingFolder)).create(recursive: true).catchError((error) {
      print("Enable to create the directory to save the buckting file ");
    });
    // We got the path to save the json file
    File jsonFile = File(bucketingDirectory.path + fileName);
    jsonFile.writeAsString(body);
  }

// Read the saved file
  Future<String> _readFile() async {
    final directory = await getApplicationDocumentsDirectory();
    File jsonFile = File(directory.path + bucketingFolder + fileName);
    if (jsonFile.existsSync() == true) {
      return jsonFile.readAsStringSync();
    } else {
      throw Exception('Flagship, Failed to read bucketing script');
    }
  }
}
