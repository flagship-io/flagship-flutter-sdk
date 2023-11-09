import 'package:flagship/flagship.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';

class Modifications {
  String type = "json";

  Map<String, dynamic> vals = {};

  Modifications.fromJson(Map<String, dynamic> json) {
    // Set type
    type = (json['type'] ?? "") as String;
    // Set the key value map
    try {
      vals = json['value'] ?? {};
    } catch (e) {
      Flagship.logger(Level.EXCEPTIONS, EXCEPTION.replaceFirst("%s", "$e"));
      vals = {};
    }
  }
}

class Modification {
  final String key;
  final String campaignId;
  final String campaignName;
  final String variationGroupId;
  final String variationGroupName;
  final String variationId;
  final String variationName;
  final bool isReference;
  final String campaignType;
  String? slug;
  dynamic value;
  dynamic defaultValue;

  Modification(
      this.key,
      this.campaignId,
      this.campaignName,
      this.variationGroupId,
      this.variationGroupName,
      this.variationId,
      this.variationName,
      this.isReference,
      this.campaignType,
      this.slug,
      dynamic pValue) {
    value = pValue;
  }

  Map<String, Object> toJson() {
    Map<String, Object> ret = {
      'campaignId': campaignId,
      'campaignName': campaignName,
      'variationGroupId': variationGroupId,
      'variationGroupName': variationGroupName,
      'variationId': variationId,
      'variationName': variationName,
      'isReference': isReference,
      'key': key
    };
    //Secure before adding the nullable
    if (value != null) ret['value'] = value;
    return ret;
  }

  /// Used for getting modification infos
  Map<String, dynamic> toJsonInformation() {
    Map<String, dynamic> ret = {
      'campaignId': campaignId,
      'campaignName': campaignName,
      'variationGroupId': variationGroupId,
      'variationGroupName': variationGroupName,
      'variationId': variationId,
      'variationName': variationName,
      'isReference': isReference,
      'campaignType': campaignType,
      'slug': slug
    };
    return ret;
  }
}
