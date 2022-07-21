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

class TargetingManager {
  String userId = "";
  Map<String, dynamic> currentContext = {};

  TargetingManager(this.userId, this.currentContext) {
    // add fs_all_users
    this.currentContext["fs_all_users"] = "";
  }

  bool isTargetingGroupIsOkay(Targeting? targeting) {
    // Groupe de variations,
    List<bool> booleanResultGroup = [];
    for (TargetingGroup itemGroup in targeting?.targetingGroups ?? []) {
      booleanResultGroup.add(checkTargetGroupIsOkay(itemGroup));
    }

    return booleanResultGroup.contains(true);
  }

  bool checkTargetGroupIsOkay(TargetingGroup itemTargetGroup) {
    for (ItemTarget itemTarget in itemTargetGroup.targetings) {
      dynamic currentContextValue = getCurrentValueFromCtx(itemTarget.tragetKey);
      // Audience value
      dynamic audienceValue = itemTarget.targetValue;

      // Create the type operator
      FSOperator opType = createOperator(itemTarget.targetOperator);

      // Special treatment for array
      bool isOkay = false;

      if ((audienceValue is List<String>) ||
          (audienceValue is List<int>) ||
          (audienceValue is List<double>) ||
          (audienceValue is List<dynamic>)) {
        isOkay = checkTargetingForList(currentContextValue, opType, audienceValue);
      } else {
        isOkay = checkCondition(currentContextValue, opType, audienceValue);
      }

      if (isOkay == false) {
        return false;
      }
    }
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
        //  eturn false for others operator
        return false;
      }
    }
    return (result == 0);
  }

  //... CONDITIONS ...//
  bool checkCondition(dynamic cuurentValue, FSOperator operation, dynamic audienceValue) {
    switch (operation) {
      case FSOperator.EQUALS:
        return isCurrentValueEqualToAudienceValue(cuurentValue, audienceValue);
      case FSOperator.NOT_EQUALS:
        return !isCurrentValueEqualToAudienceValue(cuurentValue, audienceValue);
      case FSOperator.GREATER_THAN:
        return isCurrentValueIsGreaterThanAudience(cuurentValue, audienceValue);
      case FSOperator.GREATER_THAN_OR_EQUALS:
        return isCurrentValueIsGreaterThanOrEqualAudience(cuurentValue, audienceValue);
      case FSOperator.LOWER_THAN:
        return isCurrentValueIsLowerThanAudience(cuurentValue, audienceValue);
      case FSOperator.LOWER_THAN_OR_EQUALS:
        return isCurrentValueIsLowerThanOrEqualAudience(cuurentValue, audienceValue);
      case FSOperator.CONTAINS:
        return isCurrentValueContainAudience(cuurentValue, audienceValue);
      case FSOperator.NOT_CONTAINS:
        return !isCurrentValueContainAudience(cuurentValue, audienceValue);
      default:
        return false;
    }
  }

  /// Compare EQUALS
  bool isCurrentValueEqualToAudienceValue(dynamic currentValue, dynamic audienceValue) {
    return (currentValue == audienceValue);
  }

  /// Compare greater than
  bool isCurrentValueIsGreaterThanAudience(dynamic currentValue, dynamic audienceValue) {
    if (currentValue is num && audienceValue is num) {
      return (currentValue > audienceValue);
    } else if (currentValue is String && audienceValue is String) {
      return (currentValue.compareTo(audienceValue) == 1);
    } else {
      return false;
    }
  }

  /// Compare greater than or equal
  bool isCurrentValueIsGreaterThanOrEqualAudience(dynamic currentValue, dynamic audienceValue) {
    if (currentValue is num && audienceValue is num) {
      return (currentValue >= audienceValue);
    } else if (currentValue is String && audienceValue is String) {
      return (currentValue.compareTo(audienceValue) == 1 || currentValue.compareTo(audienceValue) == 0);
    } else {
      return false;
    }
  }

  /// Compare lower than
  bool isCurrentValueIsLowerThanAudience(dynamic currentValue, dynamic audienceValue) {
    if (currentValue is num && audienceValue is num) {
      return (currentValue < audienceValue);
    } else if (currentValue is String && audienceValue is String) {
      return (currentValue.compareTo(audienceValue) == -1);
    } else {
      return false;
    }
  }

  /// Compare lower than or equal
  bool isCurrentValueIsLowerThanOrEqualAudience(dynamic currentValue, dynamic audienceValue) {
    if (currentValue is num && audienceValue is num) {
      return (currentValue <= audienceValue);
    } else if (currentValue is String && audienceValue is String) {
      return (currentValue.compareTo(audienceValue) == -1 || currentValue.compareTo(audienceValue) == 0);
    } else {
      return false;
    }
  }

  /// Compare contain
  bool isCurrentValueContainAudience(dynamic currentValue, dynamic audienceValue) {
    if (currentValue is String && audienceValue is String) {
      return (currentValue).contains(audienceValue);
    }
    return false;
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
