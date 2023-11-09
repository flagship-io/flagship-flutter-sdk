import 'package:flagship/flagship.dart';
import 'package:flagship/utils/logger/log_manager.dart';

class BaseHit extends Hit {
  // Required
  String clientId = "";

  String dataSource = "APP";

  /// Refers to the IP address of the user. This should be a valid IP address in IPv4 or IPv6 format. The maximum permitted length is 45 Bytes.
  String? userIp;

  /// Refers to the the screen resolution in pixels. The maximum permitted length is 20 Bytes.
  String? screenResolution;

  /// Refers to the user's language. The maximum permitted length is 20 Bytes.
  String? userLanguage;

  /// Indicates the number of sessions the current visitor has logged, including the current session.
  int? sessionNumber;

  /// This argument refers to the Screen Name of the app, at the moment the hit is sent.  The maximum permitted length is 2048 Bytes .
  String? location;

  BaseHit() {
    this.clientId = Flagship.sharedInstance().envId ?? "";
    createdAt = DateTime.now();
  }

  BaseHit.fromMap(String oldId, Map body) {
    try {
      this.id = oldId; // Keep the same id in db
      // Set the created date
      this.createdAt = DateTime.parse(body['createdAt']);
      // Set CLient Id
      this.clientId = body["cid"] ?? "";
      // Set the id of visitor
      this.visitorId = body["vid"] ?? "";
      this.anonymousId = body["cuid"];
      // Data Source
      this.dataSource = body["ds"] ?? "APP";
      // Screen resolution
      this.screenResolution = body["sr"];
      // user language
      this.userLanguage = body['ul'];
      // Session number
      this.sessionNumber = body['sn'];
    } catch (e) {
      Flagship.logger(Level.DEBUG, "Error on parsing hit from map, $e");
    }
  }

  @override
  Map<String, Object> get bodyTrack {
    return {};
  }

  Map<String, Object> get communBodyTrack {
    var result = new Map<String, Object>();

    result.addAll({"cid": clientId, "ds": dataSource});

    /// Add xpc informations
    result.addEntries(_createTuple().entries);

    /// User ipx
    if (userIp != null) result["uip"] = dataSource;

    /// ScreenResolution
    if (screenResolution != null) result["sr"] = screenResolution ?? "";

    /// User language
    if (userLanguage != null) result["ul"] = userLanguage ?? "";

    /// Session number
    if (sessionNumber != null) result["sn"] = sessionNumber ?? 0;

    /// Add qt entries
    /// Time difference between when the hit was created and when it was sent
    if (this.createdAt != null) {
      result.addEntries({
        "qt": DateTime.now()
            .difference(createdAt ?? DateTime.now())
            .inMilliseconds
      }.entries);
    }
    return result;
  }

  String get typeOfEvent {
    String ret = "None";
    switch (type) {
      case HitCategory.SCREENVIEW:
        ret = 'SCREENVIEW';
        break;
      case HitCategory.PAGEVIEW:
        ret = 'PAGEVIEW';
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
      case HitCategory.TROUBLESHOOTING:
        ret = "TROUBLESHOOTING";
        break;
      case HitCategory.USAGE:
        ret = "USAGE";
        break;
      default:
    }
    return ret;
  }

  @override
  bool isLessThan4H() {
    return (DateTime.now().difference(createdAt ?? DateTime.now()).inHours <=
        4);
  }

  @override
  bool isValid() {
    return (this.visitorId.isNotEmpty &&
        this.clientId.isNotEmpty &&
        this.type != HitCategory.NONE);
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

  /// CreatedAt date
  DateTime? createdAt;

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
  TROUBLESHOOTING,
  USAGE,
  NONE
}
