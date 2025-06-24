import 'dart:convert';
import 'dart:io';
import 'package:flagship/api/endpoints.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/dataUsage/data_usage_tracking.dart';
import 'package:flagship/decision/bucketing_process.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/decision/polling/polling.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/model/bucketing.dart';
import 'package:flagship/model/campaigns.dart';
import 'package:flagship/status.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BucketingManager extends DecisionManager {
  final int intervalPolling;
  Polling? polling;
  bool fileExists = true;

  Map<String, dynamic>? assignationHistory;

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  String lastModfiedKey = "FSLastModifiedScript_%s";
  String bucketingFolder = "/flagship_bucketing/";
  String fileName = "bucketing_%s.json";

  DataUsageTracking? bkDataUsage;

  BucketingManager(Service service, this.intervalPolling) : super(service);

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
      return Campaigns(visitorId, false, [], null);
    }
  }

  Future<Bucketing?> _downloadScript() async {
    SharedPreferences prefs = await _prefs;
    // Create url
    String urlString = Endpoints.BUCKETING_SCRIPT
        .replaceFirst("%s", Flagship.sharedInstance().envId ?? "");

    var response = await this.service.sendHttpRequest(
        RequestType.Get,
        urlString,
        {
          "if-modified-since": prefs.getString(lastModfiedKey.replaceFirst(
                  "%s", Flagship.sharedInstance().envId.toString())) ??
              ""
        },
        null,
        timeoutMs:
            Flagship.sharedInstance().getConfiguration()?.timeout ?? TIMEOUT);
    switch (response.statusCode) {
      case 200:
        Flagship.logger(Level.ALL, utf8.decode(response.bodyBytes),
            isJsonString: true);
        String? lastModified = response.headers["last-modified"];
        if (lastModified != null) {
          prefs.setString(
              lastModfiedKey.replaceFirst(
                  "%s", Flagship.sharedInstance().envId.toString()),
              lastModified);
        }
        // Save response body
        _saveFile(utf8.decode(response.bodyBytes));
        // Report TR
        DataUsageTracking.sharedInstance().processTroubleShootingHttp(
            CriticalPoints.SDK_BUCKETING_FILE.name, response);
        // Update sdk status
        return Bucketing.fromJson(json.decode(utf8.decode(response.bodyBytes)));

      case 304:
        Flagship.logger(Level.ALL,
            "The bucketing script is not modified since last download");
        return null;
      default:
        // Report Troubleshooting
        DataUsageTracking.sharedInstance().processTroubleShootingHttp(
            CriticalPoints.SDK_BUCKETING_FILE_ERROR.name, response);
        Flagship.logger(Level.ALL, "Failed to download script for bucketing");
        throw Exception('Flagship, Failed on getting bucketing script');
    }
  }

  @override
  void startPolling() {
    // Create and launch the polling process here...
    this.polling = Polling(intervalPolling, () async {
      await _downloadScript().then(((bk) => {_updateStatus(bk)}));
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

    File jsonFile = File(bucketingDirectory.path +
        fileName.replaceFirst(
            "%s", Flagship.sharedInstance().envId.toString()));
    jsonFile.writeAsString(body);
  }

// Read the saved file
  Future<String?> _readFile() async {
    final directory = await getApplicationDocumentsDirectory();
    File jsonFile = File(directory.path +
        bucketingFolder +
        fileName.replaceFirst(
            "%s", Flagship.sharedInstance().envId.toString()));
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

// Refresh state
  void _updateStatus(Bucketing? bk_file) async {
    Bucketing? bucketingObject =
        (bk_file != null) ? bk_file : await _getSavedScript();

    if (bucketingObject != null) {
      Flagship.sharedInstance().onUpdateState(bucketingObject.panic
          ? FSSdkStatus.SDK_PANIC
          : FSSdkStatus.SDK_INITIALIZED);
      Flagship.sharedInstance().onUpdateState(bucketingObject.panic
          ? FSSdkStatus.SDK_PANIC
          : FSSdkStatus.SDK_INITIALIZED);
      // Update Settings
      Flagship.sharedInstance().eaiActivationEnabled =
          bucketingObject.accountSettings?.eaiActivationEnabled ?? false;
      Flagship.sharedInstance().eaiCollectEnabled =
          bucketingObject.accountSettings?.eaiCollectEnabled ?? false;
      DataUsageTracking.sharedInstance().updateTroubleshooting(
          bucketingObject.accountSettings?.troubleshooting);
    }
  }

  Future<Bucketing?> _getSavedScript() async {
    String? jsonString = await _readFile().catchError((error) {
      Flagship.logger(Level.ALL,
          "Error on reading the saved bucketing or the file doesn't exist");
      return null;
    });
    if (jsonString != null) {
      return Bucketing.fromJson(json.decode(jsonString));
    } else {
      Flagship.logger(Level.ALL, "Flagship, Failed to synchronize");
      return null;
    }
  }
}
