import 'dart:async';
import 'dart:convert';
import 'package:flagship/api/endpoints.dart';
import 'package:flagship/cache/interface_cache.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/activate.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/tracking/tracking_manager_batch.dart';
import 'package:flagship/tracking/tracking_manager_config.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/flagship_tools.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:http/http.dart' as http;
import 'package:flagship/api/service.dart';

const TIMEOUT_REQUEST = 60000; // 60 seconds

class TrackingManager {
  /// api key
  late String apiKey;

  /// service
  Service service = Service(http.Client());

// Cache manager
  final IHitCacheImplementation? fsCacheHit;

// Config for the tracking manager
  final TrackingManagerConfig configTracking;

// Delegate hits
  TrackingManagerDelegate? hitDelegate;

// Delegate activate
  TrackingManagerDelegate? activateDelegate;

  // List failed ids to be cached except the consent ones
  List<String> failedIds = [];

  TrackingManager(this.service, this.configTracking, this.fsCacheHit) {
    this.apiKey = Flagship.sharedInstance().apiKey ?? "";
  }

  Future<void> sendHit(BaseHit pHit) async {
    if (pHit.isValid() == true) {
      // Create url
      String urlString = Endpoints.EVENT;
      try {
        var response = await service.sendHttpRequest(
            RequestType.Post,
            urlString,
            Endpoints.getFSHeader(this.apiKey),
            jsonEncode(pHit.bodyTrack),
            timeoutMs: TIMEOUT_REQUEST);
        switch (response.statusCode) {
          case 200:
          case 204:
          case 201:
            Flagship.logger(Level.INFO, HIT_SUCCESS);
            break;
          default:
            Flagship.logger(Level.ERROR, HIT_FAILED);
            this.onCacheHit(pHit);
        }
      } catch (error) {
        Flagship.logger(Level.EXCEPTIONS,
            EXCEPTION.replaceFirst("%s", "$error") + urlString);
        Flagship.logger(Level.ERROR, HIT_FAILED);
      }
    } else {
      Flagship.logger(Level.ERROR, "Hit not valid");
    }
  }

  // Send Activate
  Future<void> sendActivate(Activate activateHit) async {
    // Create url
    String urlString = Endpoints.DECISION_API + Endpoints.ACTIVATION;
    var response = await service.sendHttpRequest(RequestType.Post, urlString,
        Endpoints.getFSHeader(this.apiKey), jsonEncode(activateHit.toJson()),
        timeoutMs: TIMEOUT_REQUEST);
    switch (response.statusCode) {
      case 200:
      case 204:
        Flagship.logger(Level.INFO, ACTIVATE_SUCCESS);
        break;
      default:
        this.onCacheHit(activateHit);
        Flagship.logger(Level.ERROR, ACTIVATE_FAILED);
    }
  }

  void onCacheHit(Hit hitToBeCached) {
    hitToBeCached.id =
        hitToBeCached.visitorId + "_" + FlagshipTools.generateUuidv4();
    if (hitToBeCached.type != HitCategory.CONSENT) {
      failedIds.add(hitToBeCached.id);
    }
    fsCacheHit?.cacheHits({hitToBeCached.id: hitToBeCached.bodyTrack});
  }

  // Called when close flagship
  void close() {}

  // Called to flush the pool queue
  void flushAllTracking(String visitorId) {
    this.fsCacheHit?.flushHits(failedIds);
    failedIds.clear();
  }

  // Called to add a list to the pools
  // Each hit is checked before adding to the respective pool
  addTrackingElementsToBatch(List<Hit> listOfTracking) {
    // Retreive the track elements
    List<Hit> cachedHits = listOfTracking
        .where((element) => element.type != HitCategory.ACTIVATION)
        .toList();
    if (cachedHits.isNotEmpty) {
      // Create and send the hits in  batch
      sendBatch(cachedHits);
    }

    // Retreive the activate elements
    List<Hit> activateddHits = listOfTracking
        .where((element) => element.type == HitCategory.ACTIVATION)
        .toList();
    if (activateddHits.isNotEmpty) {
      // Create and send the activate in batch
      sendActivateBatch(activateddHits);
    }
  }

  // Delegate on sending batch
  void onSendBatchWithSucess(List<Hit> listOfHitToSend) {
    // Remove from data base the stored hits
    this.fsCacheHit?.flushHits(listOfHitToSend.map((e) => e.id).toList());
  }

  // Delegate on sending activate batch
  void onSendActivateBatchWithSucess(List<Hit> listOfActivate) {
    // Remove from data base the stored activate
    this.fsCacheHit?.flushHits(listOfActivate.map((e) => e.id).toList());
  }

  // start batching loops
  void startBatchingLoop() {} // There is no loop this strategy
  // Stop Batching loops
  void stopBatchingLoop() {} // There is no loop this strategy
}

mixin TrackingManagerDelegate {
  // On Sucess Sendig Batch
  onSendBatchWithSucess(
      List<Hit> listOfSendedHits, BatchCachingStrategy strategy);

  // On Failed Sending Batch
  onFailedToSendBatch(List<Hit> listOfHitToSend);
}
