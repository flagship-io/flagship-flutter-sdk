import 'package:flagship/hits/hit.dart';

class Screen extends BaseHit {
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
