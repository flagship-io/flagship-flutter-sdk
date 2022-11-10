import 'package:flagship/cache/cache_manager.dart';
import 'package:flagship/hits/batch.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/tracking/pool_queue.dart';
import 'package:flagship/tracking/tracking_manager.dart';
import 'package:flagship/tracking/tracking_manager_config.dart';
import 'package:pausable_timer/pausable_timer.dart';

class BatchManager with TrackingManagerDelegate, FlagshipPoolQueueDelegate {
  //int lengthOfBatch;

  //int batchIntervals;

  late PausableTimer cronTimer;

  final FlagshipPoolQueue fsPool;

  final Function sendBatch;

  final HitCacheManager fsCacheHit;

  final TrackingManagerConfig configTracking;

  bool get cronTimerIsPaused {
    return cronTimer.isPaused;
  }

  BatchManager(this.fsPool, this.sendBatch, this.configTracking, this.fsCacheHit) {
    // Timer for cron
    cronTimer = PausableTimer(Duration(seconds: configTracking.batchIntervals), batchFromQueue);
    cronTimer.start();
    // Set the delegate
    this.fsPool.delegate = this;
  }

  void startCron() {
    cronTimer.start();
  }

  void batchFromQueue() {
    cronTimer.reset();
    print(" ------ Create a batch from a queue and send it ------");
    var listToSend = fsPool.extractXElementFromQueue(configTracking.poolMaxSize);

    if (listToSend.isEmpty) {
      // Stop the cron may be ....
      print("--------- Pause the cron because the queue is empty -----------");
    } else {
      // var batchToSend = this.createBatch(listToSend);
      // Before send this batch will check the validity
      sendBatch(listToSend);
    }
  }

  // Create batch object
  Batch createBatch(List<BaseHit> listOfHits) {
    /// Convert here the list of base to batch object
    return Batch(listOfHits);
  }

  @override
  onSendBatchWithSucess() {
    // Remove old cache before save a fresh data
    fsCacheHit.flushHits();
    switch (configTracking.batchStrategy) {
      case BatchCachingStrategy.BATCH_CONTINUOUS_CACHING:
        break;
      case BatchCachingStrategy.BATCH_PERIODIC_CACHING:
        fsPool.fsQueue.forEach((element) {
          fsCacheHit.cacheHit(element.bodyTrack);
        });
        break;
    }
    cronTimer.start();
  }

  @override
  onFailedToSendBatch(List<Hit> listOfHitToSend) {
    cronTimer.start();
    // Save again in pool queue at the bottom
    fsPool.addListOfElementsToTheBottom(listOfHitToSend);
  }

  @override
  void onPoolSizeMaxReached() {
    batchFromQueue();
  }
}

//   void batchingContinousstrategy(BaseHit newHit) {
//     // It must check the hit validation
//     if (newHit.isValid() == true) {
//       // When the hit is valid
//       // It must add the hit in the tracking manager pool
//       fsPool.addTrackElement(newHit);
//       // It must cache the hit in the database by calling the cacheHit method of the cache manager
//       fsCacheHit.cacheHit(newHit.bodyTrack);
//     } else {
//       // When the hit is not valid
//       Flagship.logger(Level.ERROR, "Hit not valid");
//       // log an error
//     }
//   }

//   // Remove all hits from pool , When hits must be deleted due to visitor consent false
//   void removeHitsWhenConsnetIsFalse(String visitorId) {
//     // Remove all hits from pool , When hits must be deleted due to visitor consent false
//     // Hits must be deleted from the pool (expect the Consent type ones).
//     fsPool.removeHitsForVisitorId(visitorId);
//     // Hits must be deleted from the database by calling flushHits method of the cache manager.
//     fsCacheHit.flushHits();
//   }

// // Extract hits from pool
//   List<BaseHit>? extractXHitsFromthePool(int xElem) {
//     return fsPool.extractXElementFromQueue(xElem);
//   }

//   /// Create and send a batch
//   createBatch(String visitorId) {
//     var listTobatch = fsPool.extractHitsWithVisitorId(visitorId);
//     if (listTobatch.length > 0) {
//       // this.sendHit(BatchManager(listTobatch).convertToBatchEvent());
//     }
//   }
