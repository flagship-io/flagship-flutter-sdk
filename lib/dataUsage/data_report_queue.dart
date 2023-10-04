import 'dart:convert';
import 'package:flagship/api/endpoints.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/hit.dart';
import 'package:http/http.dart' as http;

class DataReportQueue {
  //TrackingManageContinuousStrategy? troubleReportQueue; // review later
  Service _reportService = Service(http.Client());

  DataReportQueue() {
    _reportService = Service(http.Client());
  }

  void sendReportData(TroubleShootingHit dataReport) async {
    // Create url string endpoint
    String urlString = Endpoints.EVENT + Endpoints.Troubleshooting;

    var response = await this._reportService.sendHttpRequest(
        RequestType.Post,
        urlString,
        Endpoints.getFSHeader(Flagship.sharedInstance().envId ?? ""),
        jsonEncode(dataReport.bodyTrack));

    switch (response.statusCode) {
      case 200:
        print("Success to send data to trouble shooting endpoint");
        break;
      default:
        print("Unknown error when sending data to trouble shooting endpoint");
    }
  }
}

class TroubleShootingHit extends BaseHit {
  TroubleShootingHit() : super() {
    type = HitCategory.TROUBLESHOOTING;
  }

  @override
  bool isLessThan4H() {
    return false;
  }

  @override
  bool isValid() {
    return true;
  }

  Map<String, Object> toJson() {
    return {
      "vid": "userTR",
      "ds": "APP",
      "cid": "bkk9glocmjcg0vtmdlng",
      "cv": {
        "version": "1",
        "label": "VISITOR-FETCH-CAMPAIGNS",
        "stack.type": "SDK",
        "stack.name": "Fluter",
        "stack.version": "3.1.4",
      }
    };
  }

  @override
  Map<String, Object> get bodyTrack {
    /// TODO remove statics
    var customBody = new Map<String, Object>();
    customBody.addAll({
      "t": typeOfEvent,
      "cv": {
        "version": "1",
        "label": "VISITOR-FETCH-CAMPAIGNS",
        "stack.type": "SDK",
        "stack.name": "Fluter",
        "stack.version": "3.0.4",
      }
    });

    // Add commun body
    customBody.addAll(super.communBodyTrack);
    return customBody;
  }
}

enum CriticalPoints {
  VISITOR_FETCH_AMPAIGNS,
  VISITOR_AUTHENTICATE,
  VISITOR_UNAUTHENTICATE,
  VISITOR_SEND_HIT,
  VISITIR_SEND_ACTIVATE,
  HTTP_CALL,
  WARNING,
  ERROR,
}
