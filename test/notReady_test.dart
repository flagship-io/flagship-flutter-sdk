import 'package:flagship/flagship.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flagship/hits/event.dart';

void main() {
  test('Test API with bad envId format', () async {
    Flagship.start("bkk9g", "apiKey");

    var v1 = Flagship.newVisitor("visitorId").build();

    expect(Flagship.getStatus(), Status.NOT_INITIALIZED);

    // v1.synchronizeModifications().then((value) {

    /// Activate
    // ignore: deprecated_member_use_from_same_package
    v1.activateModification("key");

    /// Get Modification with default value   "aliasTer": "testValue"
    // ignore: deprecated_member_use_from_same_package
    expect(v1.getModification('key1', 12), 12);

    /// Get modification infos
    // ignore: deprecated_member_use_from_same_package
    expect(v1.getModificationInfo('key1'), null);

    /// Set consent
    v1.setConsent(false);
    expect(v1.getConsent(), false);

    /// Update context
    v1.updateContext("newKey", 2);
    expect(v1.getContext().keys.contains('newKey'), true);

    /// Send hit
    v1.sendHit(Event(action: "action", category: EventCategory.Action_Tracking));
  });
}
