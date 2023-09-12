import 'package:flagship/flagship.dart';
import 'package:flagship/model/modification.dart';
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
  T value({bool visitorExposed = true}) {
    Modification? modif = this._visitorDelegate.getFlagModification(this._key);
    if (modif != null) {
      if (_isSameType(modif.value)) {
        // Activate if necessary
        if (visitorExposed) {
          this.visitorExposed();
        }
        return modif.value as T;
      }
    }
    return _defaultValue;
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
      if (modification.value == null || _isSameType(modification.value)) {
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
    if (modif != null && (modif.value == null || _isSameType(modif.value))) {
      // when the flag value is null we provide the metadata
      return FlagMetadata.withMap(
          this._visitorDelegate.getModificationInfo(this._key));
    } else {
      return FlagMetadata.withMap(null);
    }
  }

  // Check the type of flag's value with the default value
  bool _isSameType(dynamic value) {
    return (value is T);
  }

  @override
  T get defaultValue => _defaultValue;

  @override
  String get key => _key;
}

class FlagMetadata {
  String campaignId = "";
  String variationGroupId = "";
  String variationId = "";
  bool isReference = false;
  String campaignType = "";
  String? slug;

// Create metadata from map entry
  FlagMetadata.withMap(Map<String, dynamic>? infos) {
    if (infos != null) {
      this.campaignId = (infos['campaignId'] as String);
      this.variationGroupId = infos['variationGroupId'] as String;
      this.variationId = infos['variationId'] as String;
      this.isReference = infos['isReference'] as bool;
      this.campaignType = infos['campaignType'] as String;
      this.slug = infos['slug'];
    }
  }

// Get the json format
  Map<String, dynamic> toJson() {
    return {
      "campaignId": this.campaignId,
      "variationGroupId": this.variationGroupId,
      "variationId": this.variationId,
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
