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

    // Hits pool
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
        // It must cache the hit in the database by calling the cacheHit method
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
    // Add the current activate by default
    List<Hit> listOfActivate = [activateHit];
    bool needToClean = false;

    /// When yes, the cache and pool need to be cleaned
    // If we have a failed activate hits
    if (activatePool.isEmpty() == false) {
      needToClean = true;
      Flagship.logger(Level.ALL,
          "Add previous activates in batch found in the pool activate");
      listOfActivate
          .addAll(activatePool.extractHitsWithVisitorId(activateHit.visitorId));
    } else {
      // We dont have any failed activate in the pool
    }
    // Create an activate batch object
    ActivateBatch activateBatch = ActivateBatch(listOfActivate);
    // Encode batch before send it
    Object? objectToSend = jsonEncode(activateBatch.toJson());

    var response = await service.sendHttpRequest(RequestType.Post, urlString,
        Endpoints.getFSHeader(this.apiKey), objectToSend,
        timeoutMs: TIMEOUT_REQUEST);
    switch (response.statusCode) {
      case 200:
      case 204:
        Flagship.logger(Level.INFO, ACTIVATE_SUCCESS + ": $objectToSend");
        // Clear all the activate in the pool and clear them from cache
        if (needToClean) {
          listOfActivate.remove(activateHit);
          activatePool.flushTrackQueue();
          delegate?.onSendBatchWithSucess(
              listOfActivate, strategy); // revoir ici faut remove le current
        }
        break;
      default:
        Flagship.logger(Level.ERROR, ACTIVATE_FAILED + ": $objectToSend");
        activatePool.addTrackElement(activateHit);
        if (strategy == BatchCachingStrategy.BATCH_CONTINUOUS_CACHING) {
          // It must cache the hit in the database by calling the cacheHit method
          fsCacheHit?.cacheHits({activateHit.id: activateHit.bodyTrack});
        }
    }
  }

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
