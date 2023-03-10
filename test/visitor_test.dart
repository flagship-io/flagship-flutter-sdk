import 'package:flagship/flagship.dart';
import 'package:flagship/flagshipContext/flagship_context.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/visitor.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_tools.dart';

void main() {
  ToolsTest.sqfliteTestInit();
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  var v1 = Visitor(
      ConfigBuilder().build(), "user1", true, {"key1": "val1", "key2": "val2"});

  v1.flagshipDelegate.onUpdateState(Status.READY);
  group('Visitor Ready ', () {
    test(
        'Visitor instance should match with inputs constructor and default values',
        () {
      expect(v1.visitorId, "user1");
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

    test('test none authorized type  ', () {
      int oldLength = v1.getContext().length;
      v1.updateContext("valueObject", Object());
      expect(v1.getCurrentContext().length, oldLength);
      v1.clearContext();
      expect(v1.getCurrentContext().length, 0);
    });

    test('test with predefined context', () {
      v1.updateFlagshipContext(FlagshipContext.DEVICE_TYPE, "QA_Type");
      int l1 = v1.getContext().length;
      v1.updateFlagshipContext(FlagshipContext.DEVICE_MODEL, 23);
      v1.updateFlagshipContext(FlagshipContext.LOCATION_LAT, "1234");
      v1.updateFlagshipContext(FlagshipContext.FIRST_TIME_INIT, 1);
      expect(v1.getContext().length,
          l1); //The length still the same as before, because the update is not valide

      expect(v1.getContext()["sdk_deviceType"],
          "QA_Type"); //The value still the same
      // Update with valide value
      v1.updateFlagshipContext(FlagshipContext.DEVICE_TYPE, "QA_TypelBis");
      expect(v1.getContext()["sdk_deviceType"],
          "QA_TypelBis"); //The value should be updated
    });

    test('test get modification ', () {
      v1.modifications = new Map<String, Modification>();
      // ignore: deprecated_member_use_from_same_package
      expect(v1.getModification("test_missing", 10), 10);

      v1.modifications["test_string"] = new Modification(
          "test_string",
          "campaignId",
          "variationGroupId",
          "variationId",
          true,
          "ab",
          "slug",
          "string");
      // ignore: deprecated_member_use_from_same_package
      expect(v1.getModification("test_string", "string"), "string");

      v1.modifications["test_bool"] = new Modification(
          "test_bool",
          "campaignId",
          "variationGroupId",
          "variationId",
          true,
          "ab",
          "slug",
          true);
      // ignore: deprecated_member_use_from_same_package
      expect(v1.getModification("test_bool", false), true);

      v1.modifications["test_double"] = new Modification(
          "test_double",
          "campaignId",
          "variationGroupId",
          "variationId",
          true,
          "ab",
          "slug",
          23.5);
      // ignore: deprecated_member_use_from_same_package
      expect(v1.getModification("test_double", 13.5), 23.5);

      v1.modifications["test_int"] = new Modification("test_int", "campaignId",
          "variationGroupId", "variationId", true, "ab", "slug", 23);
      // ignore: deprecated_member_use_from_same_package
      expect(v1.getModification("test_int", 13), 23);

      v1.modifications["test_mismatch"] = new Modification(
          "test_mismatch",
          "campaignId",
          "variationGroupId",
          "variationId",
          true,
          "ab",
          "slug",
          23);
      // ignore: deprecated_member_use_from_same_package
      expect(v1.getModification("test_mismatch", "string"), "string");

      // ignore: deprecated_member_use_from_same_package
      expect(v1.getModification("test_not_exists", "string"), "string");

      v1.modifications["test_mismatch_castable"] = new Modification(
          "test_mismatch_castable",
          "campaignId",
          "variationGroupId",
          "variationId",
          true,
          "ab",
          "slug",
          23);
      // ignore: deprecated_member_use_from_same_package
      expect(v1.getModification("test_mismatch_castable", 23.3), 23);

      v1.modifications["test_list"] = new Modification(
          "test_mismatch_castable",
          "campaignId",
          "variationGroupId",
          "variationId",
          true,
          "ab",
          "slug",
          ["test1", "test2"]);

      // ignore: deprecated_member_use_from_same_package
      expect(v1.getModification("test_list", ["test3", "test4"]),
          ["test1", "test2"]);

      v1.modifications["test_object"] = new Modification(
          "test_mismatch_castable",
          "campaignId",
          "variationGroupId",
          "variationId",
          true,
          "ab",
          "slug",
          {"test1": "value1"});

      // ignore: deprecated_member_use_from_same_package
      expect(v1.getModification("test_object", {"test2": "value2"}),
          {"test1": "value1"});

      v1.modifications["badType"] = new Modification(
          "test_mismatch_castable",
          "campaignId",
          "variationGroupId",
          "variationId",
          true,
          "ab",
          "slug",
          "value1");
      // ignore: deprecated_member_use_from_same_package
      expect(v1.getModification("test_object", 13), 13);

      v1.modifications["null"] = new Modification(
          "test_mismatch_castable",
          "campaignId",
          "variationGroupId",
          "variationId",
          true,
          "ab",
          "slug",
          null);
      // ignore: deprecated_member_use_from_same_package
      expect(v1.getModification("null", "null"), "null");
    });

    test("Shred visitor", () {
      Flagship.newVisitor("shared").build();
      expect(Flagship.getCurrentVisitor()?.visitorId, "shared");

      Flagship.newVisitor("sharedBis", instanceType: Instance.SINGLE_INSTANCE)
          .build();
      expect(Flagship.getCurrentVisitor()?.visitorId, "sharedBis");

      Visitor notShared =
          Flagship.newVisitor("notShared", instanceType: Instance.NEW_INSTANCE)
              .build();
      expect(Flagship.getCurrentVisitor()?.visitorId, "sharedBis");
      expect(notShared.visitorId, "notShared");
    });
  });
}
