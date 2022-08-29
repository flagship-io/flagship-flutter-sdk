import 'package:flagship/flagship.dart';

enum Type { SCREENVIEW, PAGEVIEW, TRANSACTION, ITEM, EVENT, ACTIVATION, CONSENT, NONE }

abstract class Hit {
  Map<String, Object> get bodyTrack;
}

class BaseHit extends Hit {
  // type for hit
  Type type = Type.NONE;

  // Required
  late String clientId;
  late String visitorId;
  late String? anonymousId;

  String dataSource = "APP";

  /// User Ip
  String? userIp;

  /// Screen Resolution
  String? screenResolution;

  ///Screen Color Depth
  String? screenColorDepth;

  /// User Language
  String? userLanguage;

  /// Session Number
  int? sessionNumber;

  @override
  Map<String, Object> get bodyTrack {
    return {};
  }

  BaseHit() {
    this.clientId = Flagship.sharedInstance().envId ?? "";
  }

  Map<String, Object> get communBodyTrack {
    var result = new Map<String, Object>();

    result.addAll({"cid": clientId, /*"vid": visitorId,*/ "ds": dataSource});

    // ad xcpc informations
    result.addEntries(_createTuple().entries);

    /// Refracto later
    /// user ipx
    if (userIp != null) result["uip"] = dataSource;

    /// ScreenResolution
    if (screenResolution != null) result["sr"] = screenResolution ?? "";

    /// Screen Color Depth
    if (screenColorDepth != null) result["sd"] = screenColorDepth ?? "";

    /// user language
    if (userLanguage != null) result["ul"] = userLanguage ?? "";

    /// Session number
    if (sessionNumber != null) result["sn"] = sessionNumber ?? 0;

    return result;
  }

  String get typeOfEvent {
    String ret = "None";
    switch (type) {
      case Type.SCREENVIEW:
        ret = 'SCREENVIEW';
        break;
      case Type.ITEM:
        ret = 'ITEM';
        break;
      case Type.EVENT:
      case Type.CONSENT:
        ret = 'EVENT';
        break;
      case Type.TRANSACTION:
        ret = 'TRANSACTION';
        break;
      default:
    }
    return ret;
  }

  Map<String, String> _createTuple() {
    Map<String, String> tupleId = new Map<String, String>();
    if (this.anonymousId != null) {
      // envoyer: cuid = visitorId, et vid=anonymousId
      tupleId.addEntries({"cuid": this.visitorId}.entries);
      tupleId.addEntries({"vid": this.anonymousId ?? ""}.entries);
    } else {
      tupleId.addEntries({"vid": this.visitorId}.entries);
    }
    return tupleId;
  }
}
