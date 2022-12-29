import 'package:json_annotation/json_annotation.dart';

import 'data.dart';

part 'visitor_cache.g.dart';

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
}
