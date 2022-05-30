import 'package:flagship/visitor/visitor_delegate.dart';

class Flag {
  final String key;
  final dynamic defaultValue;
  final VisitorDelegate _visitorDelegate;

  Flag(this.key, this.defaultValue, this._visitorDelegate);

// Get value for flag
  dynamic value({bool userExposed: true}) {
    return this
        ._visitorDelegate
        .getModification(this.key, this.defaultValue, activate: userExposed);
  }

// Expose flag
  void userExposed() {
    this._visitorDelegate.activateModification(this.key);
  }

// Check if flag exist
  bool exists() {
    return (this._visitorDelegate.getModificationInfo(this.key) != null);
  }

  // Get metaData
  FlagMetadata metaData() {
    return FlagMetadata.withMap(
        this._visitorDelegate.getModificationInfo(this.key));
  }
}

class FlagMetadata {
  late String campaignId;
  late String variationGroupId;
  late String variationId;
  late bool isReference;
  late String campaignType;
  late String slug;

  // FlagMetadata(
  //     {this.campaignId = "",
  //     this.variationGroupId: "",
  //     this.variationId = "",
  //     this.isReference = false,
  //     this.campaignType = "",
  //     this.slug = ""});

  FlagMetadata.withMap(Map<String, Object>? infos) {
    this.campaignId = infos?['campaignId'] as String;
    this.variationGroupId = infos?['variationGroupId'] as String;
    this.variationId = infos?['variationId'] as String;
    this.isReference = infos?['isReference'] as bool;
    this.campaignType = infos?['campaignType'] as String;
    this.slug = infos?['camslugpaignType'] as String;
  }

  Map<String, dynamic> toJson() {
    return {
      "campaignId": this.campaignId,
      "variationGroupId": this.variationGroupId,
      "variationId": this.variationId,
      "isReference": this.isReference,
      "campaignType": this.campaignType,
      "slug": this.slug
    };
  }
}
