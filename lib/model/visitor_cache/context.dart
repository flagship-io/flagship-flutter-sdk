import 'package:json_annotation/json_annotation.dart';

part 'context.g.dart';

@JsonSerializable()
class Context {
  bool? vip;

  Context({this.vip});

  @override
  String toString() => 'Context(vip: $vip)';

  factory Context.fromJson(Map<String, dynamic> json) {
    return _$ContextFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ContextToJson(this);
}
