// This class represent the Object returned when the activate is done with success.

import 'package:flagship/model/exposed_flag.dart';

class VisitorExposed {
  // visitorId
  String id = "";
  // AnonymousId
  String? anonymousId;
  // Visitor context
  Map<String, dynamic>? context;

  VisitorExposed(this.id, this.anonymousId, this.context);

  VisitorExposed.fromJson(Map<String, dynamic> json) {
    this.id = (json["id"] as String?) ?? "";
    this.anonymousId = (json["anonymousId"] as String?) ?? "";
    this.context = (json["context"] as Map<String, dynamic>?) ?? {};
  }

// Json representation
  Map<String, dynamic> toJson() {
    return {
      "id": this.id,
      "anonymousId": this.anonymousId,
      "context": this.context
    };
  }
}

/// Used by TRManager to forward infos through closure

class FSExposedInfo {
  final VisitorExposed visitorExposed;
  final ExposedFlag exposedFlag;
  FSExposedInfo({required this.exposedFlag, required this.visitorExposed});
}
