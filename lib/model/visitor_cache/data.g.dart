// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data _$DataFromJson(Map<String, dynamic> json) => Data(
    visitorId: json['visitorId'] as String?,
    anonymousId: json['anonymousId'] as String?,
    consent: json['consent'] as bool?,
    context: json['context'] == null
        ? null
        : (json['context'] as Map<String, dynamic>),
    assignmentsHistory: json['assignmentsHistory'] == null
        ? null
        : (json['assignmentsHistory'] as Map<String, dynamic>),
    campaigns: (json['campaigns'] as List<dynamic>?)
        ?.map((e) => CampaignCache.fromJson(e as Map<String, dynamic>))
        .toList(),
    emotionScoreAI: json['emotionScoreAI'] as String?,
    eaiVisitorScored: json['eaiVisitorScored'] as bool?);

Map<String, dynamic> _$DataToJson(Data instance) => <String, dynamic>{
      'visitorId': instance.visitorId,
      'anonymousId': instance.anonymousId,
      'consent': instance.consent,
      'context': instance.context,
      'assignmentsHistory': instance.assignmentsHistory,
      'campaigns': instance.campaigns,
      'emotionScoreAI': instance.emotionScoreAI,
      'eaiVisitorScored': instance.eaiVisitorScored
    };
