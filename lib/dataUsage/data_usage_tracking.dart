import 'dart:io';

import 'package:flagship/api/endpoints.dart';
import 'package:flagship/cache/default_cache.dart';
import 'package:flagship/dataUsage/data_report_queue.dart';
import 'package:flagship/dataUsage/observer.dart';
import 'package:flagship/decision/bucketing_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/model/account_settings.dart';
import 'package:flagship/model/flag.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/utils/flagship_tools.dart';
import 'package:flagship/visitor.dart';
import 'package:http/http.dart';
import 'package:murmurhash/murmurhash.dart';

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
  }

  configureDataUsageWithVisitor(Troubleshooting? troubleshooting, Visitor v) {
    _singleton.sdkConfig = sdkConfig;
    _singleton._troubleshooting = troubleshooting;
    _singleton.visitorId = v.visitorId;
    _singleton.dataReport = DataReportQueue();
    _singleton.visitorSessionId = FlagshipTools.generateUuidv4().toString();
    _singleton._hasConsented = v.getConsent();
  }

  void updateTroubleshooting(Troubleshooting? trblShooting) {
    _singleton._troubleshooting = trblShooting;
    // Re evaluate the conditions of datausagetracking
    _singleton.evaluateDataUsageTrackingConditions();
  }

  void updateConsent(bool newValue) {
    _singleton._hasConsented = newValue;
    _singleton..evaluateDataUsageTrackingConditions();
  }

  void evaluateDataUsageTrackingConditions() {
    // To allow the dataUsageTracking we have to check
    _singleton
      ..troubleShootingReportAllowed = isTimeSlotValide() && // TimeSlot

          isBucketTroubleshootingAllocated() && // Bucket Allocation for TR

          isVisitorHasConsented(); // Visitor Consent

    if (_singleton.troubleShootingReportAllowed) {
      print("-------------- Data Usage Allowed ✅✅✅✅✅ ---------------");
    } else {
      print("-------------- Data Usage NOT Allowed ❌❌❌❌❌ --------------");
    }
  }

  bool isTimeSlotValide() {
    // Get the date
    DateTime startDate =
        DateTime.parse(_singleton._troubleshooting?.startDate ?? "");
    DateTime endDate =
        DateTime.parse(_singleton._troubleshooting?.endDate ?? "");
    // Get the actual date
    DateTime actualDate = DateTime.now();
    return actualDate.isAfter(startDate) && actualDate.isBefore(endDate);
  }

  bool isBucketTroubleshootingAllocated() {
    // Calculate the bucket allocation

    if (_singleton._troubleshooting?.endDate != null) {
      String combinedId = this.visitorId + (_troubleshooting?.endDate ?? "");
      int hashAlloc = (MurmurHash.v3(combinedId, 0) % 100);

      print(
          "-------- DEV --- The hash allocation for TR bucket is $hashAlloc ------------");

      int traf = (_troubleshooting?.traffic ?? 0);
      print(
          "-------- DEV --- The range allocation for TR bucket is $traf  ------------");

      return (hashAlloc <= (_troubleshooting?.traffic ?? 0));
    } else {
      return false;
    }
  }

  bool isVisitorHasConsented() {
    return _singleton._hasConsented;
  }

  // Send Hit for tracking Usage
  void sendDataUsageTracking(TroubleShootingHit hitUsage) {
    // if (_singleton.troubleShootingReportAllowed == true) { // TODO remove uncomment
    print("Send Data Usage Tracking ...........");
    _singleton.dataReport?.sendReportData(hitUsage);
    //  }
  }

  void processTroubleShooting(String label, Visitor visitor) {
    print("----------------------- $label----------------------------");
    Map<String, dynamic> criticalJson = {};

    if (label == "VISITOR_FETCH_CAMPAIGNS") {
      criticalJson = _createTSVisitorFormat(visitor);
    } else if (label == "VISITOR_AUTHENTICATE") {
      criticalJson = _createTSxpc(visitor);
    } else if (label == "VISITOR_UNAUTHENTICATE") {
      criticalJson = _createTSxpc(visitor); // TODO refract later
    }
    // Add TRIO vid aid,uuid
    criticalJson.addEntries(_createTrioIds(visitor).entries);
    sendDataUsageTracking(TroubleShootingHit(visitorId, label, criticalJson));
  }

  /// HITS and ACTIVATE
  void processTroubleShootingHits(String label, Visitor visitor, BaseHit hit) {
    Map<String, dynamic> criticalJson = {};

    criticalJson = _createTSendHit(visitor, hit);

    // Add TRIO vid aid,uuid
    criticalJson.addEntries(_createTrioIds(visitor).entries);
    sendDataUsageTracking(TroubleShootingHit(visitorId, label, criticalJson));
  }

  /// HTTP request

  void processTroubleShootingHttp(String label, Response resp) {
    // get request
    Map<String, dynamic> criticalJson = {};

    try {
      criticalJson = _createTSHttp(resp.request, resp);
      print(criticalJson);
    } on Exception catch (e) {
      print(e.toString());
      print("processTroubleShootingHttp");
      return; // skip the function
    }

    // Add TRIO vid aid,uuid
    criticalJson.addEntries(_createTrioIds(null).entries);
    sendDataUsageTracking(TroubleShootingHit(visitorId, label, criticalJson));
  }

