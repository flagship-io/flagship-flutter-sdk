import 'package:json_annotation/json_annotation.dart';

import 'campaign_cache.dart';
part 'data.g.dart';

@JsonSerializable()
class Data {
  String? visitorId;
  String? anonymousId;
  bool? consent;
  Map<String, dynamic>? context;
  Map<String, dynamic>? assignmentsHistory;
  List<CampaignCache>? campaigns;

  Data({
    this.visitorId,
    this.anonymousId,
    this.consent,
    this.context,
    this.assignmentsHistory,
    this.campaigns,
  });

  @override
  String toString() {
    return 'Data(visitorId: $visitorId, anonymousId: $anonymousId, consent: $consent, context: $context, assignmentsHistory: $assignmentsHistory, campaigns: $campaigns)';
  }

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);

  Map<String, dynamic> toJson() => _$DataToJson(this);
}
