import 'package:json_annotation/json_annotation.dart';

part 'assignments_history.g.dart';

@JsonSerializable()
class AssignmentsHistory {
  String? c60kbmc4m3ah3788s4f0;
  String? c348750k33nnjpllqpi0;

  AssignmentsHistory({
    this.c60kbmc4m3ah3788s4f0,
    this.c348750k33nnjpllqpi0,
  });

  @override
  String toString() {
    return 'AssignmentsHistory(c60kbmc4m3ah3788s4f0: $c60kbmc4m3ah3788s4f0, c348750k33nnjpllqpi0: $c348750k33nnjpllqpi0)';
  }

  factory AssignmentsHistory.fromJson(Map<String, dynamic> json) {
    return _$AssignmentsHistoryFromJson(json);
  }

  Map<String, dynamic> toJson() => _$AssignmentsHistoryToJson(this);
}
