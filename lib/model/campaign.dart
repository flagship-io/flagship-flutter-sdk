import 'package:flagship/model/modification.dart';

import 'variation.dart';

class Campaign {
  String idCampaign;
  String variationGroupId;
  Variation variation;

  Campaign.fromJson(Map<String, dynamic> json)
      : idCampaign = json['id'] as String,
        variationGroupId = json['variationGroupId'] as String,
        variation =
            Variation.fromJson(json['variation'] as Map<String, dynamic>);

  Map<String, dynamic> toJson() => {};

  Map<String, dynamic> getAllModificationsValue() {
    return variation.modifications.vals;
  }

  Map<String, Modification> getAllModificationBis() {
    var ret = getAllModificationsValue();

    Map<String, Modification> resultMap = new Map<String, Modification>();
    ret.forEach((key, value) {
      print("@@@@@@@@@@@@@@@@@@@@@@" + key + "@@@@@@@@@@@@@@@@@@@@@");
      resultMap.addAll({
        key: Modification(key, this.idCampaign, this.variationGroupId,
            this.variation.idVariation, this.variation.reference, value)
      });
    });
    return resultMap;
  }
}
