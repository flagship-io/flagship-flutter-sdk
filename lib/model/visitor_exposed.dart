// This class represent the Object returned when the activate is done with success.

class VisitorExposed {
  // visitorId
  final String id;
  // AnonymousId
  final String? anonymousId;
  // Visitor context
  final Map<String, Object>? context;

  VisitorExposed(this.id, this.anonymousId, this.context);

// Json representation
  Map<String, dynamic> toJson() {
    return {
      "id": this.id,
      "anonymousId": this.anonymousId,
      "context": this.context
    };
  }
}
