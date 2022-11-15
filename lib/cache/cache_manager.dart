import 'package:flagship/hits/hit.dart';

mixin IHitCacheManager {
  // save hit
  void cacheHits(Map<String, Object> rawHit);
  // Flush hit
  void flushAllHits();

  // Flush
  void flushHits(List<String> hitIds);
}

class HitCacheManager with IHitCacheManager {
  @override
  void cacheHits(Map<String, Object> rawHit) {
    print("--------- cache hit -----------");
  }

  @override
  void flushAllHits() {
    print("--------- flush hits ---------");
  }

  @override
  void flushHits(List<String> hitIds) {}
}
