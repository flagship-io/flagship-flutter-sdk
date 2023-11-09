import 'package:flagship/api/endpoints.dart';
import 'package:flagship/cache/default_cache.dart';
import 'package:flagship/dataUsage/data_report_queue.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/model/account_settings.dart';
import 'package:flagship/model/flag.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/utils/flagship_tools.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flagship/visitor.dart';
import 'package:http/http.dart';
import 'package:murmurhash/murmurhash.dart';

part 'trouble_shooting.g.dart';

// Data usage label
String dataUsageLabel = "SDK_CONFIG";

// Allocation threshold for data usage tracking
int dataUsageAllocationThreshold = 10;

class DataUsageTracking {
  factory DataUsageTracking.sharedInstance() {
    return _singleton;
  }

  DataUsageTracking._internal() {
    _hasConsented = false;
    troubleShootingReportAllowed = false;
  }

  // TroubleShooting
  Troubleshooting? _troubleshooting;
  // VisitorId
  String visitorId = "";
  // Is data tracking is allowed
  bool troubleShootingReportAllowed = false;

  bool dataUsageTrackingReportAllowed = true;
  // if the visitor has consented
  bool _hasConsented = false;

  String? visitorSessionId; // relative to session creation

  DataReportQueue? dataReport;

  FlagshipConfig? sdkConfig;

  // Internal Singelton
  static final DataUsageTracking _singleton = DataUsageTracking._internal();

  configureDataUsage(Troubleshooting? troubleshooting, String visitorId,
      bool hasConsented, FlagshipConfig sdkConfig) {
    _singleton.sdkConfig = sdkConfig;
    _singleton._troubleshooting = troubleshooting;
    _singleton.visitorId = visitorId;
    _singleton.dataReport = DataReportQueue();
    _singleton.visitorSessionId = FlagshipTools.generateUuidv4().toString();
    _singleton._hasConsented = hasConsented;
    _singleton.evaluateDataUsageTrackingAllocated();
  }

  configureDataUsageWithVisitor(Troubleshooting? troubleshooting, Visitor v) {
    _singleton.sdkConfig = v.config;
    _singleton._troubleshooting = troubleshooting;
    _singleton.visitorId = v.visitorId;
    _singleton.dataReport = DataReportQueue();
    _singleton.visitorSessionId = FlagshipTools.generateUuidv4().toString();
    _singleton._hasConsented = v.getConsent();
    _singleton.evaluateDataUsageTrackingAllocated();
  }

  void updateTroubleshooting(Troubleshooting? trblShooting) {
    _singleton._troubleshooting = trblShooting;
    // Re evaluate the conditions of datausagetracking
    _singleton.evaluateTroubleShootingConditions();
  }

  void updateConsent(bool newValue) {
    _singleton._hasConsented = newValue;
    _singleton..evaluateTroubleShootingConditions();
  }

// Evaluate conditions to allow TS (trouble shooting) reporting
  void evaluateTroubleShootingConditions() {
    // To allow the dataUsageTracking we have to check
    _singleton
      ..troubleShootingReportAllowed = isTimeSlotValide() && // TimeSlot

          isBucketTroubleshootingAllocated() && // Bucket Allocation for TR

          isVisitorHasConsented(); // Visitor Consent

    if (_singleton.troubleShootingReportAllowed) {
      Flagship.logger(Level.ALL,
          "-------------- Troubleshooting Allowed ✅✅✅✅✅ ---------------");
    } else {
      //  Flagship.logger(Level.ALL,
      //     "-------------- Trouble shooting NOT Allowed ❌❌❌❌❌ --------------");
    }
  }

  bool isTimeSlotValide() {
    try {
      // Get the dates
      DateTime startDate =
          DateTime.parse(_singleton._troubleshooting?.startDate ?? "");

      DateTime endDate =
          DateTime.parse(_singleton._troubleshooting?.endDate ?? "");

      // Get the actual date
      DateTime actualDate = DateTime.now();
      return actualDate.isAfter(startDate) && actualDate.isBefore(endDate);
    } catch (e) {
      Flagship.logger(Level.DEBUG, e.toString());
      return false;
    }
  }

