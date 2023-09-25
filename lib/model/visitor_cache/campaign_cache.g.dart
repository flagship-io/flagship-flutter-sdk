// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campaign_cache.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CampaignCache _$CampaignFromJson(Map<String, dynamic> json) => CampaignCache(
      campaignId: json['campaignId'] as String?,
      campaignName: json['campaignName'] as String?,
      variationGroupId: json['variationGroupId'] as String?,
      variationGroupName: json['variationGroupName'] as String?,
      variationId: json['variationId'] as String?,
      variationName: json['variationName'] as String?,
      isReference: json['isReference'] as bool?,
      type: json['type'] as String?,
      activated: json['activated'] as bool?,
      flags: json['flags'] == null
          ? null
          : (json['flags'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CampaignCacheToJson(CampaignCache instance) =>
    <String, dynamic>{
      'campaignId': instance.campaignId,
      'campaignName': instance.campaignName,
      'variationGroupId': instance.variationGroupId,
      'variationGroupName': instance.variationGroupName,
      'variationId': instance.variationId,
      'variationName': instance.variationName,
      'isReference': instance.isReference,
      'type': instance.type,
      'activated': instance.activated,
      'flags': instance.flags,
    };
