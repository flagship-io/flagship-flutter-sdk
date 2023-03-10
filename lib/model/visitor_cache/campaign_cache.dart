import 'package:flagship/model/modification.dart';
import 'package:json_annotation/json_annotation.dart';
part 'campaign_cache.g.dart';

@JsonSerializable()
class CampaignCache {
  String? campaignId;
  String? variationGroupId;
  String? variationId;
  bool? isReference;
  String? type;
  bool? activated;
  Map<dynamic, dynamic>? flags;

  CampaignCache({
    this.campaignId,
    this.variationGroupId,
    this.variationId,
    this.isReference,
    this.type,
    this.activated,
    this.flags,
  });

  @override
  String toString() {
    return 'Campaign(campaignId: $campaignId, variationGroupId: $variationGroupId, variationId: $variationId, isReference: $isReference, type: $type, activated: $activated, flags: $flags)';
  }

  factory CampaignCache.fromJson(Map<String, dynamic> json) {
    return _$CampaignFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CampaignCacheToJson(this);

  CampaignCache.fromModification(Modification modification) {
    this.campaignId = modification.campaignId;
    this.variationGroupId = modification.variationGroupId;
    this.variationId = modification.variationId;
    this.type = modification.campaignType;
    this.isReference = modification.isReference;
    this.activated = false; // For the moment is false
    // Let the flag to null , we need it for the check later
  }

  void updateFlags(Map<dynamic, dynamic> itemFlag) {
    this.flags?.addEntries(itemFlag.entries);
  }
}
