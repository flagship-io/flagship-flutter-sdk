import 'dart:io';

import 'package:flagship/api/endpoints.dart';
import 'package:flagship/cache/default_cache.dart';
import 'package:flagship/dataUsage/data_report_queue.dart';
import 'package:flagship/dataUsage/observer.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/model/account_settings.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/utils/flagship_tools.dart';
import 'package:flagship/visitor.dart';
import 'package:http/http.dart';
import 'package:murmurhash/murmurhash.dart';

class DataUsageTracking with Observer {
  factory DataUsageTracking.sharedInstance() {
    return _singleton;
  }

  DataUsageTracking._internal();

  // TroubleShooting
  Troubleshooting? _troubleshooting;
  // VisitorId
  String visitorId;
  // Is data tracking is allowed
  bool troubleShootingReportAllowed = false;
  // if the visitor has consented
  bool _hasConsented = false;

  String? visitorSessionId; // relative to session creation

  DataReportQueue? dataReport;

  FlagshipConfig sdkConfig;

  // Internal Singelton
  static final DataUsageTracking _singleton = DataUsageTracking._internal();

  DataUsageTracking(this._troubleshooting, this.visitorId, this._hasConsented,
      this.sdkConfig) {
    dataReport = DataReportQueue();

    visitorSessionId = FlagshipTools.generateUuidv4().toString();
  }

  void updateTroubleshooting(Troubleshooting? trblShooting) {
    _troubleshooting = trblShooting;
    // ReEvaluate the conditions of datausagetracking
    evaluateDataUsageTrackingConditions();
  }

  void updateConsent(bool newValue) {
    _hasConsented = newValue;
    evaluateDataUsageTrackingConditions();
  }

  void evaluateDataUsageTrackingConditions() {
    // To allow the dataUsageTracking we have to check
    troubleShootingReportAllowed = isTimeSlotValide() && // TimeSlot

        isBucketTroubleshootingAllocated() && // Bucket Allocation for TR

        isVisitorHasConsented(); // Visitor Consent

    if (troubleShootingReportAllowed) {
      print("-------------- Data Usage Allowed ✅✅✅✅✅ ---------------");
    } else {
      print("-------------- Data Usage NOT Allowed ❌❌❌❌❌ --------------");
    }
  }

  bool isTimeSlotValide() {
    // Get the date
    DateTime startDate = DateTime.parse(_troubleshooting?.startDate ?? "");
    DateTime endDate = DateTime.parse(_troubleshooting?.endDate ?? "");
    // Get the actual date
    DateTime actualDate = DateTime.now();
    return actualDate.isAfter(startDate) && actualDate.isBefore(endDate);
  }

