import 'package:flagship/cache/interface_cache.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/batch.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/tracking/Batching/pool_queue.dart';
import 'package:flagship/tracking/tracking_manager.dart';
import 'package:flagship/tracking/tracking_manager_config.dart';
import 'package:flagship/utils/flagship_tools.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:pausable_timer/pausable_timer.dart';

class BatchManager with TrackingManagerDelegate, FlagshipPoolQueueDelegate {
// Pausable timer
  late PausableTimer cronTimer;

// Queue
  final FlagshipPoolQueue fsPool;

// CallBack
  final Function sendBatch;

// Cache Hit
  final IHitCacheImplementation fsCacheHit;

// Configuration tracking manager
  final TrackingManagerConfig configTracking;

  bool get cronTimerIsPaused {
    return cronTimer.isPaused;
  }

  BatchManager(
      this.fsPool, this.sendBatch, this.configTracking, this.fsCacheHit) {
    // Timer for cron
    cronTimer = PausableTimer(
        Duration(seconds: configTracking.batchIntervals), batchFromQueue);
    cronTimer.start();
    // Set the delegate
    this.fsPool.delegate = this;
  }

  void startCron() {
    cronTimer.start();
  }

  void batchFromQueue() {
    cronTimer.reset();
    var listOfHitsToSend =
        fsPool.extractXElementFromQueue(configTracking.poolMaxSize);
    if (listOfHitsToSend.isNotEmpty) {
      /// Refracto and check later this reset
      // in periodic strategy will cache the list
      if (this.configTracking.batchStrategy ==
          BatchCachingStrategy.BATCH_PERIODIC_CACHING) {
        // Call the interface to store the entire loop before send it
        this.fsCacheHit.cacheHits(fsPool.hitsFromListToMap(listOfHitsToSend));
      }
      // Send batch
      sendBatch(listOfHitsToSend);
    } else {
      cronTimer.start();
    }
  }

  // Create batch object
  Batch createBatch(List<BaseHit> listOfHits) {
    /// Convert here the list of base to batch object
    return Batch(listOfHits);
  }

  @override
  onSendBatchWithSucess(
      List<Hit> listOfSendedHits, BatchCachingStrategy strategy) {
    // Remove old cache before save a fresh data
    if (strategy == BatchCachingStrategy.BATCH_CONTINUOUS_CACHING) {
      // Refractor later
      List<String> listOfIds = [];
      listOfSendedHits.forEach((element) {
        listOfIds.add(element.id);
      });
      fsCacheHit.flushHits(listOfIds);
    } else if (strategy == BatchCachingStrategy.BATCH_PERIODIC_CACHING) {
      // Clean the pool before save it again, because those hits are sended with success
      listOfSendedHits.forEach((element) {
        fsPool.removeTrackElement(element.id);
      });

      // Flush all hits before cache the new ones
      fsCacheHit.flushAllHits();
      fsCacheHit.cacheHits(FlagshipTools.hitsToMap(fsPool.fsQueue.toList()));
    } else {
      Flagship.logger(
          Level.INFO, "Batching is not implemented on hidden option");
    }
    cronTimer.start();
  }

  @override
  onFailedToSendBatch(List<Hit> listOfHitToSend) {
    cronTimer.start();
    // Save again in pool queue at the bottom
    fsPool.addListOfElements(listOfHitToSend);
  }

  @override
  void onPoolSizeMaxReached() {
    batchFromQueue();
  }
}
