import 'dart:convert';
import 'package:flagship/api/endpoints.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/utils/flagship_tools.dart';
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
  // Commun Fields
  Map<String, dynamic> communFields = {};
  // Custom Variable
  Map<String, dynamic> customVariable = {};
  // Label for the critical point
  String label = "";
  TroubleShootingHit(this.label) : super() {
    type = HitCategory.TROUBLESHOOTING;
    visitorId = "testUser";

    /// TODO remove static later
    _fillTheCommunFields();
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
      "cv": {communFields, customVariable}
    };
  }

  @override
  Map<String, Object> get bodyTrack {
    var customBody = new Map<String, Object>();
    customBody.addAll({
      "t": typeOfEvent,
      "cv": communFields,
    });

    // Add commun body
    customBody.addAll(super.communBodyTrack);
    return customBody;
  }

  _fillTheCommunFields() {
    communFields = {
      "version": 1,
      "envId": Flagship.sharedInstance().envId,
      "logLevel": "ALL",
      "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
      "timeZone":
          DateTime.now().timeZoneName, // TODO check later if the value is OK ?
      "label": label,
      "stack.type": "SDK",
      "stack.name": "Flutter",
      "stack.version": FlagshipVersion,
      "flagshipInstanceId": FlagshipTools.generateUuidv4()
          .toString() // An unique ID (uuidV4) generated at the SDK initialization.
    };
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
