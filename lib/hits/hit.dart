import 'package:flagship/flagship.dart';

enum Type {
  SCREENVIEW,
  PAGEVIEW,
  TRANSACTION,
  ITEM,
  EVENT,
  ACTIVATION,
  CONSSENT,
  NONE
}

abstract class Hit {
  Map<String, Object> get bodyTrack;
}

class BaseHit extends Hit {
  // type for hit
  Type type = Type.NONE;

  // Required
  late String clientId;
  late String visitorId;
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
    this.visitorId = Flagship.getCurrentVisitor()?.visitorId ?? "";
    this.clientId = Flagship.sharedInstance().envId ?? "";
  }

  Map<String, Object> get communBodyTrack {
    var result = new Map<String, Object>();

    result.addAll({"cid": clientId, "vid": visitorId, "ds": dataSource});

    /// Refracto later
    /// user ip
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
        ret = 'EVENT';
        break;
      case Type.TRANSACTION:
        ret = 'TRANSACTION';
        break;
      default:
    }
    return ret;
  }
}
