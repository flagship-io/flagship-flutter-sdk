import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class AccountSettings {
  bool enabledXPC = false;
  bool enabled1V1T = false;
  Troubleshooting? troubleshooting;

  AccountSettings.fromJson(Map<String, dynamic> json) {
    // Set enabledXPC
    enabledXPC = (json['enabledXPC'] ?? false) as bool;

    // Set enabled1V1T
    enabledXPC = (json['enabled1V1T'] ?? false) as bool;

    // Set Troubleshooting
    troubleshooting = Troubleshooting.fromJson(
        json['troubleshooting'] as Map<String, dynamic>);
  }
}

@JsonSerializable()
class Troubleshooting {
  String? startDate;
  String? endDate;
  String? timezone;
  int traffic = 0;

  Troubleshooting.fromJson(Map<String, dynamic> json) {
    // Set startDate
    startDate = (json['startDate'] ?? "") as String;

    // Set endDate
    endDate = (json['endDate'] ?? "") as String;

    // Set timezone
    timezone = (json['timezone'] ?? "") as String;

    // Set traffic
    traffic = (json['traffic'] ?? 0) as int;
  }
}
