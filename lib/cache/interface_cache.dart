mixin IVisitorCacheImplementation {
  int visitorCacheLookupTimeout = 200;

// Called after each fetchFlags. Must upsert the given visitor jsonString in the database.
  void cacheVisitor(String visitorId, String jsonString);

// Called right at visitor creation, return a jsonString corresponding to visitor. Return a jsonString
  Future<String> lookupVisitor(String visitoId);

// Called when a visitor set consent to false. Must erase visitor data related to the given visitor
  void flushVisitor(String visitorId);
}

mixin IHitCacheImplementation {
  int hitCacheLookupTimeout = 200;

  // Called to return the hits contained in the database
  // Attention: The periodic strategy must remove all the previous hits from database and insert the new ones
  // hits Map of <id, hit json format> Id : hit unique id Hit json format
  void cacheHits(Map<String, Map<String, Object>> hits);

// Called to return the hits contained in the database
// This method should timeout and be canceled  if it takes too much time. Configurable, Default 200ms

// SDK : This method should be called at TrackingManager initialization time

// Custom implementation : The custom implementation must load ALL the hits. Hits older than 4H should be ignored
// Map of <id, hit json format>
  Future<List<Map>> lookupHits();

// Called to remove the hits from the database
// Custom implementation : It should remove the hits data corresponding to the hitIds from the database.
  void flushHits(List<String> hitIds);

// Must remove all hits in the database without exception.
  void flushAllHits();
}
