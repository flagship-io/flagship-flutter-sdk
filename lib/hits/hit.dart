import 'package:flagship/flagship.dart';
import 'package:flagship/utils/logger/log_manager.dart';

class BaseHit extends Hit {
  // Required
  String clientId = "";

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

  BaseHit() {
    this.clientId = Flagship.sharedInstance().envId ?? "";
    qt = DateTime.now();
  }

  BaseHit.fromMap(String oldId, Map body) {
    try {
      this.id = oldId; // Keep the same id in db
      // Set CLient Id
      this.clientId = body["cid"] ?? "";
      // Set the id of visitor
      this.visitorId = body["vid"] ?? "";
      this.anonymousId = body["cuid"];
      // Data Source
      this.dataSource = body["ds"] ?? "APP";

      this.screenResolution = body["sr"];
      this.screenColorDepth = body['sd'];
      this.userLanguage = body['ul'];
      this.sessionNumber = body['sn'];
      this.qt = DateTime.parse(body['qt']);
    } catch (e) {
      Flagship.logger(Level.DEBUG, "Error en parsin hit from map, $e");
    }
  }

  @override
  Map<String, Object> get bodyTrack {
    return {};
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
    result.addEntries({"qt": qt.toString()}.entries);
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
      case HitCategory.ACTIVATION:
        ret = 'ACTIVATE';
        break;
      case HitCategory.SEGMENT:
        ret = 'SEGMENT';
        break;
      default:
    }
    return ret;
  }

  @override
  bool isLessThan4H() {
    return (DateTime.now().difference(qt).inHours <= 4);
  }

  @override
  bool isValid() {
    return true; // Todo implement later
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

abstract class Hit {
  // id for the hit
  String id = "";

  String? anonymousId;

  // Visitor id
  String visitorId = "";

  // Type for hit
  HitCategory type = HitCategory.NONE;

  // Body used on posting data
  Map<String, Object> get bodyTrack;

  // Is less than 4h
  bool isLessThan4H();

  // Check the validity
  bool isValid();
}

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
