import 'package:flagship/model/trageting.dart';
import 'package:flagship/model/variation.dart';

class Bucketing {
  bool panic = false;
  List<BucketCampaign> campaigns = [];
  bool visitorConsolidation = false;

  Bucketing.fromJson(Map<String, dynamic> json) {
    // Set panic
    if (json.keys.contains("panic")) {
      panic = json['panic'] as bool;
    }
    // Set the xpc
    if (json.keys.contains("visitorConsolidation")) {
      visitorConsolidation = json['visitorConsolidation'] as bool;
    }
    // Construct bucketing object
    var list = (json['campaigns'] ?? []) as List<dynamic>;
    campaigns = list.map((e) {
      return BucketCampaign.fromJson(e);
    }).toList();
  }
}

class BucketCampaign {
  String idCampaign = "";
  String type = "";
  List<VariationGroup> variationGroups = [];

  BucketCampaign.fromJson(Map<String, dynamic> json) {
    // Set idCampaign
    if (json.keys.contains("id")) {
      idCampaign = json['id'] as String;
    }

    // Set idCampaign
    if (json.keys.contains("type")) {
      type = json['type'] as String;
    }

    var list = (json['variationGroups'] ?? []) as List<dynamic>;
    variationGroups = list.map((e) {
      return VariationGroup.fromJson(e);
    }).toList();
  }
}

class VariationGroup {
  String idVariationGroup = "";

  Targeting? targeting;

  List<Variation> variations = [];

  VariationGroup.fromJson(Map<String, dynamic> json) {
    // Set idVariationGroup
    if (json.keys.contains("id")) {
      idVariationGroup = json['id'] as String;
    }

    // Create targeting
    if (json.keys.contains("targeting")) {
      targeting = Targeting.fromJson(json["targeting"]);
    }
    // Create variation
    var list = (json['variations'] ?? []) as List<dynamic>;
    variations = list.map((e) {
      return Variation.fromJson(e);
    }).toList();
  }
}
