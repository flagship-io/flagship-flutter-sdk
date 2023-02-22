class ExposedUser {
  // visitorId
  final String visitorId;
  // AnonymousId
  final String? visitorAnonymousId;
  // Visitor context
  final Map<String, Object> visitorContext;

  ExposedUser(this.visitorId, this.visitorAnonymousId, this.visitorContext);
// Json representation
  Map<String, Object> toJson() {
    return {
      "exposedUser": {
        "visitorId": this.visitorId,
        "anonymousId": this.visitorAnonymousId,
        "context": this.visitorContext
      }
    };
  }
}
