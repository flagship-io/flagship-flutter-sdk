import 'package:flagship/Targeting/targeting_manager.dart';
import 'package:flagship/decision/bucketing_manager.dart';
import 'package:flagship/model/bucketing.dart';
import 'package:flagship/model/campaign.dart';
import 'package:flagship/model/campaigns.dart';
import 'package:flagship/model/variation.dart';
import 'package:murmurhash/murmurhash.dart';

extension BucketingProcess on BucketingManager {
  Campaigns bucketVariations(String visitorId, Bucketing scriptBucket, Map<String, dynamic> context) {
    /// Check the panic mode
    if (scriptBucket.panic == true) {
      return Campaigns(visitorId, true, []);
    }

    // check the targetings and filter the variation he can run
    Campaigns result = processBucketing(visitorId, scriptBucket, context);

    return result;
  }

  Campaigns processBucketing(String visitorId, Bucketing scriptBucket, Map<String, dynamic> context) {
    Campaigns result = Campaigns(visitorId, false, []);
    TargetingManager targetManager = TargetingManager(visitorId, context);

    // Campaign
    for (BucketCampaign itemCamp in scriptBucket.campaigns) {
      // Variation group
      for (VariationGroup itemVarGroup in itemCamp.variationGroups) {
        // Check the targeting
        if (targetManager.isTargetingGroupIsOkay(itemVarGroup.targeting) == true) {
          print("The Targeting for " + itemVarGroup.idVariationGroup + "is OKAY 👍");

          String? varId = selectVariationWithMurMurHash(visitorId, itemVarGroup);

          if (varId != null) {
            // Create variation group
            Campaign camp = Campaign(itemCamp.idCampaign, itemVarGroup.idVariationGroup, itemCamp.type, itemCamp.slug);
            print("##### The variation choosen is $varId ###########");

            for (Variation itemVar in itemVarGroup.variations) {
              if (itemVar.idVariation == varId) {
                camp.variation = itemVar;
              }
            }

            /// Add this camp to the result
            result.campaigns.add(camp);
          }
        } else {
          print("The Targeting for " + itemVarGroup.idVariationGroup + "is KO 👎");
        }
      }
    }
    return result;
  }

  String? selectVariationWithMurMurHash(String visitorId, VariationGroup varGroup) {
    int hashAlloc;
    // We calculate the Hash allocation by the combonation of : visitorId + idVariationGroup
    String combinedId = varGroup.idVariationGroup + visitorId;

    // Calculate the murmurHash algorithm

    print(" ########## ${MurmurHash.v3(combinedId, 0)} ############");
    hashAlloc = (MurmurHash.v3(combinedId, 0) % 100);
    print("########### The MurMur fot the combined " + combinedId + " is : $hashAlloc #############");

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
