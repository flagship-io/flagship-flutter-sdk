import 'package:json_annotation/json_annotation.dart';

import 'flags.dart';

part 'campaign.g.dart';

@JsonSerializable()
class Campaign {
  String? campaignId;
  String? variationGroupId;
  String? variationId;
  bool? isReference;
  String? type;
  bool? activated;
  Flags? flags;

  Campaign({
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

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return _$CampaignFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CampaignToJson(this);
}
