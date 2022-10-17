import 'package:flagship/hits/hit.dart';

mixin IHitCacheManager {
  // save hit
  void cacheHit(Map<String, Object> rawHit);
  // Flush hit
  void flushHits();
}

class HitCacheManager with IHitCacheManager {
  @override
  void cacheHit(Map<String, Object> rawHit) {
    print("--------- cache hit -----------");
  }

  @override
  void flushHits() {
    print("--------- flush hits ---------");
  }
}



// class ContinousCachingStrategy with CacheManager {
//   @override
//   void cacheHits(BaseHit pHit) {
//     print(" ############## Cache hits - ContinousCachingStrategy #################");
//   }
// }

// class PeriodicCachingStrategy with CacheManager {
//   @override
//   void cacheHits(BaseHit pHit) {
//     print(" ############## Cache hits - PeriodicCachingStrategy #################");
//   }
// }
