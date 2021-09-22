class Modifications {
  String type;

  Map<String, dynamic> vals;

  Modifications.fromJson(Map<String, dynamic> json)
      : type = json['type'] as String,
        vals = json['value'] as Map<String, dynamic>;
}

class Modification {
  final String key;
  final String campaignId;
  final String variationGroupId;
  final String variationId;
  final bool isReference;
  dynamic value;

  Modification(this.key, this.campaignId, this.variationGroupId,
      this.variationId, this.isReference, dynamic pValue) {
    value = pValue;
  }

  Map<String, Object> toJson() {
    Map<String, Object> ret = {
      'campaignId': campaignId,
      'variationGroupId': variationGroupId,
      'variationId': variationId,
      'isReference': isReference,
      'key': key
    };
    //Secure before adding the nullable
    if (value != null) ret['value'] = value;
    return ret;
  }
}
