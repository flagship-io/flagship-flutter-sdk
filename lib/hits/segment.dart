import 'package:flagship/hits/hit.dart';

class Segment extends BaseHit {
  Map<String, dynamic> persona = {};

  Segment({required this.persona}) : super() {
    type = HitCategory.SEGMENT;
  }

  @override
  Map<String, Object> get bodyTrack {
    var customBody = new Map<String, Object>();
    customBody.addAll({"s": persona, "t": typeOfEvent});
    // Add commun body
    customBody.addAll(super.communBodyTrack);
    return customBody;
  }

  Segment.fromMap(String oldId, Map body) : super.fromMap(oldId, body) {
    this.type = HitCategory.SEGMENT;
    this.persona = body['s'];
  }
}