  bool isBucketTroubleshootingAllocated() {
    // Calculate the bucket allocation

    if (_troubleshooting?.endDate != null) {
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
    return _hasConsented;
  }

  // Send Hit for tracking Usage
  void sendDataUsageTracking(TroubleShootingHit hitUsage) {
    if (troubleShootingReportAllowed == true) {
      print("Send Data Usage Tracking ...........");
      this.dataReport?.sendReportData(hitUsage);
    }
  }

  @override
  void update(Observable observable, Object arg) {
    if (arg is Map) {
      if (arg["label"] != null) {
        String outPutLabel = arg["label"];
        print("Troubleshooting from ---- $outPutLabel");
        if (arg["visitor"] != null && arg["visitor"] is Visitor) {
          var v = arg["visitor"] as Visitor;

          // get and format all others informations
          Map<String, dynamic> criticalJson = {};

          switch (outPutLabel) {
            case "VISITOR_FETCH_CAMPAIGNS":
              criticalJson = _createTSVisitorFormat(v);
              break;
            case "VISITOR_AUTHENTICATE":
              criticalJson = _createTSxpc(v);
              break;
            case "VISITOR_UNAUTHENTICATE":
              criticalJson = _createTSxpc(v);
              break;
            case "VISITOR_SEND_HIT":
            case "VISITIR_SEND_ACTIVATE":
              {
                try {
                  var h = arg["hit"] as Hit;
                  criticalJson = _createTSendHit(v, h);
                } on Exception catch (e) {
                  print(e.toString());
                  return; // skip the function
                }
              }
              break;
            case "SDK_BUCKETING_FILE": // It will be triggered when the bucketing route responds with code 200
            case "SDK_BUCKETING_FILE_ERROR": // It will be triggered when the bucketing route responds with error
            case "GET_CAMPAIGNS_ROUTE_RESPONSE_ERROR": // It will be triggered when the campaigns route responds with an error
            case "SEND_BATCH_HIT_ROUTE_RESPONSE_ERROR": // When a batch request failed
            case "SEND_ACTIVATE_HIT_ROUTE_ERROR":
              {
                // get request
                try {
                  var req = arg["request"] as Request;
                  // get response
                  var resp = arg["response"] as Response;
                  criticalJson = _createTSHttp(v, req, resp);
                  print(criticalJson);
                } on Exception catch (e) {
                  print(e.toString());
                  return; // skip the function
                }
              }
              break;
            case "WARNING":
              criticalJson = _createTSWarning(v);
              break;
            case "ERROR":
              criticalJson = _createTSError(v);
              break;
            default:
              break;
          }

          // Add visitor trio of visitorId / anonymousId / instanceId
          criticalJson.addEntries(_createTrioIds(v).entries);
          sendDataUsageTracking(
              TroubleShootingHit(visitorId, outPutLabel, criticalJson));
        }
      }
    }
  }

  // Create a trio of visitorId / anonymousId / instanceId
  Map<String, dynamic> _createTrioIds(Visitor v) {
    return {
      "visitor.visitorId": v.visitorId,
      "visitor.anonymousId": v.anonymousId,
      "visitor.instanceId": visitorSessionId
    };
  }

  Map<String, dynamic> _createTSVisitorFormat(Visitor visitor) {
    Map<String, dynamic> sdkSettings = {
      "visitor.consent": visitor.getConsent(),
      "visitor.campaigns": visitor.modifications.toString(),

      "visitor.isAuthenticated": "false",

      /// SDK
      "sdk.config.usingOnVisitorExposed": (sdkConfig.onVisitorExposed != null),
      "sdk.config.usingCustomVisitorCache":
          (!(sdkConfig.visitorCacheImp is DefaultCacheVisitorImp)).toString(),
      "sdk.config.usingCustomHitCache":
          (!(sdkConfig.hitCacheImp is DefaultCacheHitImp)).toString(),
      "sdk.config.usingCustomLogManager": "true",
      "sdk.config.trackingManager.config.strategy":
          sdkConfig.trackingManagerConfig.batchStrategy.name,
      " sdk.config.trackingManager.config.batchIntervals":
          sdkConfig.trackingManagerConfig.batchIntervals.toString(),
      "sdk.config.timeout": sdkConfig.timeout.toString(),
      "sdk.config.pollingTime": sdkConfig.pollingTime.toString(),
      "sdk.config.mode": sdkConfig.decisionMode.name,

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

// For the hist and activate
  Map<String, dynamic> _createTSendHit(Visitor v, Hit h) {
    return {"hit.content": h.bodyTrack.toString()};
  }

  Map<String, dynamic> _createTSHttp(Visitor v, Request r, Response resp) {
    return {
      "http.request.headers": r.headers.toString(),
      "http.request.method": r.method,
      "http.request.url": r.url.path,
      "http.response.body": resp.body.toString(),
      "http.response.headers": resp.headers.toString(),
      "http.response.code": resp.statusCode.toString(),
      "http.response.time": "time" // TODO set real time
    };
  }

  Map<String, dynamic> _createTSWarning(Visitor v) {
    return {};
  }

  Map<String, dynamic> _createTSError(Visitor v) {
    return {};
  }
}

enum CriticalPoints {
  VISITOR_FETCH_CAMPAIGNS,
  VISITOR_AUTHENTICATE,
  VISITOR_UNAUTHENTICATE,
  VISITOR_SEND_HIT,
  VISITIR_SEND_ACTIVATE,
  HTTP_CALL,

  /// HTTP CALL

  SDK_BUCKETING_FILE, // It will be triggered when the bucketing route responds with code 200
  SDK_BUCKETING_FILE_ERROR, // It will be triggered when the bucketing route responds with error
  GET_CAMPAIGNS_ROUTE_RESPONSE_ERROR, // It will be triggered when the campaigns route responds with an error
  SEND_BATCH_HIT_ROUTE_RESPONSE_ERROR, // When a batch request failed
  SEND_ACTIVATE_HIT_ROUTE_ERROR, // When a activate request failed

  WARNING,
}
