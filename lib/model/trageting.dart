class Targeting {
  List<TargetingGroup> targetingGroups = [];
  Targeting.fromJson(Map<String, dynamic> json) {
    var list = (json['targetingGroups'] ?? []) as List<dynamic>;
    targetingGroups = list.map((e) {
      return TargetingGroup.fromJson(e);
    }).toList();
  }
}

class TargetingGroup {
  List<ItemTarget> targetings = [];
  TargetingGroup.fromJson(Map<String, dynamic> json) {
    var list = (json['targetings'] ?? []) as List<dynamic>;
    targetings = list.map((e) {
      return ItemTarget.fromJson(e);
    }).toList();
  }
}

class ItemTarget {
  /// To complete later
  String targetOperator = ""; // operator
  String tragetKey = ""; // key
  dynamic targetValue; // value

  ItemTarget.fromJson(Map<String, dynamic> json) {
    // Set type operator
    targetOperator = (json['operator'] ?? "") as String;

    // Set tragetKey
    tragetKey = (json['key'] ?? "") as String;

    // Set the key value map
    targetValue = json['value'];
  }
}
