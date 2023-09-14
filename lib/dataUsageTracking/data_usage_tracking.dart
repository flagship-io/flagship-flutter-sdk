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
  bool dataUsageIsAllowed = false;

  DataUsageTracking(this._troubleshooting, this.visitorId);

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
    // Calculate the bucket allocation

    int hashAlloc;

    if (_troubleshooting != null){
      
      String combinedId = _troubleshooting?.endDate;
    }
    // We calculate the Hash allocation by the combination of : visitorId + endDate
    

    

    MurmurHash(

    return true;
  }

  bool isVisitorHasConsented() {
    return true;
  }

  // Send Hit for tracking Usage
  void sendDataUsageTracking() {
    print("Send Data Usage Tracking ...........");
  }


    String? selectIdVariationWithMurMurHash(
      String visitorId, VariationGroup varGroup) {
    int hashAlloc;
    // We calculate the Hash allocation by the combination of : visitorId + idVariationGroup
    String combinedId = varGroup.idVariationGroup + visitorId;

    // Calculate the murmurHash algorithm
    hashAlloc = (MurmurHash.v3(combinedId, 0) % 100);
    Flagship.logger(
        Level.DEBUG,
        "########### The MurMurHash for the combined " +
            varGroup.idVariationGroup +
            " " +
            visitorId +
            " is : $hashAlloc #############");

    int offsetAlloc = 0;
    for (Variation itemVar in varGroup.variations) {
      if (hashAlloc < itemVar.allocation + offsetAlloc) {
        return itemVar.idVariation;
      }
      offsetAlloc += itemVar.allocation;
    }
    return null;
  }

  
}
