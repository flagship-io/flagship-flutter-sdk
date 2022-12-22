import 'package:flagship/flagship.dart';

enum HitCategory {
  SCREENVIEW,
  PAGEVIEW,
  TRANSACTION,
  ITEM,
  EVENT,
  ACTIVATION,
  CONSENT,
  BATCH,
  SEGMENT,
  NONE
}

abstract class Hit {
  // id for the hit
  late String id;

  // Visitor id
  late String visitorId;

  // Check the validity
  bool isValid();

  // Type for hit
  HitCategory type = HitCategory.NONE;

  // Is less than 4h
  bool isLessThan4H();

  // Body used on posting data
  Map<String, Object> get bodyTrack;
}

class BaseHit extends Hit {
  // type for hit
  // Type type = Type.NONE;

  // Required
  late String clientId;
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

  /// QT time
  late DateTime qt;

  @override
  Map<String, Object> get bodyTrack {
    return {};
  }

  BaseHit() {
    this.clientId = Flagship.sharedInstance().envId ?? "";
    qt = DateTime.now();
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

    // Add qt entries
    result.addEntries({"qt": qt.second}.entries);

    return result;
  }

  String get typeOfEvent {
    String ret = "None";
    switch (type) {
      case HitCategory.SCREENVIEW:
        ret = 'SCREENVIEW';
        break;
      case HitCategory.ITEM:
        ret = 'ITEM';
        break;
      case HitCategory.EVENT:
      case HitCategory.CONSENT:
        ret = 'EVENT';
        break;
      case HitCategory.TRANSACTION:
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

  @override
  bool isValid() {
    return true; // Todo implement later
  }

  @override
  bool isLessThan4H() {
    return (qt.difference(DateTime.now()).inHours <= 4);
  }

  BaseHit.fromMap(String oldId, Map body) {
    this.id = oldId;
    this.clientId = body["client"];
    this.anonymousId = body["cuid"];
    this.visitorId = body["vid"];
    this.dataSource = body["ds"];
    this.screenResolution = body["sr"];
    this.screenColorDepth = body['sd'];
    this.userLanguage = body['ul'];
    this.sessionNumber = body['sn'];
    this.qt = body['qt'];
  }
}
