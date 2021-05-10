import 'package:flagship/flagship_config.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var v1 = Visitor(
      FlagshipConfig.defaultMode(), "user1", {"key1": "val1", "key2": "val2"});
  group('Visitor ', () {
    test(
        'Visitor instance should match with inputs constructor and default values',
        () {
      expect(v1.visitorId, "user1");
      expect(v1.getCurrentContext().length, 2);
      expect(v1.getCurrentContext()["key1"], "val1");
      expect(v1.config.decisionMode, FSMode.DECISION_API);
      expect(v1.config.timeout, 2);
    });

    test('update context with String ', () {
      v1.updateContext("valueString", "ola");
      expect(v1.getCurrentContext()["valueString"], "ola");
    });

    test('update context with String (already exist ) ', () {
      v1.updateContext("valueString", "newValue");
      expect(v1.getCurrentContext()["valueString"], "newValue");
    });

    test('update context with int ', () {
      v1.updateContext("valueInt", 3);
      expect(v1.getCurrentContext()["valueInt"], 3);
    });

    test('update context with Bool ', () {
      v1.updateContext("valueBool", true);
      expect(v1.getCurrentContext()["valueBool"], true);
    });

    test('update context with Bool (already exist )', () {
      v1.updateContext("valueBool", false);
      expect(v1.getCurrentContext()["valueBool"], false);
    });

    test('update context with double ', () {
      v1.updateContext("valueDouble", 12.6);
      expect(v1.getCurrentContext()["valueDouble"], 12.6);
    });

    test('length for context ', () {
      expect(v1.getCurrentContext().length, 6);
    });

    test('test none authoriezd type  ', () {
      v1.updateContext("valueObject", Object());
      expect(v1.getCurrentContext().length, 6);
    });
  });
}
