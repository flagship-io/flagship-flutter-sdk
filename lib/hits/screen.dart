import 'package:flagship/hits/hit.dart';

class Screen extends BaseHit {
  /// This argument refers to the Screen Name of the app, at the moment the hit is sent.  The maximum permitted length is 2048 Bytes .
  late String location;

  Screen({required this.location}) : super() {
    type = HitCategory.SCREENVIEW;
  }

  @override
  Map<String, Object> get bodyTrack {
    var customBody = new Map<String, Object>();
    customBody.addAll({"t": typeOfEvent, "dl": location});
    // Add commun body
    customBody.addAll(super.communBodyTrack);
    return customBody;
  }

  Screen.fromMap(String oldId, Map body) : super.fromMap(oldId, body) {
    this.location = body['dl'];
    this.type = HitCategory.SCREENVIEW;
  }
}
