import 'package:flagship/hits/hit.dart';

class Segment extends BaseHit {
  Map<String, dynamic> persona = {};

  Segment({required this.persona}) : super() {
    type = HitCategory.SEGMENT;
  }

  @override
  Map<String, Object> get bodyTrack {
    var customBody = new Map<String, Object>();
// Convert persona values to String
    Map<String, String> personaString =
        persona.map((key, value) => MapEntry(key, value.toString()));
    customBody.addAll({"s": personaString, "t": typeOfEvent});
    // Add commun body
    customBody.addAll(super.communBodyTrack);
    return customBody;
  }

  Segment.fromMap(String oldId, Map body) : super.fromMap(oldId, body) {
    this.type = HitCategory.SEGMENT;
    this.persona = body['s'];
  }
}