  bool isBucketTroubleshootingAllocated() {
    // Calculate the bucket allocation
    if (_singleton._troubleshooting?.endDate != null) {
      String combinedId = this.visitorId + (_troubleshooting?.endDate ?? "");
      int hashAlloc = (MurmurHash.v3(combinedId, 0) % 100);

      Flagship.logger(Level.INFO,
          "The hash allocation for TR bucket is $hashAlloc ------------");

      int traf = (_troubleshooting?.traffic ?? 0);
      Flagship.logger(Level.INFO,
          "The range allocation for TR bucket is $traf  ------------");

      return (hashAlloc <= (_troubleshooting?.traffic ?? 0));
    } else {
      return false;
    }
  }

// Evaluate data usage to allow reporting
  void evaluateDataUsageTrackingAllocated() {
    // Calculate the bucket allocation
    String combinedId = this.visitorId +
        DateTime.now().year.toString() +
        DateTime.now().month.toString() +
        DateTime.now().day.toString();
    int hashAlloc = (MurmurHash.v3(combinedId, 0) % 100);

    Flagship.logger(Level.INFO,
        "The hash allocation for Datausage tracking  bucket is $hashAlloc ");
    bool ret = _singleton.sdkConfig?.disableDeveloperUsageTracking ?? false;

    _singleton.dataUsageTrackingReportAllowed =
        (hashAlloc <= dataUsageAllocationThreshold) && !ret;
  }

  bool isVisitorHasConsented() {
    return _singleton._hasConsented;
  }

  // Send Hit for tracking TR
  void _sendTroubleShootingReport(TroubleshootingHit trHit) {
    if (_singleton.troubleShootingReportAllowed == true) {
      _singleton.dataReport?.sendReportData(trHit);
    }
  }

  void _sendDataUsageTracking(DataUsageHit duHit) {
    if (_singleton.dataUsageTrackingReportAllowed) {
      _singleton.dataReport?.sendReportData(duHit);
    } else {
      Flagship.logger(Level.INFO, "Sending developer data usage not allowed");
    }
  }

// Create Trouble shooting information for Fetch flags
  void processTSFetching(Visitor visitor) {
    Map<String, String> criticalJson = {};
    criticalJson = _createTSVisitorFormat(visitor);
    // Add vid aid,uuid
    criticalJson.addEntries(_createTrioIds(visitor).entries);
    // Send TS report
    _sendTroubleShootingReport(TroubleshootingHit(
        visitorId, CriticalPoints.VISITOR_FETCH_CAMPAIGNS.name, criticalJson));
  }

// Create trouble shooting information for xpc
  void processTSXpc(String label, Visitor visitor) {
    Map<String, String> criticalJson = {};
    criticalJson = _createTSxpc(visitor);
    // Add TRIO vid aid,uuid
    criticalJson.addEntries(_createTrioIds(visitor).entries);
    // Send TS report
    _sendTroubleShootingReport(
        TroubleshootingHit(visitorId, label, criticalJson));
  }

  // Create Trouble shooting information for hits
  void processTroubleShootingHits(String label, Visitor visitor, BaseHit hit) {
    Map<String, String> criticalJson = {};

    criticalJson = _createTSendHit(visitor, hit);

    // Add vid aid,uuid
    criticalJson.addEntries(_createTrioIds(visitor).entries);
    // Send TS report
    _sendTroubleShootingReport(
        TroubleshootingHit(visitorId, label, criticalJson));
  }

  // Create trouble shooting information for the request
  void processTroubleShootingHttp(String label, Response resp) {
    // get request
    Map<String, String> criticalJson = {};

    try {
      criticalJson = _createTSHttp(resp.request, resp);
      print(criticalJson);
    } on Exception catch (e) {
      Flagship.logger(Level.EXCEPTIONS, e.toString());
      return;
    }

    // Add Trio vid aid,uuid
    criticalJson.addEntries(_createTrioIds(null).entries);
    // Send trouble shooting report
    _sendTroubleShootingReport(
        TroubleshootingHit(visitorId, label, criticalJson));
  }

// Create trouble shooting flag infromation
  void proceesTroubleShootingFlag(String label, Flag f, Visitor v) {
    Map<String, String> criticalJson = {};
    criticalJson = createTroubleShooitngFlag(f, v);
    // Add vid aid,uuid
    criticalJson.addEntries(_createTrioIds(v).entries);
    // Add Context
    criticalJson.addEntries(_createTRContext(v).entries);
    // Send TS report
    _sendTroubleShootingReport(
        TroubleshootingHit(visitorId, label, criticalJson));
  }

