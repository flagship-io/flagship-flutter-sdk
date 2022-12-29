import 'package:json_annotation/json_annotation.dart';

part 'flags.g.dart';

@JsonSerializable()
class Flags {
  String? text;
  String? textColor;

  Flags({this.text, this.textColor});

  @override
  String toString() => 'Flags(text: $text, textColor: $textColor)';

  factory Flags.fromJson(Map<String, dynamic> json) => _$FlagsFromJson(json);

  Map<String, dynamic> toJson() => _$FlagsToJson(this);
}
