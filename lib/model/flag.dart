import 'package:flagship/dataUsage/data_usage_tracking.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/status.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flagship/visitor/visitor_delegate.dart';

class Flag<T> implements IFlag {
  // Key associated to the Flag
  final String _key;
  // Value for the Flag
  final T _defaultValue;
  // Delegate
  final VisitorDelegate _visitorDelegate;

  Flag(this._key, this._defaultValue, this._visitorDelegate);

// Get value for flag
//
// visitorExposed is true by default
  dynamic value({bool visitorExposed = true}) {
    dynamic retValue = _defaultValue;
    Modification? modif = this._visitorDelegate.getFlagModification(this._key);
    if (modif != null) {
      try {
        {
          if (modif.value == null) {
            // Activate if necessary
            if (visitorExposed) {
              this.visitorExposed();
            }
          } else if (_isSameTypeOrDefaultValueNull(modif.value)) {
            /// Get the flag value
            retValue = modif.value;
            // Activate if necessary
            if (visitorExposed) {
              this.visitorExposed();
            }
          } else {
            DataUsageTracking.sharedInstance().proceesTroubleShootingFlag(
                CriticalPoints.GET_FLAG_VALUE_TYPE_WARNING.name,
                this,
                this._visitorDelegate.visitor);
          }
        }
      } catch (exp) {
        Flagship.logger(Level.INFO,
            "an exception raised  $exp , will return a default value ");
      }
    } else {
      DataUsageTracking.sharedInstance().proceesTroubleShootingFlag(
          CriticalPoints.GET_FLAG_VALUE_FLAG_NOT_FOUND.name,
          this,
          this._visitorDelegate.visitor);
    }
    return retValue;
  }

// Expose Flag
  @Deprecated('Use visitorExposed() instead')
  Future<void> userExposed() async {
    visitorExposed();
  }

  // Expose Flag
  Future<void> visitorExposed() async {
    // Before expose whe should check the Type
    Modification? modification =
        this._visitorDelegate.getFlagModification(this._key);
    if (modification != null) {
      if (modification.value == null ||
          _isSameTypeOrDefaultValueNull(modification.value)) {
        Flagship.logger(
            Level.DEBUG, "Send exposure flag (activate) for : " + _key);

        // Update modification with default value
        modification.defaultValue = this._defaultValue;
        // Activate flag
        this._visitorDelegate.activateFlag(modification);
      } else {
        Flagship.logger(Level.DEBUG,
            "Exposed aborted, because the flagValue type is not the same as default value");
      }
    } else {
      Flagship.logger(Level.DEBUG,
          "Flag: " + _key + "not found, the activate won't be sent");
    }
  }

// Check if Flag exist
  bool exists() {
    return (this._visitorDelegate.getFlagModification(this._key) != null);
  }

  // Get metadata
  @override
  FlagMetadata metadata() {
    // Before expose whe should check the Type
    Modification? modif = this._visitorDelegate.getFlagModification(this._key);
    if (modif != null &&
        (modif.value == null || _isSameTypeOrDefaultValueNull(modif.value))) {
      // when the flag value is null we provide the metadata
      return FlagMetadata.withMap(
          this._visitorDelegate.getModificationInfo(this._key));
    } else {
      return FlagMetadata.withMap(null);
    }
  }

  // Check the type of flag's value with the default value and return true if the same
  // If the default value is null will return true
  bool _isSameTypeOrDefaultValueNull(dynamic value) {
    if (this._defaultValue.runtimeType == Null) {
      return true;
    }
    return (value is T);
  }

  @override
  T get defaultValue => _defaultValue;

  @override
  String get key => _key;

  // Get Status
  FlagStatus getFlagStatus() {
    return this._visitorDelegate.getFlagStatus(this._key);
  }
}

class FlagMetadata {
  String campaignId = "";
  String campaignName = "";
  String variationGroupId = "";
  String variationGroupName = "";
  String variationId = "";
  String variationName = "";
  bool isReference = false;
  String campaignType = "";
  String? slug;

// Create metadata from map entry
  FlagMetadata.withMap(Map<String, dynamic>? infos) {
    if (infos != null) {
      this.campaignId = (infos['campaignId'] as String?) ?? "";
      this.campaignName = (infos['campaignName'] as String?) ?? "";

      this.variationGroupId = (infos['variationGroupId'] as String?) ?? "";
      this.variationGroupName = (infos['variationGroupName'] as String?) ?? "";

      this.variationId = (infos['variationId'] as String?) ?? "";
      this.variationName = (infos['variationName'] as String?) ?? "";

      this.isReference = (infos['isReference'] as bool?) ?? false;
      this.campaignType = (infos['campaignType'] as String?) ?? "";
      this.slug = (infos['slug'] as String?) ?? "";
    }
  }

// Get the json format
  Map<String, dynamic> toJson() {
    return {
      "campaignId": this.campaignId,
      "campaignName": this.campaignName,
      "variationGroupId": this.variationGroupId,
      "variationGroupName": this.variationGroupName,
      "variationId": this.variationId,
      "variationName": this.variationName,
      "isReference": this.isReference,
      "campaignType": this.campaignType,
      "slug": this.slug,
    };
  }
}

abstract class IFlag<T> {
  // Key for flag
  String get key;

  // Default value
  T get defaultValue;

  // Get metadata
  FlagMetadata metadata();
}

// Flag Sync Status
enum FlagSyncStatus {
  CREATED,
  CONTEXT_UPDATED,
  FLAGS_FETCHED,
  AUTHENTICATED,
  UNAUTHENTICATED
}

extension FlagSyncLogMessage on FlagSyncStatus {
  String warningMessage(String visitorId, String flagKey) {
    String ret = "";
    switch (this) {
      case FlagSyncStatus.CREATED:
        ret =
            "Visitor `$visitorId` has been created without calling `fetchFlags` method afterwards, the value of the flag `$flagKey` may be outdated.";
        break;
      case FlagSyncStatus.CONTEXT_UPDATED:
        ret =
            " Visitor context for visitor `$visitorId` has been updated without calling `fetchFlags` method afterwards, the value of the flag `$flagKey` may be outdated.";
        break;
      case FlagSyncStatus.AUTHENTICATED:
        ret =
            "Visitor `$visitorId` has been authenticated without calling `fetchFlags` method afterwards, the value of the flag `$flagKey` may be outdated.";
        break;
      case FlagSyncStatus.UNAUTHENTICATED:
        ret =
            "Visitor `$visitorId` has been unauthenticated without calling `fetchFlags` method afterwards, the value of the flag `$flagKey` may be outdated.";
        break;
      case FlagSyncStatus.FLAGS_FETCHED:
      default:
        break;
    }
    return ret;
  }
}
