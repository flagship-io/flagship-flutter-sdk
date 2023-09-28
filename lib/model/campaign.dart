import 'package:flagship/model/modification.dart';

import 'variation.dart';

class Campaign {
  String idCampaign = "";
  String variationGroupId = "";
  Variation? variation;
  String campaignType = "";
  String? slug;
  String name = "";
  String variationGroupName = "";

  Campaign(this.idCampaign, this.name, this.variationGroupId,
      this.variationGroupName, this.campaignType, this.slug);

  Campaign.fromJson(Map<String, dynamic> json) {
    // Set the id campaign
    idCampaign = (json['id'] ?? "") as String;
    // Set the name of campaign
    name = (json['name'] ?? "") as String;
    // Set the variation groupId
    variationGroupId = (json['variationGroupId'] ?? "") as String;
    // Set the name of variation group name
    variationGroupName = (json["variationGroupName"] ?? "") as String;
    // Set variation object
    if (json.keys.contains('variation')) {
      variation = Variation.fromJson(json['variation'] as Map<String, dynamic>);
    }
    // Set Type of cmapaign
    campaignType = (json['type'] ?? "") as String;
    // Set slug
    slug = json['slug'];
  }

  Map<String, dynamic> toJson() => {};

  Map<String, dynamic> getAllModificationsValue() {
    return variation?.modifications?.vals ?? {};
  }

  Map<String, Modification> getAllModification() {
    var ret = getAllModificationsValue();

    Map<String, Modification> resultMap = new Map<String, Modification>();
    ret.forEach((key, value) {
      if (this.variation != null) {
        resultMap.addAll({
          key: Modification(
              key,
              this.idCampaign,
              this.name,
              this.variationGroupId,
              this.variationGroupName,
              this.variation?.idVariation ?? "",
              this.variation?.name ?? "",
              this.variation?.reference ?? false,
              this.campaignType,
              this.slug,
              value)
        });
      }
    });
    return resultMap;
  }
}
