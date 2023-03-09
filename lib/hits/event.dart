import 'package:flagship/hits/hit.dart';

const String ActionTracking = "Action Tracking";
const String UserEngagement = "User Engagement";

/// Enumeration that represent Events type
enum EventCategory {
  /// Action tracking
  Action_Tracking,

  /// User engagement
  User_Engagement
}

class Event extends BaseHit {
  /// Categorizes the event and helps us understand what you want to retrieve inside the reporting.
  EventCategory? category;

  /// The action corresponds to the KPI name you will be able to select inside the Flagship dashboard reporting. The maximum permitted length is 500 Bytes.
  String action = "";

  /// The label argument is a supplementary description of your event. The maximum permitted length is 500 Bytes.
  String? label;

  /// value of the event, must be non-negative.
  int? value;

  Event({required this.action, required this.category, this.label, this.value})
      : super() {
    type = HitCategory.EVENT;
  }

  @override
  Map<String, Object> get bodyTrack {
    var customBody = new Map<String, Object>();
    customBody.addAll({
      "t": typeOfEvent,
      "ea": this.action,
      "ec": (this.category == EventCategory.Action_Tracking)
          ? ActionTracking
          : UserEngagement
    });
    // Add label if not null
    if (label != null) {
      customBody['el'] = label ?? "";
    }
    // Add value if not null
    if (value != null) {
      customBody['ev'] = value ?? 0;
    }
    // Add commun body
    customBody.addAll(super.communBodyTrack);

    return customBody;
  }

  Event.fromMap(String oldId, Map body) : super.fromMap(oldId, body) {
    // this.location = body['dl'];
    this.category = (body['ec'] == ActionTracking)
        ? EventCategory.Action_Tracking
        : EventCategory.User_Engagement;
    this.action = body['ea'] ?? "";
    this.label = body['el'];
    this.value = body["ev"];
    this.type = HitCategory.EVENT;
  }

  @override
  bool isValid() {
    if (this.value != null) {
      // if the value is not null ==> check the sign of the value
      if (this.value?.sign == -1) {
        return false;
      }
    }
    return true;
  }
}

class Consent extends Event {
  Consent({required bool hasConsented})
      : super(action: "fs_consent", category: EventCategory.User_Engagement) {
    type = HitCategory.CONSENT;
    label = hasConsented ? "Flutter:true" : "Flutter:false";
  }

  Consent.fromMap(String oldId, Map body) : super.fromMap(oldId, body) {
    this.type = HitCategory.CONSENT;
  }
}
