import 'package:flagship/hits/fs_hit.dart';

const String ActionTracking = "Action Tracking";
const String UserEngagement = "User Engagement";

/// Enumeration that represent Events type
enum FSCategoryEvent {
  /// Action tracking
  Action_Tracking,

  /// User engagement
  User_Engagement
}

class FSEvent extends Hit {
  /// category of the event (Action_Tracking or User_Engagement).
  FSCategoryEvent? category;

  /// name of the event.
  String action;

  /// description of the event.
  String? label;

  /// value of the event, must be non-negative.
  int? value;

  FSEvent(
      {required this.action, required this.category, this.label, this.value})
      : super() {
    type = Type.EVENT;
  }

  @override
  Map<String, Object> get bodyTrack {
    var customBody = new Map<String, Object>();
    customBody.addAll({
      "t": typeOfEvent,
      "ea": this.action,
      "ec": (this.category == FSCategoryEvent.Action_Tracking)
          ? ActionTracking
          : UserEngagement
    });
    // Add label
    if (label != null) customBody['el'] = label ?? "";
    // Add value
    if (value != null) customBody['ev'] = value ?? 0;
    // Add commun body
    customBody.addAll(super.communBodyTrack);
    return customBody;
  }
}
