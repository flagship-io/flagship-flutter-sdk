// Continous Strategy
import 'package:flagship/api/service.dart';
import 'package:flagship/cache/interface_cache.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/activate.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/tracking/Batching/batch_manager.dart';
import 'package:flagship/tracking/Batching/pool_queue.dart';
import 'package:flagship/tracking/tracking_manager.dart';
import 'package:flagship/tracking/tracking_manager_batch.dart';
import 'package:flagship/tracking/tracking_manager_config.dart';
import 'package:flagship/utils/logger/log_manager.dart';

class TrackingManageContinuousStrategy extends TrackingManager {
  // Hit pool
  late FlagshipPoolQueue _fsHitPool;
  // Activate pool
  late FlagshipPoolQueue _activatePool;

// Batch manager
  BatchManager? hitBatchManager;

  // Batch manager
  BatchManager? activateBatchManager;

  // Get the hitPool
  FlagshipPoolQueue get fsHitPool {
    return _fsHitPool;
  }

  // Get the activate pool
  FlagshipPoolQueue get activatePool {
    return _activatePool;
  }

  TrackingManageContinuousStrategy(Service service,
      TrackingManagerConfig configTracking, IHitCacheImplementation fsCacheHit)
      : super(service, configTracking, fsCacheHit) {
    // Hits pool
    _fsHitPool = FlagshipPoolQueue(configTracking.poolMaxSize);

    // Activate pool
    _activatePool = FlagshipPoolQueue(configTracking.poolMaxSize);

    // Create batch manager
    hitBatchManager = BatchManager(
        _fsHitPool, sendBatch, configTracking, fsCacheHit,
        label: "batch_of_hits");

    // Create batch manager for activate
    activateBatchManager = BatchManager(
        _activatePool, sendActivateBatch, configTracking, fsCacheHit,
        label: "batch_of_activate");

    this.hitDelegate = hitBatchManager;
    this.activateDelegate = activateBatchManager;
  }

  @override
  // Send Hit
  Future<void> sendHit(BaseHit pHit) async {
    if (pHit.isValid() == true) {
      // Add to pool
      _fsHitPool.addNewTrackElement(pHit);
      this.onCacheHit(pHit);
    } else {
      // When the hit is not valid
      Flagship.logger(Level.ERROR, "Hit not valid");
    }
  }

  // later add code error in the future
  Future<int> sendActivate(Activate activateHit) async {
    // Add the current activate by default
    List<Hit> listOfActivate = [activateHit];
    bool needToClean = false;

    /// When yes, the cache and pool need to be cleaned
    // If we have a failed activate hits
    if (_activatePool.isNotEmpty()) {
      needToClean = true;
      Flagship.logger(Level.ALL,
          "Add previous activates in batch found in the pool activate");
      listOfActivate.addAll(
          _activatePool.extractHitsWithVisitorId(activateHit.visitorId));
    } else {
      // We dont have any failed activate in the pool
    }
    var statusCode = await sendActivateBatch(listOfActivate);
    switch (statusCode) {
      case 200:
      case 204:
        // Clear all the activate in the pool and clear them from cache
        if (needToClean) {
          _activatePool.flushAllTrackFromQueue();
          listOfActivate.remove(
              activateHit); // Remove the current hit before because is not already present in the cache.
          onSendActivateBatchWithSucess(listOfActivate);
        }
        break;
      default:
        _activatePool.addNewTrackElement(activateHit);
        this.onCacheHit(activateHit);
    }
    return statusCode;
  }

  @override
  void onCacheHit(Hit hitToBeCached) {
    // Before cache the hit we save also the date creation
    var bodyToCache = hitToBeCached.bodyTrack;
    if (hitToBeCached.createdAt != null) {
      bodyToCache.addEntries(
          {"createdAt": hitToBeCached.createdAt.toString()}.entries);
    }
    // Cache hits
    fsCacheHit?.cacheHits({hitToBeCached.id: bodyToCache});
  }

  // On sucess sending batch activate
  onSendActivateBatchWithSucess(List<Hit> listOfSendedHits) {
    activateDelegate?.onSendBatchWithSucess(
        listOfSendedHits, BatchCachingStrategy.BATCH_CONTINUOUS_CACHING);
  }

  // On sucess sendig batch hits
  onSendBatchWithSucess(List<Hit> listOfSendedHits) {
    hitDelegate?.onSendBatchWithSucess(
        listOfSendedHits, BatchCachingStrategy.BATCH_CONTINUOUS_CACHING);
  }

  @override
  close() {
    hitBatchManager?.batchFromQueue();
    activateBatchManager?.batchFromQueue();
  }

  @override
  flushAllTracking(String visitorId) {
    // Retreive the ids (hits) and clean hit pool (keep the consent  tracking)
    var listIdsToRemove = this._fsHitPool.flushTrackAndKeepConsent(visitorId);
    // Retreive the ids (activate) and clean activate pool
    listIdsToRemove.addAll(this._activatePool.flushAllTrackFromQueue());
    // Based on those ids will remove them from database
    if (listIdsToRemove.isNotEmpty) {
      this.fsCacheHit?.flushHits(listIdsToRemove);
    }
  }

  @override
  addTrackingElementsToBatch(List<Hit> listOfTracking) {
    listOfTracking.forEach((element) {
      if (element.type == HitCategory.ACTIVATION) {
        this._activatePool.addElement(element);
      } else {
        this._fsHitPool.addElement(element);
      }
    });
  }

  // start batching loops
  @override
  void startBatchingLoop() {
    hitBatchManager?.start();
    activateBatchManager?.start();
  }

  // Stop Batching loops
  @override
  void stopBatchingLoop() {
    hitBatchManager?.pause();
    activateBatchManager?.pause();
  }
}
