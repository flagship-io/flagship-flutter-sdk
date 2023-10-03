import 'package:flagship/dataUsage/data_report_queue.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/model/account_settings.dart';
import 'package:flagship/model/bucketing.dart';
import 'package:flagship/model/variation.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:murmurhash/murmurhash.dart';

class DataUsageTracking {
  // TroubleShooting
  Troubleshooting? _troubleshooting;
  // VisitorId
  String visitorId;
  // Is data tracking is allowed
  bool troubleShootingReportAllowed = false;

  bool _hasConsented = false;

  DataReportQueue? dataReport;

  DataUsageTracking(this._troubleshooting, this.visitorId, this._hasConsented) {
    dataReport = DataReportQueue();
  }

  void updateTroubleshooting(Troubleshooting? trblShooting) {
    _troubleshooting = trblShooting;
    // ReEvaluate the conditions of datausagetracking
    evaluateDataUsageTrackingConditions();
  }

  void updateConsent(bool newValue) {
    _hasConsented = newValue;
    evaluateDataUsageTrackingConditions();
  }

  void evaluateDataUsageTrackingConditions() {
    // To allow the dataUsageTracking we have to check
    troubleShootingReportAllowed = isTimeSlotValide() && // TimeSlot

        isBucketTroubleshootingAllocated() && // Bucket Allocation for TR

        isVisitorHasConsented(); // Visitor Consent

    if (troubleShootingReportAllowed) {
      print("-------------- Data Usage Allowed ✅✅✅✅✅ ---------------");
    } else {
      print("-------------- Data Usage NOT Allowed ❌❌❌❌❌ --------------");
    }
  }

  bool isTimeSlotValide() {
    // Get the date
    DateTime startDate = DateTime.parse(_troubleshooting?.startDate ?? "");
    DateTime endDate = DateTime.parse(_troubleshooting?.endDate ?? "");
    // Get the actual date
    DateTime actualDate = DateTime.now();
    return actualDate.isAfter(startDate) && actualDate.isBefore(endDate);
  }

  bool isBucketTroubleshootingAllocated() {
    // Calculate the bucket allocation

    if (_troubleshooting?.endDate != null) {
      String combinedId = this.visitorId + (_troubleshooting?.endDate ?? "");
      int hashAlloc = (MurmurHash.v3(combinedId, 0) % 100);

      print(
          "-------- DEV --- The hash allocation for TR bucket is $hashAlloc ------------");

      int traf = (_troubleshooting?.traffic ?? 0);
      print(
          "-------- DEV --- The range allocation for TR bucket is $traf  ------------");

      return (hashAlloc <= (_troubleshooting?.traffic ?? 0));
    } else {
      return false;
    }
  }

  bool isVisitorHasConsented() {
    return _hasConsented;
  }

  // Send Hit for tracking Usage
  void sendDataUsageTracking() {
    print("Send Data Usage Tracking ...........");
  }
}
