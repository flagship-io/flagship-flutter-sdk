import 'package:flagship/model/flag.dart';

class ExposedFlag {
  // Flag name
  final String flagKey;
  // Flag value
  final dynamic flagValue;
  // Default Value
  final dynamic defaultValue;
  // Metadata
  final FlagMetadata flagMetadata;

  ExposedFlag(
      this.flagKey, this.flagValue, this.defaultValue, this.flagMetadata);

// Json representation
  Map<String, Object> toJson() {
    return {
      "ExposedFlag": {
        "flagKey": this.flagKey,
        "flagValue": this.flagValue,
        "defaultValue": this.defaultValue,
        "flagMetadata": this.flagMetadata.toJson()
      }
    };
  }
}
