import 'package:flagship/model/trageting.dart';

/// :nodoc:
const String FS_USERS = "fs_users";

enum FSOperator {
  EQUALS,

  NOT_EQUALS,

  GREATER_THAN,

  GREATER_THAN_OR_EQUALS,

  LOWER_THAN,

  LOWER_THAN_OR_EQUALS,

  CONTAINS,

  NOT_CONTAINS,

  Unknown
}

class FSTargetingManager {
  String userId = "";
  Map<String, dynamic> currentContext = {};

  FSTargetingManager(this.userId);

  bool isTargetingGroupIsOkay(Targeting targeting) {
    // Groupe de variations
    List<bool> booleanResultGroup = [];

    for (TargetingGroup itemTargetingGroup in targeting.targetingGroups) {
      booleanResultGroup.add(checkTargetGroupIsOkay(itemTargetingGroup));
    }
    // Here we supposed to have all result , we should have at least one true value to return YES, because we have -OR- between Groups
    return booleanResultGroup.contains(true);
  }

  bool checkTargetGroupIsOkay(TargetingGroup itemTargetGroup) {
    itemTargetGroup.targetings.map((itemTarget) {
      dynamic currentContextValue = getCurrentValueFromCtx(itemTarget.tragetKey);
      // Audience value
      dynamic audienceValue = itemTarget.targetValue;

      // Create the type operator
      FSOperator opType = createOperator(itemTarget.targetOperator);

      // Special treatment for array
      bool isOkay = false;

      if ((audienceValue is List<String>) || (audienceValue is List<int>) || (audienceValue is List<double>)) {
        isOkay = checkTargetingForList(currentContextValue, opType, audienceValue);
      } else {
        isOkay = checkCondition(currentContextValue, opType, audienceValue);
      }

      if (isOkay == false) {
        return false;
      }
    });
    return true;
  }

  bool checkTargetingForList(dynamic currentValue, FSOperator opType, List<dynamic> listAudience) {
    // Chekc the type list before
    bool isOkay = false;
    int result = 0;
    for (dynamic subAudienceValue in listAudience) {
      isOkay = checkCondition(currentValue, opType, subAudienceValue);
      // For those operator, we use  --- OR ---
      if (opType == FSOperator.CONTAINS || opType == FSOperator.EQUALS) {
        if (isOkay == true) {
          return true;
        } else {
          result = 1;
        }
      } else if (opType == FSOperator.NOT_EQUALS || opType == FSOperator.NOT_CONTAINS) {
        result += isOkay ? 0 : 1;
      } else {
        //  return false for others operator
        return false;
      }
    }
    return (result == 0);
  }

  //... CONDITIONS ...//
  bool checkCondition(dynamic cuurentValue, FSOperator operation, dynamic audienceValue) {
    return true;
  }

  /// Compare EQUALS
  bool isCurrentValueEqualToAudienceValue(dynamic currentValue, dynamic audienceValue) {
    /// add throw
    return true;
  }

  /// Compare greater than
  bool isCurrentValueIsGreaterThanAudience(dynamic urrentValue, dynamic audienceValue) {
    /// add throw
    return true;
  }

  /// Compare greater than or equal
  bool isCurrentValueIsGreaterThanOrEqualAudience(dynamic currentValue, dynamic audienceValue) {
    return true;
  }

  /// Compare lower than
  bool isCurrentValueIsLowerThanAudience(dynamic currentValue, dynamic audienceValue) {
    return true;
  }

  /// Compare lower than or equal
  bool isCurrentValueIsLowerThanOrEqualAudience(dynamic currentValue, dynamic audienceValue) {
    return true;
  }

  /// Compare contain
  bool isCurrentValueContainAudience(dynamic currentValue, dynamic audienceValue) {
    return true;
  }

  dynamic getCurrentValueFromCtx(String targetKey) {
    if (targetKey == FS_USERS) {
      return userId;
    } else {
      return currentContext[targetKey];
    }
  }

  static FSOperator createOperator(String raw) {
    if (raw == 'EQUALS') {
      return FSOperator.EQUALS;
    } else if (raw == "NOT_EQUALS") {
      return FSOperator.NOT_EQUALS;
    } else if (raw == "GREATER_THAN") {
      return FSOperator.GREATER_THAN;
    } else if (raw == "GREATER_THAN_OR_EQUALS") {
      return FSOperator.GREATER_THAN_OR_EQUALS;
    } else if (raw == "LOWER_THAN") {
      return FSOperator.LOWER_THAN;
    } else if (raw == "LOWER_THAN_OR_EQUALS") {
      return FSOperator.LOWER_THAN_OR_EQUALS;
    } else if (raw == "CONTAINS") {
      return FSOperator.CONTAINS;
    } else if (raw == "NOT_CONTAINS") {
      return FSOperator.NOT_CONTAINS;
    } else {
      return FSOperator.Unknown;
    }
  }
}
