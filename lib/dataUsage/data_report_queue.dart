import 'dart:convert';
import 'package:flagship/api/endpoints.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:http/http.dart' as http;

String troubleShootingVersion = "1";
String stackType = "SDK";
String stackName = "Flutter";

class DataReportQueue {
  Service _reportService = Service(http.Client());

  DataReportQueue() {
    _reportService = Service(http.Client());
  }

  void sendReportData(TroubleShootingHit dataReport) async {
    // Create url string endpoint
    String urlString = Endpoints.EVENT;
    if (dataReport.type == HitCategory.TROUBLESHOOTING) {
      urlString = urlString + Endpoints.Troubleshooting;
    } else if (dataReport.type == HitCategory.USAGE) {
      urlString = urlString + Endpoints.Analytics;
    } else {
      return;
    }
    var response = await this._reportService.sendHttpRequest(
        RequestType.Post,
        urlString,
        Endpoints.getFSHeader(Flagship.sharedInstance().envId ?? ""),
        jsonEncode(dataReport.bodyTrack));

    switch (response.statusCode) {
      case 200:
        Flagship.logger(Level.INFO, "Success to send DUT or TR report");
        break;
      default:
        Flagship.logger(Level.INFO, "Error on sending DUT or TR report");
    }
  }
}

class TroubleShootingHit extends BaseHit {
  // Commun Fields
  Map<String, String> _communCustomFields =
      {}; // this is the out put will add into it the custom variable
  // Custom Variable
  Map<String, String> speceficCustomFields = {};
  // Label for the critical point
  String label = "";
  TroubleShootingHit(String aVisitorId, this.label, this.speceficCustomFields)
      : super() {
    type = HitCategory.TROUBLESHOOTING;
    visitorId = aVisitorId;
    _fillTheCommunFieldsAndCompleteWithCustom();
  }

  @override
  bool isLessThan4H() {
    return false;
  }

  @override
  bool isValid() {
    return true;
  }

  @override
  Map<String, Object> get bodyTrack {
    var customBody = new Map<String, Object>();

    customBody.addAll({"t": typeOfEvent, "cv": _communCustomFields});

    // Add commun body
    customBody.addAll(super.communBodyTrack);

    return customBody;
  }

  _fillTheCommunFieldsAndCompleteWithCustom() {
    _communCustomFields = {
      "version": troubleShootingVersion,
      "envId": Flagship.sharedInstance().envId ?? "",
      "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
      "timeZone": DateTime.now().timeZoneName,
      "label": label,
      "stack.type": stackType,
      "stack.name": stackName,
      "stack.version": FlagshipVersion,
      "flagshipInstanceId":
          Flagship.sharedInstance().flagshipInstanceId.toString(),
    };

    _communCustomFields.addEntries(this.speceficCustomFields.entries);
  }
}

class DataUsageHit extends TroubleShootingHit {
  DataUsageHit(
      String aVisitorId, String label, Map<String, String> speceficCustomFields)
      : super(aVisitorId, label, speceficCustomFields) {
    type = HitCategory.USAGE;
  }
}
