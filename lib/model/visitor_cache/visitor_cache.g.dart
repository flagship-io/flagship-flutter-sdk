// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visitor_cache.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VisitorCache _$VisitorCacheFromJson(Map<String, dynamic> json) => VisitorCache(
      version: (json['version'] as num?)?.toInt(),
      data: json['data'] == null
          ? null
          : Data.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VisitorCacheToJson(VisitorCache instance) =>
    <String, dynamic>{
      'version': instance.version,
      'data': instance.data,
    };
