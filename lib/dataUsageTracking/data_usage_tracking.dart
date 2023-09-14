import 'package:flagship/model/account_settings.dart';

class DataUsageTracking {
  Troubleshooting? _troubleshooting;

  bool dataUsageIsAllowed = false;

  DataUsageTracking(this._troubleshooting);

  void updateTroubleshooting(Troubleshooting? trblShooting) {
    _troubleshooting = trblShooting;
    // ReEvaluate the conditions of datausagetracking
    evaluateDataUsageTrackingConditions();
  }

  void evaluateDataUsageTrackingConditions() {
    // To allow the dataUsageTracking we have to check
    dataUsageIsAllowed = isTimeSlotValide() && // TimeSlot

        isBucketAllocationValide() && // Bucket Allocation

        isVisitorHasConsented(); // Visitor Consent

    if (dataUsageIsAllowed) {
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

  bool isBucketAllocationValide() {
    return true;
  }

  bool isVisitorHasConsented() {
    return true;
  }

  // Send Hit for tracking Usage
  void sendDataUsageTracking() {
    print("Send Data Usage Tracking ...........");
  }
}
