// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campaign.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Campaign _$CampaignFromJson(Map<String, dynamic> json) => Campaign(
      campaignId: json['campaignId'] as String?,
      variationGroupId: json['variationGroupId'] as String?,
      variationId: json['variationId'] as String?,
      isReference: json['isReference'] as bool?,
      type: json['type'] as String?,
      activated: json['activated'] as bool?,
      flags: json['flags'] == null
          ? null
          : Flags.fromJson(json['flags'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CampaignToJson(Campaign instance) => <String, dynamic>{
      'campaignId': instance.campaignId,
      'variationGroupId': instance.variationGroupId,
      'variationId': instance.variationId,
      'isReference': instance.isReference,
      'type': instance.type,
      'activated': instance.activated,
      'flags': instance.flags,
    };
