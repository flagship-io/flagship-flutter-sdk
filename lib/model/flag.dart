import 'package:flagship/flagship.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flagship/visitor/visitor_delegate.dart';

class Flag<T> {
  // Key associated to the Flag
  final String _key;
  // Value for the Flag
  final T _defaultValue;
  // Delegate
  final VisitorDelegate _visitorDelegate;

  Flag(this._key, this._defaultValue, this._visitorDelegate);

// Get value for flag
//
// userExposed is true by default
  T value({bool userExposed: true}) {
    Modification? modif = this._visitorDelegate.getFlagModification(this._key);
    if (modif != null) {
      if (_isSameType(modif.value)) {
        // Activate if necessary
        if (userExposed) {
          this.userExposed();
        }
        return modif.value as T;
      }
    }
    return _defaultValue;
  }

// Expose Flag
  Future<void> userExposed() async {
    // Before expose whe should check the Type
    Modification? modification =
        this._visitorDelegate.getFlagModification(this._key);
    if (modification != null) {
      if (modification.value == null || _isSameType(modification.value)) {
        Flagship.logger(Level.DEBUG, "Send activate for the flag: " + _key);

        // Update modification with default value
        modification.defaultValue = this._defaultValue;
        // Activate flag
        this._visitorDelegate.activateFlag(modification);
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
}

class FlagMetadata {
  late String campaignId = "";
  late String variationGroupId = "";
  late String variationId = "";
  late bool isReference = false;
  late String campaignType = "";
  late String slug = "";

// Create metadata from map entry
  FlagMetadata.withMap(Map<String, Object>? infos) {
    if (infos != null) {
      this.campaignId = (infos['campaignId'] as String);
      this.variationGroupId = infos['variationGroupId'] as String;
      this.variationId = infos['variationId'] as String;
      this.isReference = infos['isReference'] as bool;
      this.campaignType = infos['campaignType'] as String;
      this.slug = infos['slug'] as String;
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
