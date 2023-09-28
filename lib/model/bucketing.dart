import 'package:flagship/model/trageting.dart';
import 'package:flagship/model/variation.dart';

class Bucketing {
  bool panic = false;
  List<BucketCampaign> campaigns = [];
  Bucketing.fromJson(Map<String, dynamic> json) {
    // Set panic
    if (json.keys.contains("panic")) {
      panic = json['panic'] as bool;
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
  String campaignName = "";
  String type = "";
  String slug = "";
  List<VariationGroup> variationGroups = [];

  BucketCampaign.fromJson(Map<String, dynamic> json) {
    // Set idCampaign
    if (json.keys.contains("id")) {
      idCampaign = json['id'] as String;
    }

    // Set Campaign name
    if (json.keys.contains("name")) {
      campaignName = json['name'] as String;
    }

    // Set type Campaign
    if (json.keys.contains("type")) {
      type = json['type'] as String;
    }

    // Set slug
    if (json.keys.contains("slug")) {
      slug = json['slug'] as String;
    }

    var list = (json['variationGroups'] ?? []) as List<dynamic>;
    variationGroups = list.map((e) {
      return VariationGroup.fromJson(e);
    }).toList();
  }
}

class VariationGroup {
  String idVariationGroup = "";
  String variationGroupName = "";
  Targeting? targeting;

  List<Variation> variations = [];

  VariationGroup.fromJson(Map<String, dynamic> json) {
    // Set idVariationGroup
    if (json.keys.contains("id")) {
      idVariationGroup = json['id'] as String;
    }

    // Set idVariationGroup Name
    if (json.keys.contains("name")) {
      variationGroupName = json['name'] as String;
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