// FLags
  void proceesTroubleShootingFlag(String label, Flag f, Visitor v) {
    Map<String, dynamic> criticalJson = {};
    criticalJson = _createTroubleShooitngFlag(f, v);
    // Add TRIO vid aid,uuid
    criticalJson.addEntries(_createTrioIds(v).entries);
    sendDataUsageTracking(TroubleShootingHit(visitorId, label, criticalJson));
  }

  /// Errors
  void processTroubleShootingException(Visitor? v, Object error) {
    Map<String, dynamic> criticalJson = {};

    if (v != null) {
      // Add context
      criticalJson.addEntries(_createTRContext(v).entries);
    }

    /// Add ids
    criticalJson.addEntries(_createTrioIds(v).entries);
    // Add error message
    criticalJson.addEntries({"error.message": error.toString()}.entries);
    // Send Error
    sendDataUsageTracking(TroubleShootingHit(
        visitorId, CriticalPoints.ERROR_CATCHED.name, criticalJson));
  }

/////////////////////////
  /// Private functions  //
/////////////////////////

  // Create a trio of visitorId / anonymousId / instanceId
  Map<String, dynamic> _createTrioIds(Visitor? v) {
    return {
      "visitor.visitorId": v?.visitorId ?? this.visitorId,
      "visitor.anonymousId": v?.anonymousId.toString(),
      "visitor.instanceId": this.visitorSessionId
    };
  }

  Map<String, dynamic> _createTSVisitorFormat(Visitor visitor) {
    Map<String, dynamic> sdkSettings = {
      "visitor.consent": visitor.getConsent(),
      "visitor.campaigns": visitor.modifications.toString(),

      "visitor.isAuthenticated": "false",

      /// SDK
      "sdk.config.usingOnVisitorExposed": (sdkConfig?.onVisitorExposed != null),
      "sdk.config.usingCustomVisitorCache":
          (!(sdkConfig?.visitorCacheImp is DefaultCacheVisitorImp)).toString(),
      "sdk.config.usingCustomHitCache":
          (!(sdkConfig?.hitCacheImp is DefaultCacheHitImp)).toString(),
      "sdk.config.usingCustomLogManager": "true",
      "sdk.config.trackingManager.config.strategy":
          sdkConfig?.trackingManagerConfig.batchStrategy.name,
      " sdk.config.trackingManager.config.batchIntervals":
          sdkConfig?.trackingManagerConfig.batchIntervals.toString(),
      "sdk.config.timeout": sdkConfig?.timeout.toString(),
      "sdk.config.pollingTime": sdkConfig?.pollingTime.toString(),
      "sdk.config.mode": sdkConfig?.decisionMode.name,

      "sdk.config.decisionApiUrl": Endpoints.DECISION_API,
      "sdk.status": Flagship.getStatus().name,
      //  "sdk.lastInitializationTimestamp":
      "sdk.config.initialBucketing": "", // See later
      /// Flags
    };
    sdkSettings.addEntries(_createTRFlagsInfo(visitor.modifications).entries);
    sdkSettings.addEntries(_createTRContext(visitor).entries);

    return sdkSettings;
  }

  Map<String, dynamic> _createTRFlagsInfo(
      Map<String, Modification> modifications) {
    Map<String, dynamic> ret = {};

    modifications.forEach((flagKey, flagModification) {
      ret.addEntries({
        "visitor.flags.$flagKey.key": flagKey,
        "visitor.flags.$flagKey.value": flagModification.value.toString(),
        "visitor.flags.$flagKey.metadata.campaignId":
            flagModification.campaignId,
        "visitor.flags.$flagKey.metadata.variationGroupId":
            flagModification.variationGroupId,
        "visitor.flags.$flagKey.metadata.variationId":
            flagModification.variationId,
        "visitor.flags.$flagKey.metadata.isReference":
            flagModification.isReference.toString(),
        "visitor.flags.$flagKey.metadata.campaignType":
            flagModification.campaignType,
        "visitor.flags.$flagKey.metadata.slug": flagModification.slug
      }.entries);
    });

    return ret;
  }

  Map<String, dynamic> _createTRContext(Visitor v) {
    Map<String, Object> ctx = v.getContext();

    Map<String, dynamic> ret = {};
    ctx.forEach((ctxKey, ctxValue) {
      ret.addEntries({"visitor.context.$ctxKey": ctxValue.toString()}.entries);
    });
    return ret;
  }

