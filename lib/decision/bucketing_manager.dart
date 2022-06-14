import 'dart:convert';
import 'dart:io';

import 'package:flagship/api/endpoints.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/decision/polling/polling.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/model/bucketing.dart';
import 'package:flagship/model/campaigns.dart';
import 'package:http/http.dart';
import '../utils/logger/log_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BucketingManager extends DecisionManager {
  late Polling polling;
  int intervalPolling = 60;
  bool fileExists = true;
  String fileName = "bucketing.json";
  late Future<SharedPreferences> _prefs;

  /// Connect this with the config entry

  late Campaigns campaigns;

  String lastModfiedKey = "FSLastModifiedScript";

  BucketingManager(Service service) : super(service) {
    _prefs = SharedPreferences.getInstance();
  }

  @override
  Future<Campaigns> getCampaigns(String envId, String visitorId, Map<String, Object> context) async {
    /// Read File before
    ///
    String result = await _readFile().catchError((error) {
      print("Error on read file from cache");
    });

    Bucketing object = convertToBuckeitng(result);

    /// Here we have to run the targeting
    return campaigns;

    /// to do later
  }

  _downloadScript() async {
    SharedPreferences prefs = await _prefs;
    // Create url
    String urlString = Endpoints.BucketingScript.replaceFirst("%s", Flagship.sharedInstance().envId ?? "");

    var response = await this.service.sendHttpRequest(
        RequestType.Get, urlString, {"if-modified-since": prefs.getString(lastModfiedKey) ?? ""}, null,
        timeoutMs: Flagship.sharedInstance().getConfiguration()?.timeout ?? TIMEOUT);
    switch (response.statusCode) {
      case 200:
        Flagship.logger(Level.ALL, response.body, isJsonString: true);
        // Retreive the last update

        String? lastModified = response.headers["last-modified"];
        if (lastModified != null) {
          prefs.setString(lastModfiedKey, lastModified);
        }
        // save respnse body
        _saveFile(response.body);
        break;
      case 304:
        Flagship.logger(Level.ALL, "The bucketing script is not modified since last download");
        break;
      default:
        Flagship.logger(
          Level.ALL,
          "Failed to download script for bucketing",
        );
        throw Exception('Flagship, Failed on get bucketing script');
    }
  }

  @override
  void startPolling() {
    // launch the polling process here
    this.polling = Polling(intervalPolling, () async {
      await _downloadScript();
    });
    this.polling.start();
  }

  _saveFile(String body) async {
    final directory = await getApplicationDocumentsDirectory();
    Directory bucketingDirectory = await Directory.fromUri(Uri.file(directory.path + "/flagship/Bucketing"))
        .create(recursive: true)
        .catchError((error) {
      print("Enable to create the directory to save the buckting file ");
    });

    /// We got the path to save the json file
    File jsonFile = File(bucketingDirectory.path + "/" + fileName);
    jsonFile.writeAsString(body);
  }

  Future<String> _readFile() async {
    final directory = await getApplicationDocumentsDirectory();
    File jsonFile = File(directory.path + "/flagship/Bucketing/" + fileName);
    if (jsonFile.existsSync() == true) {
      return jsonFile.readAsStringSync();
    } else {
      throw Exception('Flagship, Failed to read bucketing script');
    }
  }

  Bucketing convertToBuckeitng(String jsonString) {
    Bucketing result = Bucketing.fromJson(json.decode(jsonString));
    return result;
  }
}
