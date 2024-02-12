import 'package:flagship/dataUsage/data_usage_tracking.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/model/account_settings.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/visitor.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fake_path_provider_platform.dart';

import 'test_tools.dart';

void main() {
  ToolsTest.sqfliteTestInit();
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  // Start
  Flagship.start("bkk9glocmjcg0vtmdldd", "apiKey");
  PathProviderPlatform.instance = FakePathProviderPlatform();

  DataUsageTracking dataUsageTest = DataUsageTracking.sharedInstance();
  // Create a config
  FlagshipConfig sdkConfig = ConfigBuilder().build();

  test("Trouble shooting test time slot ", () {
    // Create trouble shooting
    Troubleshooting troubleshooting = Troubleshooting.fromJson({
      "startDate": DateTime.now().subtract(Duration(minutes: 5)).toString(),
      "endDate": DateTime.now().add(Duration(hours: 4)).toString(),
      "timezone": "UTC",
      "traffic": 100
    });

    // Configure data usage
    dataUsageTest.configureDataUsage(
        troubleshooting, "visitorTest", true, sdkConfig);
    // Evaluate
    dataUsageTest.evaluateTroubleShootingConditions();
    // Test should be OKAY
    expect(dataUsageTest.troubleShootingReportAllowed, true);
    troubleshooting.endDate =
        DateTime.now().subtract(Duration(minutes: 10)).toString();
    // Re Evaluate
    dataUsageTest.evaluateTroubleShootingConditions();
    // Test Should be false
    expect(dataUsageTest.troubleShootingReportAllowed, false);
  });

  test("Trouble shooting with consent ", () {
    // Create trouble shooting
    Troubleshooting troubleshooting = Troubleshooting.fromJson({
      "startDate": DateTime.now().subtract(Duration(minutes: 5)).toString(),
      "endDate": DateTime.now().add(Duration(hours: 4)).toString(),
      "timezone": "UTC",
      "traffic": 100
    });

    // Configure data usage
    dataUsageTest.configureDataUsage(
        troubleshooting, "visitorTest", true, sdkConfig);

    dataUsageTest.updateConsent(false);
    // Should be false
    expect(dataUsageTest.troubleShootingReportAllowed, false);
    dataUsageTest.updateConsent(true);
    // Should be true
    expect(dataUsageTest.troubleShootingReportAllowed, true);
  });

  test("Trouble Data Usage", () {
    // Start
    Flagship.start("bkk9glocmjcg0vtmdldd", "apiKey");
    // Create trouble shooting
    dataUsageTest.evaluateDataUsageTrackingAllocated();
    // disable data usage
    sdkConfig.disableDeveloperUsageTracking = false;
    // Check the data usage should be false
    expect(dataUsageTest.dataUsageTrackingReportAllowed, false);
  });

  test("TS Fetching", () {
    Visitor testVisitor = Flagship.newVisitor("TSVisitor").build();
    dataUsageTest.processTSFetching(testVisitor, DateTime.now());
  });

  test("Data Usage Fetching", () {
    Visitor testVisitor = Flagship.newVisitor("dataUsageVisitor").build();
    dataUsageTest.dataUsageTrackingReportAllowed = true;
    dataUsageTest.processDataUsageTracking(testVisitor);
  });

  test("Data Usage Fetching on Buckeitng", () {
    Visitor testVisitor = Flagship.newVisitor("dataUsageVisitor").build();

    dataUsageTest.configureDataUsage(null, "visitorId", true,
        ConfigBuilder().withMode(Mode.BUCKETING).build());
    dataUsageTest.dataUsageTrackingReportAllowed = true;
    dataUsageTest.processDataUsageTracking(testVisitor);
  });
}
