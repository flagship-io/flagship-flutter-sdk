import 'package:flagship/hits/hit.dart';

class Screen extends BaseHit {
  Screen({required String location}) : super() {
    type = HitCategory.SCREENVIEW;
    super.location = location;
  }

  @override
  Map<String, Object> get bodyTrack {
    var customBody = new Map<String, Object>();
    customBody.addAll({"t": typeOfEvent});
    // Add commun body
    customBody.addAll(super.communBodyTrack);
    return customBody;
  }

  @override
  bool isValid() {
    return (super.isValid() && super.location != null);
  }

  Screen.fromMap(String oldId, Map body) : super.fromMap(oldId, body) {
    this.location = body['dl'];
    this.type = HitCategory.SCREENVIEW;
  }
}
