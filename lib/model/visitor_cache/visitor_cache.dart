import 'package:flagship/model/visitor_cache/campaign_cache.dart';
import 'package:flagship/visitor.dart';
import 'package:json_annotation/json_annotation.dart';

import 'data.dart';

part 'visitor_cache.g.dart';

const int dataBaseVersion = 1; // will be used for migration

@JsonSerializable()
class VisitorCache {
  int? version;
  Data? data;

  VisitorCache({this.version, this.data});

  @override
  String toString() => 'VisitorCache(version: $version, data: $data)';

  factory VisitorCache.fromJson(Map<String, dynamic> json) {
    return _$VisitorCacheFromJson(json);
  }

  Map<String, dynamic> toJson() => _$VisitorCacheToJson(this);

  // Create a visitorCache from the response
  VisitorCache.fromVisitor(Visitor visitor) {
    this.version = dataBaseVersion;
    this.data = Data(
        visitorId: visitor.visitorId,
        context: visitor.getContext(),
        anonymousId: visitor.anonymousId,
        consent: visitor.getConsent());
    List<CampaignCache> listCampCache = [];
    visitor.modifications.forEach((key, modificationItem) {
      // If the campaign already exist then just update flags
      CampaignCache newCampCache = listCampCache.firstWhere(
          (element) => (element.variationId == modificationItem.variationId),
          orElse: () {
        // Create a new cacheCampaign without flags
        return CampaignCache.fromModification(modificationItem);
      });
      if (newCampCache.flags == null) {
        newCampCache.flags = Map.from({key: modificationItem.value});
        listCampCache.add(newCampCache);
      } else {
        newCampCache.updateFlags({key: modificationItem.value});
      }
    });
    this.data?.campaigns = listCampCache;
  }
}
