import 'package:flagship/hits/hit.dart';

class Segment extends BaseHit {
  final Map<String, dynamic> persona;

  Segment({required this.persona}) : super() {
    type = HitCategory.SEGMENT;
  }

  @override
  Map<String, Object> get bodyTrack {
    var customBody = new Map<String, Object>();
    customBody.addAll({"s": persona});
    // Add commun body
    customBody.addAll(super.communBodyTrack);
    return customBody;
  }
}