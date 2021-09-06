import 'package:flagship/flagship.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flagship/utils/constants.dart';

void main() {
  test('Start Client ', () {
    Flagship.start("envId", "apiKey");

    Flagship.setCurrentVisitor(Flagship.newVisitor(
        "user1", {"key1": "val1", "key2": 2, "key3": true, "key4": 12.01}));
    var v1 = Flagship.getCurrentVisitor();

    // check the user id
    expect(v1?.visitorId, "user1");
    // check the mode
    expect(v1?.config.decisionMode, Mode.DECISION_API);
    expect(v1?.getCurrentContext().length, 4);
    expect(v1?.getConsent(), true);

    // create visitor v2
    var v2 = Flagship.newVisitor(
        "user2", {"key1": "val1", "key2": 2, "key3": true, "key4": 12.01},
        hasConsented: false);
    expect(v2.visitorId, "user2");
    expect(v2.getConsent(), false);
    v2.setConsent(true);
    expect(v2.getConsent(), true);
  });
}
