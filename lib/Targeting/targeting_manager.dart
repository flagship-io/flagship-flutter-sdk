import 'package:flagship/flagship.dart';
import 'package:flagship/model/trageting.dart';
import 'package:flagship/utils/logger/log_manager.dart';

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
      dynamic currentContextValue =
          getCurrentValueFromCtx(itemTarget.tragetKey);
      // Audience value
      dynamic audienceValue = itemTarget.targetValue;

      // Create the type operator
      FSOperator opType = createOperator(itemTarget.targetOperator);
      bool isOkay = false;

      // Special treatment for array
      if ((audienceValue is List<String>) ||
          (audienceValue is List<int>) ||
          (audienceValue is List<double>) ||
          (audienceValue is List<dynamic>)) {
        isOkay =
            checkTargetingForList(currentContextValue, opType, audienceValue);
      } else {
        isOkay = checkCondition(currentContextValue, opType, audienceValue);
      }

      Flagship.logger(Level.DEBUG,
          "For the key \"${itemTarget.tragetKey}\" the condition: ( $currentContextValue ${opType.name} $audienceValue )${isOkay ? " is " : " is not "} satisfied");

      if (isOkay == false) {
        return false; // if false no need to check others
      }
    }
    return true;
  }

  bool checkTargetingForList(
      dynamic currentValue, FSOperator opType, List<dynamic> listAudience) {
    // Check the type list before
    bool isOkay = false;
    bool isTargetingOkayForList = true;
    for (dynamic subAudienceValue in listAudience) {
      isOkay = checkCondition(currentValue, opType, subAudienceValue);
      // For those operator, we use  --- OR ---
      if (opType == FSOperator.CONTAINS || opType == FSOperator.EQUALS) {
        if (isOkay == true) {
          return true; // Exit no need to check others
        } else {
          isTargetingOkayForList = false;
        }
        // For those operator, we use  --- AND ---
      } else if (opType == FSOperator.NOT_EQUALS ||
          opType == FSOperator.NOT_CONTAINS) {
        if (isOkay == false) {
          return false; // Exit No need to check others
        }
      } else {
        // Return false for others operator
        isTargetingOkayForList = false;
      }
    }
    return isTargetingOkayForList;
  }

  //... CONDITIONS ...//
  bool checkCondition(
      dynamic cuurentValue, FSOperator operation, dynamic audienceValue) {
    switch (operation) {
      case FSOperator.EQUALS:
        return isCurrentValueEqualToAudienceValue(cuurentValue, audienceValue);
      case FSOperator.NOT_EQUALS:
        return !isCurrentValueEqualToAudienceValue(cuurentValue, audienceValue);
      case FSOperator.GREATER_THAN:
        return isCurrentValueIsGreaterThanAudience(cuurentValue, audienceValue);
      case FSOperator.GREATER_THAN_OR_EQUALS:
        return isCurrentValueIsGreaterThanOrEqualAudience(
            cuurentValue, audienceValue);
      case FSOperator.LOWER_THAN:
        return isCurrentValueIsLowerThanAudience(cuurentValue, audienceValue);
      case FSOperator.LOWER_THAN_OR_EQUALS:
        return isCurrentValueIsLowerThanOrEqualAudience(
            cuurentValue, audienceValue);
      case FSOperator.CONTAINS:
        return isCurrentValueContainAudience(cuurentValue, audienceValue);
      case FSOperator.NOT_CONTAINS:
        return !isCurrentValueContainAudience(cuurentValue, audienceValue);
      default:
        return false;
    }
  }

  /// Compare EQUALS
  bool isCurrentValueEqualToAudienceValue(
      dynamic currentValue, dynamic audienceValue) {
    return (currentValue == audienceValue);
  }

  /// Compare greater than
  bool isCurrentValueIsGreaterThanAudience(
      dynamic currentValue, dynamic audienceValue) {
    if (currentValue is num && audienceValue is num) {
      return (currentValue > audienceValue);
    } else if (currentValue is String && audienceValue is String) {
      return (currentValue.compareTo(audienceValue) == 1);
    } else {
      return false;
    }
  }

  /// Compare greater than or equal
  bool isCurrentValueIsGreaterThanOrEqualAudience(
      dynamic currentValue, dynamic audienceValue) {
    if (currentValue is num && audienceValue is num) {
      return (currentValue >= audienceValue);
    } else if (currentValue is String && audienceValue is String) {
      return (currentValue.compareTo(audienceValue) == 1 ||
          currentValue.compareTo(audienceValue) == 0);
    } else {
      return false;
    }
  }

  /// Compare lower than
  bool isCurrentValueIsLowerThanAudience(
      dynamic currentValue, dynamic audienceValue) {
    if (currentValue is num && audienceValue is num) {
      return (currentValue < audienceValue);
    } else if (currentValue is String && audienceValue is String) {
      return (currentValue.compareTo(audienceValue) == -1);
    } else {
      return false;
    }
  }

  /// Compare lower than or equal
  bool isCurrentValueIsLowerThanOrEqualAudience(
      dynamic currentValue, dynamic audienceValue) {
    if (currentValue is num && audienceValue is num) {
      return (currentValue <= audienceValue);
    } else if (currentValue is String && audienceValue is String) {
      return (currentValue.compareTo(audienceValue) == -1 ||
          currentValue.compareTo(audienceValue) == 0);
    } else {
      return false;
    }
  }

  /// Compare contain
  bool isCurrentValueContainAudience(
      dynamic currentValue, dynamic audienceValue) {
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
    for (var value in FSOperator.values) {
      if (value.toString().toString().split('.').last == raw) {
        return value;
      }
    }
    return FSOperator.Unknown;
  }
}
