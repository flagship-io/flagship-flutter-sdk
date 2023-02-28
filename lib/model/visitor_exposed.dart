// This class represent the Object returned when the activate is done with success.

class VisitorExposed {
  // visitorId
  final String visitorId;
  // AnonymousId
  final String? visitorAnonymousId;
  // Visitor context
  final Map<String, Object>? visitorContext;

  VisitorExposed(this.visitorId, this.visitorAnonymousId, this.visitorContext);

// Json representation
  Map<String, dynamic> toJson() {
    return {
      "visitorId": this.visitorId,
      "visitorAnonymousId": this.visitorAnonymousId,
      "visitorContext": this.visitorContext
    };
  }
}
