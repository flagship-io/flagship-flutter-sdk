import 'dart:convert';
import 'dart:math';

import 'package:flagship/cache/cache_manager.dart';
import 'package:flagship/cache/interface_cache.dart';
import 'package:flagship/hits/batch.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/tracking/pool_queue.dart';
import 'package:flagship/tracking/tracking_manager.dart';
import 'package:flagship/tracking/tracking_manager_config.dart';
import 'package:flagship/utils/flagship_tools.dart';
import 'package:pausable_timer/pausable_timer.dart';

class BatchManager with TrackingManagerDelegate, FlagshipPoolQueueDelegate {
  late PausableTimer cronTimer;

  final FlagshipPoolQueue fsPool;

  final Function sendBatch;

  final IHitCacheImplementation fsCacheHit;

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
    print(" ------ Create a batch from a queue and send it ------");
    var listToSend =
        fsPool.extractXElementFromQueue(configTracking.poolMaxSize);

    if (listToSend.isEmpty) {
      // Stop the cron may be ....
      print("--------- Pause the cron because the queue is empty -----------");
    } else {
      // var batchToSend = this.createBatch(listToSend);
      // Before send this batch will check the validity

      // in periodic strategy will cache the list
      if (this.configTracking.batchStrategy ==
          BatchCachingStrategy.BATCH_PERIODIC_CACHING) {
        // Call the interface to store the entire loop before send it
        this.fsCacheHit.cacheHits(fsPool.hitsFromListToMap(listToSend));
      }
      // Send batch
      sendBatch(listToSend);
    }
  }

  // Create batch object
  Batch createBatch(List<BaseHit> listOfHits) {
    /// Convert here the list of base to batch object
    return Batch(listOfHits);
  }

  @override
  onSendBatchWithSucess(List<BaseHit> listOfSendedHits) {
    // Remove old cache before save a fresh data

    switch (configTracking.batchStrategy) {
      case BatchCachingStrategy.BATCH_CONTINUOUS_CACHING:
        // Refractor later
        List<String> listOfIds = [];
        listOfSendedHits.forEach((element) {
          listOfIds.add(element.id);
        });
        fsCacheHit.flushHits(listOfIds);
        break;
      case BatchCachingStrategy.BATCH_PERIODIC_CACHING:
        // Clean the pool before save it again, because those hits are sended with success
        listOfSendedHits.forEach((element) {
          fsPool.removeTrackElement(element.id);
        });

        // Flush all hits before cache the new ones
        fsCacheHit.flushAllHits();
        fsCacheHit.cacheHits(FlagshipTools.hitsToMap(fsPool.fsQueue.toList()));
        break;
    }

    cronTimer.start();
  }

  @override
  onFailedToSendBatch(List<BaseHit> listOfHitToSend) {
    cronTimer.start();
    // Save again in pool queue at the bottom
    fsPool.addListOfElements(listOfHitToSend);
  }

  @override
  void onPoolSizeMaxReached() {
    batchFromQueue();
  }
}
