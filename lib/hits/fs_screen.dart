import 'package:flagship/hits/fs_hit.dart';

class FSScreen extends Hit {
  final String location;

  FSScreen({required this.location}) : super() {
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
