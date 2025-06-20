import 'package:flagship/hits/hit.dart';

class Page extends BaseHit {
  Page({required String location}) : super() {
    type = HitCategory.PAGEVIEW;
    super.location = location;
  }

  @override
  Map<String, Object> get bodyTrack {
    var customBody = new Map<String, Object>();
    customBody.addAll({"t": typeOfEvent /*, "dl": super.location ?? ""*/});
    // Add commun body
    customBody.addAll(super.communBodyTrack);
    return customBody;
  }

  @override
  bool isValid() {
    if (super.isValid() && super.location != null) {
      return Uri.parse(super.location ?? "").isAbsolute;
    } else {
      return false;
    }
  }

  Page.fromMap(String oldId, Map body) : super.fromMap(oldId, body) {
    this.location = body['dl'];
    this.type = HitCategory.PAGEVIEW;
  }
}
