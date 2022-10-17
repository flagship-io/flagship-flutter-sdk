import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flagship/api/endpoints.dart';
import 'package:flagship/tracking/batch_manager.dart';
import 'package:flagship/cache/cache_manager.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flagship/hits/activate.dart';
import 'package:flagship/hits/batch.dart';
import 'package:flagship/hits/event.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/tracking/pool_queue.dart';
import 'package:flagship/tracking/tracking_manager_config.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/flagship_tools.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:http/http.dart' as http;
import 'package:flagship/api/service.dart';
import 'package:pausable_timer/pausable_timer.dart';

const TIMEOUT_REQUEST = 60000; // 60 seconds

class TrackingManager {
  /// api key
  late String apiKey;

  /// service
  late Service _service;

  /// Pool tempo, place it later elswhere
  late FlagshipPoolQueue fsPool;

  late FlagshipPoolQueue activatePool;

  /// Cache manager
  late HitCacheManager fsCacheHit = HitCacheManager();

  final TrackingManagerConfig configTracking;

  late BatchManager batchManager;

  TrackingManagerDelegate? delegate;

  TrackingManager(this.configTracking) {
    this.apiKey = Flagship.sharedInstance().apiKey ?? "";
    _service = Service(http.Client());

    // Temporary create a pool
    fsPool = FlagshipPoolQueue();

    // Activate poool
    activatePool = FlagshipPoolQueue();

    /// Create batch manager
    batchManager = BatchManager(fsPool, configTracking.batchLength, configTracking.batchIntervals, sendBatch);
    this.delegate = batchManager;
  }

  /// Header for request
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
    /// Create url
    String urlString = Endpoints.DECISION_API + Endpoints.ACTIVATION;
    Object? objectToSend;
    if (activatePool.isEmpty()) {
      objectToSend = jsonEncode(activateHit.toJson());
    } else {
      var listOfActivate = activatePool.extractHitsWithVisitorId(activateHit.visitorId);
      // Add the current activate
      listOfActivate.add(activateHit);
      // Create an activate batch object
      ActivateBatch activateBatch = ActivateBatch(listOfActivate);
      // Encode
      objectToSend = jsonEncode(activateBatch.toJson());
    }

    var response =
        await _service.sendHttpRequest(RequestType.Post, urlString, fsHeader, objectToSend, timeoutMs: TIMEOUT_REQUEST);
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
    if (batchManager.cronTimer.isPaused) {
      batchManager.startCron();
    }
    // Add to pool
    if (pHit.isValid() == true) {
      fsPool.addTrackElement(pHit);
      // It must cache the hit in the database by calling the cacheHit method of the cache manager
      fsCacheHit.cacheHit(pHit.bodyTrack);
    } else {
      // When the hit is not valid
      Flagship.logger(Level.ERROR, "Hit not valid");
    }
    return;
  }

  // /// Send Hit
  // Future<void> sendHit(Hit pHit) async {
  //   /// Create url
  //   String urlString = Endpoints.ARIANE;
  //   try {
  //     var response = await _service.sendHttpRequest(RequestType.Post, urlString, fsHeader, jsonEncode(pHit.bodyTrack),
  //         timeoutMs: TIMEOUT_REQUEST);
  //     switch (response.statusCode) {
  //       case 200:
  //       case 204:
  //       case 201:
  //         Flagship.logger(Level.INFO, HIT_SUCCESS);
  //         break;
  //       default:
  //         Flagship.logger(Level.ERROR, HIT_FAILED);
  //     }
  //   } catch (error) {
  //     Flagship.logger(Level.EXCEPTIONS, EXCEPTION.replaceFirst("%s", "$error") + urlString);
  //     Flagship.logger(Level.ERROR, HIT_FAILED);
  //   }
  // }

  Future<void> sendBatch(List<Hit> listOfHitToSend) async {
    /// Create url
    String urlString = Endpoints.ARIANE;
    try {
      var response = await _service.sendHttpRequest(
          RequestType.Post, urlString, fsHeader, jsonEncode(Batch(listOfHitToSend).bodyTrack),
          timeoutMs: TIMEOUT_REQUEST);
      switch (response.statusCode) {
        case 200:
        case 204:
        case 201:
          Flagship.logger(Level.INFO, HIT_SUCCESS);
          Flagship.logger(Level.INFO, jsonEncode(Batch(listOfHitToSend).bodyTrack), isJsonString: true);
          delegate?.onSendBatchWithSucess();
          break;
        default:
          Flagship.logger(Level.ERROR, HIT_FAILED);
          delegate?.onFailedToSendBatch(listOfHitToSend);
      }
    } catch (error) {
      delegate?.onFailedToSendBatch(listOfHitToSend);
      Flagship.logger(Level.EXCEPTIONS, EXCEPTION.replaceFirst("%s", "$error") + urlString);
      Flagship.logger(Level.ERROR, HIT_FAILED);
    }
  }
}

mixin TrackingManagerDelegate {
  onSendBatchWithSucess();
  onFailedToSendBatch(List<Hit> listOfHitToSend);
}
