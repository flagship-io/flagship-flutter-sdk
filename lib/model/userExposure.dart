import 'package:flagship/model/flag.dart';
import 'package:flagship/model/modification.dart';

class UserExposure {
  final String visitorId;
  final String? anonymousId;
  final Map<String, Object> context;
  String? key;
  dynamic value;
  FlagMetadata? metadata;

  UserExposure(this.visitorId, this.anonymousId, this.context,
      {required Modification modification}) {
    key = modification.key;
    metadata = FlagMetadata.withMap(modification.toJsonInformation());
    value = modification.value;
  }

  Map<String, Object> toJson() {
    return {
      "UserExposure": {
        "visitorId": this.visitorId,
        "anonymousId": this.anonymousId,
        "context": this.context,
        "key": this.key,
        "value": this.value,
        "metadata": this.metadata?.toJson()
      }
    };
  }
}