  // Errors
  void processTroubleShootingException(Visitor? v, Object error) {
    Map<String, String> criticalJson = {};

    if (v != null) {
      // Add context
      criticalJson.addEntries(_createTRContext(v).entries);
    }

    /// Add ids
    criticalJson.addEntries(_createTrioIds(v).entries);
    // Add error message
    criticalJson.addEntries({"error.message": error.toString()}.entries);
    // Send TS reporting
    _sendTroubleShootingReport(TroubleshootingHit(
        visitorId, CriticalPoints.ERROR_CATCHED.name, criticalJson));
  }

  // Create data usage information
  void processDataUsageTracking(Visitor v) {
    Map<String, String> dataUsageJson = {};

    // Add SDK Config infos
    dataUsageJson.addEntries(_createSdkConfig(_singleton.sdkConfig).entries);
    // Send Data usage report
    _sendDataUsageTracking(DataUsageHit(
        this.visitorSessionId.toString(), dataUsageLabel, dataUsageJson));
  }

  ///////////////////////
  // Private functions //
  ///////////////////////

  // Create trio ids visitorId / anonymousId / instanceId
  Map<String, String> _createTrioIds(Visitor? v) {
    return {
      "visitor.visitorId": v?.visitorId ?? this.visitorId,
      "visitor.anonymousId": v?.anonymousId.toString() ?? "",
      "visitor.instanceId": this.visitorSessionId ?? ""
    };
  }

  // Create the trouble shooting visitor information
  Map<String, String> _createTSVisitorFormat(Visitor visitor) {
    Map<String, String> sdkSettings = {
      "visitor.consent": visitor.getConsent().toString(),
      "visitor.isAuthenticated": visitor.isAuthenticated().toString(),
    };

    visitor.modifications.forEach((key, value) {
      sdkSettings.addEntries(
          {"visitor.campaigns.$key": value.toJson().toString()}.entries);
    });
    // Add the sdk config entries
    sdkSettings.addEntries(_createSdkConfig(_singleton.sdkConfig).entries);
    // Add the Flag entries
    sdkSettings.addEntries(_createTRFlagsInfo(visitor.modifications).entries);
    // Add the context entries
    sdkSettings.addEntries(_createTRContext(visitor).entries);
    // Return the settings
    return sdkSettings;
  }
}

enum CriticalPoints {
  // Trigger on fetch flags
  VISITOR_FETCH_CAMPAIGNS,
  // Trigger on authenticate
  VISITOR_AUTHENTICATE,
  // Trigger on unAuthenticate
  VISITOR_UNAUTHENTICATE,
  // Trigger on sending Hit
  VISITOR_SEND_HIT,
  // Trigger on sending activate
  VISITOR_SEND_ACTIVATE,
  // Http call
  HTTP_CALL,
  // Trigger when the bucketing route responds with code 200
  SDK_BUCKETING_FILE,
  // Trigger when the bucketing route responds with error
  SDK_BUCKETING_FILE_ERROR,
  // Trigger when the campaigns route responds with an error
  GET_CAMPAIGNS_ROUTE_RESPONSE_ERROR,
  // Trigger when a batch request failed
  SEND_BATCH_HIT_ROUTE_RESPONSE_ERROR,
  // Trigger when a activate request failed
  SEND_ACTIVATE_HIT_ROUTE_ERROR,
  // Trigger when the Flag.getValue method is called and no flag is found
  GET_FLAG_VALUE_FLAG_NOT_FOUND,
  // Trigger when the Flag.visitorExposed method is called and no flag is found
  VISITOR_EXPOSED_FLAG_NO_FOUND,
  // Trigger when the Flag.visitorExposed method is called and the flag value has a different type with default value
  GET_FLAG_VALUE_TYPE_WARNING,
  // Trigger when the SDK catches any other error but those listed here.
  ERROR_CATCHED
}
