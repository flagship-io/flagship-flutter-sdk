import 'dart:convert';
import 'dart:io';
import 'package:flagship/api/endpoints.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/dataUsage/data_usage_tracking.dart';
import 'package:flagship/dataUsage/observer.dart';
import 'package:flagship/decision/bucketing_process.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/decision/polling/polling.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/model/bucketing.dart';
import 'package:flagship/model/campaigns.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BucketingManager extends DecisionManager with Observable {
  final int intervalPolling;
  Polling? polling;
  bool fileExists = true;

  Map<String, dynamic>? assignationHistory;

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  String lastModfiedKey = "FSLastModifiedScript";
  String bucketingFolder = "/flagship_bucketing/";
  String fileName = "bucketing.json";

  DataUsageTracking? bkDataUsage;

  BucketingManager(Service service, this.intervalPolling) : super(service) {
    this.addObserver(DataUsageTracking.sharedInstance());
  }

  @override
  Future<Campaigns> getCampaigns(
      String envId,
      String visitorId,
      String? anonymousId,
      bool hasConsented,
      Map<String, Object> context) async {
    // Read File before
    String? jsonString = await _readFile().catchError((error) {
      Flagship.logger(Level.ALL,
          "Error on reading the saved bucketing or the file doesn't exist");
      return null;
    });
    if (jsonString != null) {
      Bucketing bucketingObject = Bucketing.fromJson(json.decode(jsonString));
      return bucketVariations(
          visitorId, bucketingObject, context, assignationHistory ?? {});
    } else {
      Flagship.logger(Level.ALL, "Flagship, Failed to synchronize");
      return Campaigns(visitorId, false, []);
    }
  }

  _downloadScript() async {
    SharedPreferences prefs = await _prefs;
    // Create url
    String urlString = Endpoints.BUCKETING_SCRIPT
        .replaceFirst("%s", Flagship.sharedInstance().envId ?? "");

    var response = await this.service.sendHttpRequest(
        RequestType.Get,
        urlString,
        {"if-modified-since": prefs.getString(lastModfiedKey) ?? ""},
        null,
        timeoutMs:
            Flagship.sharedInstance().getConfiguration()?.timeout ?? TIMEOUT);
    switch (response.statusCode) {
      case 200:
        Flagship.logger(Level.ALL, response.body, isJsonString: true);
        String? lastModified = response.headers["last-modified"];
        if (lastModified != null) {
          prefs.setString(lastModfiedKey, lastModified);
        }
        // Save response body
        _saveFile(response.body);

        // Notify observer

        visitor.notifyObservers({
          "label": CriticalPoints.VISITIR_SEND_ACTIVATE.name,
          "visitor": this.visitor,
          "hit": activateHit
        });

        break;
      case 304:
        Flagship.logger(Level.ALL,
            "The bucketing script is not modified since last download");
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

  // Save the response into the file
  _saveFile(String body) async {
    final directory = await getApplicationDocumentsDirectory();
    Directory bucketingDirectory =
        await Directory.fromUri(Uri.file(directory.path + bucketingFolder))
            .create(recursive: true)
            .catchError((error) {
      Flagship.logger(Level.DEBUG,
          "Enable to create the directory to save the buckting file ");
      throw Exception('Flagship, Failed to save file');
    });
    // We got the path to save the json file
    File jsonFile = File(bucketingDirectory.path + fileName);
    jsonFile.writeAsString(body);
  }

// Read the saved file
  Future<String?> _readFile() async {
    final directory = await getApplicationDocumentsDirectory();
    File jsonFile = File(directory.path + bucketingFolder + fileName);
    if (jsonFile.existsSync() == true) {
      return jsonFile.readAsStringSync();
    } else {
      throw Exception('Flagship, Failed to read bucketing script');
    }
  }

  void updateAssignationHistory(Map<String, dynamic> newAssign) {
    if (this.assignationHistory == null) {
      this.assignationHistory = Map.fromEntries(newAssign.entries);
    } else {
      this.assignationHistory?.clear();
      this.assignationHistory?.addEntries(newAssign.entries);
    }
  }
}
