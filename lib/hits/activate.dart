import 'package:flagship/model/modification.dart';

class Activate {
  // final String campaignId;
  // final String variationId;
  // final String variationGroupId;
  // final bool isReference;
  final Modification modification;
  final String visitorId;
  final String envId;

  Activate(this.modification, this.visitorId, this.envId);

  Map<String, Object> toJson() => {
        "vaid": modification.variationId,
        "caid": modification.variationGroupId,
        "vid": visitorId,
        "cid": envId
      };
}
