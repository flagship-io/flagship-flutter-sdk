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

class TrackingManageStrategy extends TrackingManager {
  BatchCachingStrategy strategy = BatchCachingStrategy.BATCH_CONTINUOUS_CACHING;

  TrackingManageStrategy(Service service, TrackingManagerConfig configTracking,
      IHitCacheImplementation fsCacheHit)
      : super(service, configTracking, fsCacheHit) {
    strategy = configTracking.batchStrategy;

    fsPool = FlagshipPoolQueue(configTracking.poolMaxSize);

    // Activate pool
    activatePool = FlagshipPoolQueue(configTracking.poolMaxSize);

    // Create batch manager
    batchManager = BatchManager(fsPool, sendBatch, configTracking, fsCacheHit);

    this.delegate = batchManager;
  }

  @override
  // Send Hit
  Future<void> sendHit(BaseHit pHit) async {
    Flagship.logger(Level.INFO, "Send hit with continious caching strategy");
    if (pHit.isValid() == true) {
      // Add to pool
      fsPool.addTrackElement(pHit);

      if (strategy == BatchCachingStrategy.BATCH_CONTINUOUS_CACHING) {
        // It must cache the hit in the database by calling the cacheHit method of the cache manager
        fsCacheHit?.cacheHits({pHit.id: pHit.bodyTrack});
      }
    } else {
      // When the hit is not valid
      Flagship.logger(Level.ERROR, "Hit not valid");
    }
  }

  // later add code error in the future
  Future<void> sendActivate(Activate activateHit) async {
    // Create url
    String urlString = Endpoints.DECISION_API + Endpoints.ACTIVATION;
    Object? objectToSend;
    if (activatePool.isEmpty()) {
      objectToSend = jsonEncode(activateHit.toJson());
    } else {
      urlString = Endpoints.DECISION_API + Endpoints.ACTIVATION;
      var listOfActivate =
          activatePool.extractHitsWithVisitorId(activateHit.visitorId);
      // Add the current activate
      listOfActivate.add(activateHit);
      // Create an activate batch object
      ActivateBatch activateBatch = ActivateBatch(listOfActivate);
      // Encode
      objectToSend = jsonEncode(activateBatch.toJson());
    }

    var response = await service.sendHttpRequest(
        RequestType.Post, urlString, fsHeader, objectToSend,
        timeoutMs: TIMEOUT_REQUEST);
    switch (response.statusCode) {
      case 200:
      case 204:
        Flagship.logger(Level.INFO, ACTIVATE_SUCCESS + ": $objectToSend");
        // Clear all the activate in the pool
        activatePool.flushTrackQueue();
        break;
      default:
        Flagship.logger(Level.ERROR, ACTIVATE_FAILED + ": $objectToSend");
        activatePool.addTrackElement(activateHit);
    }
  }

  Future<void> sendBatch(List<BaseHit> listOfHitToSend) async {
    // Create url
    String urlString = Endpoints.BATCH;
    try {
      var response = await service.sendHttpRequest(RequestType.Post, urlString,
          fsHeader, jsonEncode(Batch(listOfHitToSend).bodyTrack),
          timeoutMs: TIMEOUT_REQUEST);
      switch (response.statusCode) {
        case 200:
        case 204:
        case 201:
          Flagship.logger(Level.INFO, HIT_SUCCESS);
          Flagship.logger(
              Level.INFO, jsonEncode(Batch(listOfHitToSend).bodyTrack),
              isJsonString: true);
          delegate?.onSendBatchWithSucess(listOfHitToSend, strategy);
          break;
        default:
          Flagship.logger(Level.ERROR, HIT_FAILED);
          delegate?.onFailedToSendBatch(listOfHitToSend);
      }
    } catch (error) {
      delegate?.onFailedToSendBatch(listOfHitToSend);
      Flagship.logger(
          Level.EXCEPTIONS, EXCEPTION.replaceFirst("%s", "$error") + urlString);
      Flagship.logger(Level.ERROR, HIT_FAILED);
    }
  }
}
