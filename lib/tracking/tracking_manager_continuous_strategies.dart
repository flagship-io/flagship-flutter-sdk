// Continous Strategy
import 'dart:convert';
import 'package:flagship/api/endpoints.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/cache/interface_cache.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/activate.dart';
import 'package:flagship/hits/batch.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/tracking/Batching/batch_manager.dart';
import 'package:flagship/tracking/Batching/pool_queue.dart';
import 'package:flagship/tracking/tracking_manager.dart';
import 'package:flagship/tracking/tracking_manager_config.dart';
import 'package:flagship/utils/constants.dart';
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
      this.onCacheHits({pHit.id: pHit.bodyTrack});
    } else {
      // When the hit is not valid
      Flagship.logger(Level.ERROR, "Hit not valid");
    }
  }

  // later add code error in the future
  Future<void> sendActivate(Activate activateHit) async {
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
    sendActivateBatch(listOfActivate).then((statusCode) {
      switch (statusCode) {
        case 200:
        case 204:
          Flagship.logger(Level.INFO, ACTIVATE_SUCCESS);
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

          this.onCacheHits({activateHit.id: activateHit.bodyTrack});
      }
    });
  }

// Sending batchs

  Future<void> sendBatch(List<Hit> listOfHitToSend) async {
    // Create url
    String urlString = Endpoints.EVENT;
    try {
      var response = await service.sendHttpRequest(
          RequestType.Post,
          urlString,
          Endpoints.getFSHeader(this.apiKey),
          jsonEncode(Batch(listOfHitToSend).bodyTrack),
          timeoutMs: TIMEOUT_REQUEST);
      switch (response.statusCode) {
        case 200:
        case 204:
        case 201:
          Flagship.logger(Level.INFO, HIT_SUCCESS);
          Flagship.logger(
              Level.INFO, jsonEncode(Batch(listOfHitToSend).bodyTrack),
              isJsonString: true);
          onSendBatchWithSucess(listOfHitToSend);
          break;
        default:
          Flagship.logger(Level.ERROR, HIT_FAILED);
          hitDelegate?.onFailedToSendBatch(listOfHitToSend);
      }
    } catch (error) {
      hitDelegate?.onFailedToSendBatch(listOfHitToSend);
      Flagship.logger(
          Level.EXCEPTIONS, EXCEPTION.replaceFirst("%s", "$error") + urlString);
      Flagship.logger(Level.ERROR, HIT_FAILED);
    }
  }

  // Send activate batch
  Future<int> sendActivateBatch(List<Hit> listOfActivate) async {
    // Create url
    String urlString = Endpoints.DECISION_API + Endpoints.ACTIVATION;
    // Create an activate batch object
    ActivateBatch activateBatch = ActivateBatch(listOfActivate);
    // Encode batch before send it
    try {
      Object? objectToSend = jsonEncode(activateBatch.toJson());
      var response = await service.sendHttpRequest(RequestType.Post, urlString,
          Endpoints.getFSHeader(this.apiKey), objectToSend,
          timeoutMs: TIMEOUT_REQUEST);
      switch (response.statusCode) {
        case 200:
        case 204:
          Flagship.logger(Level.INFO, ACTIVATE_SUCCESS + ": $objectToSend");
          Flagship.logger(
              Level.INFO, jsonEncode(Batch(listOfActivate).bodyTrack),
              isJsonString: true);
          onSendActivateBatchWithSucess(listOfActivate);
          return response.statusCode;
        default:
          Flagship.logger(Level.ERROR, HIT_FAILED);
          activateDelegate?.onFailedToSendBatch(listOfActivate);
          return response.statusCode;
      }
    } on Exception catch (e) {
      activateDelegate?.onFailedToSendBatch(listOfActivate);
      Flagship.logger(
          Level.EXCEPTIONS, EXCEPTION.replaceFirst("%s", "$e") + urlString);
      Flagship.logger(Level.ERROR, HIT_FAILED);
      return 500;
    }
  }

// On cache hits
  onCacheHits(Map<String, Map<String, Object>> hits) {
    fsCacheHit?.cacheHits(hits);
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
  addTrackingElementsToPool(List<Hit> listOfTracking) {
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
