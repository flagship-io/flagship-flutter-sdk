import 'package:flagship/model/flag.dart';

class ExposedFlag {
  // Flag name
  final String flagKey;
  // Flag value
  final dynamic flagValue;
  // Metadata
  final FlagMetadata flagMetadata;

  ExposedFlag(this.flagKey, this.flagValue, this.flagMetadata);

// Json representation
  Map<String, Object> toJson() {
    return {
      "ExposedFlag": {
        "flagKey": this.flagKey,
        "flagValue": this.flagValue,
        "flagMetadata": this.flagMetadata.toJson()
      }
    };
  }
}
