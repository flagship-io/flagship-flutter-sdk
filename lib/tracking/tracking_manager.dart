import 'dart:async';
import 'dart:convert';
import 'package:flagship/api/endpoints.dart';
import 'package:flagship/cache/interface_cache.dart';
import 'package:flagship/tracking/batch_manager.dart';
import 'package:flagship/cache/cache_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flagship/hits/activate.dart';
import 'package:flagship/hits/batch.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/tracking/pool_queue.dart';
import 'package:flagship/tracking/tracking_manager_config.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:http/http.dart' as http;
import 'package:flagship/api/service.dart';

const TIMEOUT_REQUEST = 60000; // 60 seconds

class TrackingManager {
  /// api key
  late String apiKey;

  /// service
  Service service = Service(http.Client());

  /// Pool tempo, place it later elswhere
  late FlagshipPoolQueue fsPool;

  late FlagshipPoolQueue activatePool;

  // Cache manager
  final IHitCacheImplementation fsCacheHit;

  final TrackingManagerConfig configTracking;

  late BatchManager batchManager;

  TrackingManagerDelegate? delegate;

  TrackingManager(this.service, this.configTracking, this.fsCacheHit) {
    this.apiKey = Flagship.sharedInstance().apiKey ?? "";

    // Temporary create a pool  /// TO REVIEW
    fsPool = FlagshipPoolQueue(configTracking.poolMaxSize);

    // Activate poool
    activatePool = FlagshipPoolQueue(configTracking.poolMaxSize);

    // Create batch manager
    batchManager = BatchManager(fsPool, sendBatch, configTracking, fsCacheHit);
    this.delegate = batchManager;
    batchManager.startCron();
  }

  // Header for request
  Map<String, String> get fsHeader {
    return {
      "x-api-key": this.apiKey,
      "x-sdk-client": "flutter",
      "x-sdk-version": FlagshipVersion,
      "Content-type": "application/json"
    };
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

  // Send Hit
  Future<void> sendHit(BaseHit pHit) async {
    // Add to pool
    if (pHit.isValid() == true) {
      fsPool.addTrackElement(pHit);
      if (configTracking.batchStrategy ==
          BatchCachingStrategy.BATCH_CONTINUOUS_CACHING) {
        // It must cache the hit in the database by calling the cacheHit method of the cache manager
        fsCacheHit.cacheHits({pHit.id: pHit.bodyTrack});
      }
    } else {
      // When the hit is not valid
      Flagship.logger(Level.ERROR, "Hit not valid");
    }
    return;
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
          delegate?.onSendBatchWithSucess(listOfHitToSend);
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

mixin TrackingManagerDelegate {
  onSendBatchWithSucess(List<BaseHit> listOfSendedHits);
  onFailedToSendBatch(List<BaseHit> listOfHitToSend);
}