// For the XPC
  Map<String, dynamic> _createTSxpc(Visitor v) {
    return {"visitor.context": _createTRContext(v)};
  }

// For the hit and activate
  Map<String, dynamic> _createTSendHit(Visitor v, Hit h) {
    return {"hit.content": h.bodyTrack.toString()};
  }

// For HTTP & Buckeitng
  Map<String, dynamic> _createTSHttp(BaseRequest? r, Response resp) {
    return {
      "http.request.headers": r?.headers.toString(),
      "http.request.method": r?.method,
      "http.request.url": r?.url.path,
      "http.response.body": resp.body.toString(),
      "http.response.headers": resp.headers.toString(),
      "http.response.code": resp.statusCode.toString(),
    };
  }

  Map<String, dynamic> _createTroubleShooitngFlag(Flag f, Visitor v) {
    return {
      "flag.key": f.key,
      "flag.defaultValue": f.defaultValue.toString(),
      "visitor.context": v.getContext().toString()
    };
  }
}

enum CriticalPoints {
  VISITOR_FETCH_CAMPAIGNS,
  VISITOR_AUTHENTICATE,
  VISITOR_UNAUTHENTICATE,
  VISITOR_SEND_HIT,
  VISITIR_SEND_ACTIVATE,
  HTTP_CALL,

  // HTTP CALL

  SDK_BUCKETING_FILE, // It will be triggered when the bucketing route responds with code 200
  SDK_BUCKETING_FILE_ERROR, // It will be triggered when the bucketing route responds with error
  GET_CAMPAIGNS_ROUTE_RESPONSE_ERROR, // It will be triggered when the campaigns route responds with an error
  SEND_BATCH_HIT_ROUTE_RESPONSE_ERROR, // When a batch request failed
  SEND_ACTIVATE_HIT_ROUTE_ERROR, // When a activate request failed

  // Warning flag
  GET_FLAG_VALUE_FLAG_NOT_FOUND, // It will be triggered when the Flag.getValue method is called and no flag is found
  GET_FLAG_VALUE_TYPEWARNING, // It will be triggered when the Flag.getValue method is called and the flag value has a different type with default value
  VISITOR_EXPOSED_FLAG_NO_FOUND, // It will be triggered when the Flag.visitorExposed method is called and no flag is found
  GET_FLAG_VALUE_TYPE_WARNING, // // It will be triggered when the Flag.visitorExposed method is called and the flag value has a different type with default value

  ERROR_CATCHED // It will be trigger when the SDK catches any other error but those listed here.
}
