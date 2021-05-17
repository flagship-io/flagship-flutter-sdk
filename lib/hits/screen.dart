import 'package:flagship/hits/hit.dart';

class Screen extends BaseHit {
  final String location;

  Screen({required this.location}) : super() {
    type = Type.SCREENVIEW;
  }

  @override
  Map<String, Object> get bodyTrack {
    var customBody = new Map<String, Object>();
    customBody.addAll({"t": typeOfEvent, "dl": location});
    // Add commun body
    customBody.addAll(super.communBodyTrack);
    return customBody;
  }
}
