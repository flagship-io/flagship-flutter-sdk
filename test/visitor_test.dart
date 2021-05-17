import 'package:flagship/flagship_config.dart';
import 'package:flagship/model/modification.dart';
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
      expect(v1.config.decisionMode, Mode.DECISION_API);
      expect(v1.config.timeout, 2000);
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

    test('test none authorized type  ', () {
      v1.updateContext("valueObject", Object());
      expect(v1.getCurrentContext().length, 6);
    });

    test('test get modification ', () {
      v1.modifications = new Map<String, Modification>();
      expect(v1.getModification("test_missing", 10), 10);

      v1.modifications["test_string"] = new Modification("test_string",
          "campaignId", "variationGroupId", "variationId", true, "string");
      expect(v1.getModification("test_string", "string"), "string");

      v1.modifications["test_bool"] = new Modification("test_bool",
          "campaignId", "variationGroupId", "variationId", true, true);
      expect(v1.getModification("test_bool", false), true);

      v1.modifications["test_double"] = new Modification("test_double",
          "campaignId", "variationGroupId", "variationId", true, 23.5);
      expect(v1.getModification("test_double", 13.5), 23.5);

      v1.modifications["test_int"] = new Modification("test_int", "campaignId",
          "variationGroupId", "variationId", true, 23);
      expect(v1.getModification("test_int", 13), 23);

      v1.modifications["test_mismatch"] = new Modification("test_mismatch",
          "campaignId", "variationGroupId", "variationId", true, 23);
      expect(v1.getModification("test_mismatch", "string"), "string");

      expect(v1.getModification("test_not_exists", "string"), "string");

      v1.modifications["test_mismatch_castable"] = new Modification(
          "test_mismatch_castable",
          "campaignId",
          "variationGroupId",
          "variationId",
          true,
          23);
      expect(v1.getModification("test_mismatch_castable", 23.3), 23);

      v1.modifications["test_list"] = new Modification(
          "test_mismatch_castable",
          "campaignId",
          "variationGroupId",
          "variationId",
          true,
          ["test1", "test2"]);

      expect(v1.getModification("test_list", ["test3", "test4"]),
          ["test1", "test2"]);

      v1.modifications["test_object"] = new Modification(
          "test_mismatch_castable",
          "campaignId",
          "variationGroupId",
          "variationId",
          true,
          {"test1": "value1"});

      expect(v1.getModification("test_object", {"test2": "value2"}),
          {"test1": "value1"});
    });
  });
}
