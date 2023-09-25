import 'package:flagship/Targeting/targeting_manager.dart';
import 'package:flagship/decision/bucketing_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/model/bucketing.dart';
import 'package:flagship/model/campaign.dart';
import 'package:flagship/model/campaigns.dart';
import 'package:flagship/model/variation.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:murmurhash/murmurhash.dart';
import 'package:collection/collection.dart';

extension BucketingProcess on BucketingManager {
  Campaigns bucketVariations(String visitorId, Bucketing scriptBucket,
      Map<String, dynamic> context, Map<String, dynamic> assignHistory) {
    // Check the panic mode
    if (scriptBucket.panic == true) {
      return Campaigns(visitorId, true, []);
    }
    // Check the targeting and filter the variation he can run
    Campaigns result =
        processBucketing(visitorId, scriptBucket, context, assignHistory);
    return result;
  }

  Campaigns processBucketing(String visitorId, Bucketing scriptBucket,
      Map<String, dynamic> context, Map<String, dynamic> assignHistory) {
    Campaigns result = Campaigns(visitorId, false, []);
    TargetingManager targetManager = TargetingManager(visitorId, context);
    // Campaign
    for (BucketCampaign itemCamp in scriptBucket.campaigns) {
      // Variation group
      for (VariationGroup itemVarGroup in itemCamp.variationGroups) {
        // Check the targeting
        if (targetManager.isTargetingGroupIsOkay(itemVarGroup.targeting) ==
            true) {
          Flagship.logger(
              Level.DEBUG,
              "The Targeting for " +
                  itemVarGroup.idVariationGroup +
                  "is OK 👍");

          // Check if the variationId already exist in the history before selecting by the MurMurHash
          String? varId;
          if (assignHistory.containsKey(itemVarGroup.idVariationGroup) ==
              true) {
            // The variation group already exist
            varId = assignHistory[
                itemVarGroup.idVariationGroup]; // add more security
            Flagship.logger(Level.DEBUG,
                "This variation: $varId' already selected for the visitor: $visitorId event if the allocation changed this visitor still belong to the initial bucket");
          } else {
            varId = selectIdVariationWithMurMurHash(visitorId, itemVarGroup);

            if (varId != null) {
              Flagship.logger(Level.ALL,
                  "Adding a new saved variation in the assignation ");
              this
                  .assignationHistory
                  ?.addEntries({itemVarGroup.idVariationGroup: varId}.entries);
            }
          }

          if (varId != null) {
            // Create variation group
            Campaign camp = Campaign(
                itemCamp.idCampaign,
                itemCamp.campaignName,
                itemVarGroup.idVariationGroup,
                itemVarGroup.variationGroupName,
                itemCamp.type,
                itemCamp.slug);
            Flagship.logger(Level.DEBUG,
                "#### The variation choosen is $varId ###########");

            var matchedVariation = itemVarGroup.variations
                .firstWhereOrNull((v) => v.idVariation == varId);

            if (matchedVariation != null) {
              camp.variation = matchedVariation;

              /// Add this camp to the result
              result.campaigns.add(camp);
            } else {
              Flagship.logger(Level.DEBUG,
                  "Variation $varId not found in the recent bucketing script, this variation could be removed, will return a default value ");
            }
          }
        } else {
          Flagship.logger(
              Level.DEBUG,
              "The Targeting for " +
                  itemVarGroup.idVariationGroup +
                  "is NOT OK 👎 ");
        }
      }
    }
    return result;
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
